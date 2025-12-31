import Domain
import Configuration
import GRPCCore
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
import UnixSignals
import Valkey

func buildServiceGroup(
    reader: ConfigReader,
    logger: inout Logger
) async throws -> ServiceGroup {
    // TODO give services their own loggers
    logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
    
    let service = ServiceImplementation()

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
            configuration: .init(queueName: "customer", retentionPolicy: .init(completedJobs: .retain)),
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

    return ServiceGroup(
        services: [
            server,
            observability,
            valkeyClient,
            jobQueue.processor(options: .init(numWorkers: 1, gracefulShutdownTimeout: .seconds(10))), // TODO run out of process
            jobSchedule.scheduler(on: jobQueue, named: "customer"),
            kafkaConsumer,
            kafkaProducer,
            postgresClient
        ],
        gracefulShutdownSignals: [.sigterm, .sigint],
        logger: logger
    )
}
