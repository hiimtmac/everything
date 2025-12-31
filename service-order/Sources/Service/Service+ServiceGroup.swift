import Domain
import Configuration
import GRPCCore
import GRPCClient
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCReflectionService
import GRPCHealthService
import GRPCServiceLifecycle
import Jobs
import JobsValkey
import Kafka
import Logging
import Otel
import PostgresNIO
import ServiceLifecycle
import Temporal
import UnixSignals
import Valkey

// TODO move to own file
@ActivityContainer
struct GreetingActivities {
    @Activity
    func sayHello(input: String) -> String {
        "Hello, \(input)!"
    }
}

func buildServiceGroup(
    reader: ConfigReader, 
    logger: inout Logger
) async throws -> ServiceGroup {
    // TODO give services their own loggers
    logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
    
    let customerClient = try GRPCClient(
        transport: HTTP2ClientTransport.Posix(reader: reader.scoped(to: "customer")),
        interceptors: [ClientOTelTracingInterceptor(reader: reader.scoped(to: "otel.client"))]
    )
    let customerService = Homebrews_Customer_V1_CustomerService.Client(wrapping: customerClient)
    
    let service = ServiceImplementation(customerService: customerService)

    let health = HealthService()

//    let paths = Bundle.module.paths(forResourcesOfType: "pb", inDirectory: "DescriptorSets") // todo acutally bundle these
    let reflection = try ReflectionService(descriptorSetFilePaths: [])

    let server = try GRPCServer(
        transport: HTTP2ServerTransport.Posix(reader: reader.scoped(to: "grpc")),
        services: [
            health,
            reflection,
            service,
        ],
        interceptors: [ServerOTelTracingInterceptor(reader: reader.scoped(to: "otel.server"))]
    )

    let observability = try OTel.bootstrap(reader: reader.scoped(to: "otel.server"))

    let valkeyClient = try ValkeyClient(
        reader: reader.scoped(to: "valkey"),
        logger: logger
    )

    let jobQueue = try await JobQueue(
        .valkey(
            valkeyClient,
            configuration: .init(queueName: "order", retentionPolicy: .init(completedJobs: .retain)),
            logger: logger
        ),
        logger: logger
    )

    var jobSchedule = JobSchedule()

    let brokerAddress = try KafkaConfiguration.BrokerAddress(reader: reader.scoped(to: "kafka"))
    let kafkaProducerConfig = KafkaProducerConfiguration(bootstrapBrokerAddresses: [brokerAddress])

    let kafkaConsumerConfig = KafkaConsumerConfiguration(
        consumptionStrategy: .partition(
            KafkaPartition(rawValue: 0),
            topic: "topic-name"
        ),
        bootstrapBrokerAddresses: [brokerAddress]
    )

    let kafkaConsumer = try KafkaConsumer(configuration: kafkaConsumerConfig, logger: logger)
    let kafkaProducer = try KafkaProducer(configuration: kafkaProducerConfig, logger: logger)

    let postgresConfig = try PostgresClient.Configuration(reader: reader.scoped(to: "postgres"))
    let postgresClient = PostgresClient(configuration: postgresConfig, backgroundLogger: logger)

    // todo config
    let temporalWorkerConfig = TemporalWorker.Configuration(reader: reader.scoped(to: "temporal"))
    let temporalWorker = try TemporalWorker(
        configuration: temporalWorkerConfig,
        target: .ipv4(address: "127.0.0.1", port: 7233),
        transportSecurity: .plaintext,
        activityContainers: GreetingActivities(),
        activities: [],
        workflows: [],
        logger: logger
    )

    let temporalClientConfig = TemporalWorker.Configuration(reader: reader.scoped(to: "temporal"))
    let temporalClient = try TemporalClient(
        target: .ipv4(address: "127.0.0.1", port: 7233),
        transportSecurity: .plaintext,
        configuration: temporalClientConfig,
        logger: logger
    )

    return ServiceGroup(
        services: [
            server,
            customerClient,
            observability,
            valkeyClient,
            jobQueue.processor(options: .init(numWorkers: 1, gracefulShutdownTimeout: .seconds(10))), // TODO run out of process
            jobSchedule.scheduler(on: jobQueue, named: "order"),
            kafkaConsumer,
            kafkaProducer,
            postgresClient,
            temporalWorker,
            temporalClient,
        ],
        gracefulShutdownSignals: [.sigterm, .sigint],
        logger: logger
    )
}
