import Domain
import Configuration
import GRPCNIOTransportCore
import GRPCNIOTransportHTTP2Posix
import Jobs
import JobsValkey
import Kafka
import Logging
import OTel
import ProfileRecorderServer
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
    reader: ConfigReader
) async throws -> ServiceGroup {
    // OTEL - must be bootstrapped BEFORE creating loggers or traced services
    let observability = try OTel.bootstrap(reader: reader.scoped(to: "otel"))

    let logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
    
    // GRPC
    var grpcLogger = Logger(label: "grpc")
    grpcLogger.logLevel = logLevel
    let customerService = try GRPCService.customerService(reader: reader.scoped(to: "customer"), logger: grpcLogger)
    
    let service = ServiceImplementation(customerService: customerService)
    let server = try GRPCService.orderService(
        reader: reader.scoped(to: "grpc"),
        service: service,
        logger: grpcLogger
    )

    // Valkey
    var valkeyLogger = Logger(label: "valkey")
    valkeyLogger.logLevel = logLevel
    let valkeyClient = try ValkeyClient(
        reader: reader.scoped(to: "valkey"),
        logger: valkeyLogger
    )

    // Job Queue
    var jobLogger = Logger(label: "job-queue")
    jobLogger.logLevel = logLevel
    let jobQueue = try await JobQueue(
        .valkey(
            valkeyClient,
            configuration: .init(queueName: "customer", retentionPolicy: .init(completedJobs: .retain)),
            logger: jobLogger
        ),
        logger: jobLogger
    )
    let jobQueueService = jobQueue.processor(options: .init(numWorkers: 1, gracefulShutdownTimeout: .seconds(10)))

    // let jobSchedule = JobSchedule()

    // Kafka
    let brokerAddress = try KafkaConfiguration.BrokerAddress(reader: reader.scoped(to: "kafka"))

    var kafkaProducerLogger = Logger(label: "kafka-producer")
    kafkaProducerLogger.logLevel = logLevel
    let kafkaProducerConfig = KafkaProducerConfiguration(bootstrapBrokerAddresses: [brokerAddress])
    let kafkaProducer = try KafkaProducer(configuration: kafkaProducerConfig, logger: kafkaProducerLogger)

    var kafkaConsumerLogger = Logger(label: "kafka-consumer")
    kafkaConsumerLogger.logLevel = logLevel
    let kafkaConsumerConfig = KafkaConsumerConfiguration(
        consumptionStrategy: .partition(
            KafkaPartition(rawValue: 0),
            topic: "topic-name"
        ),
        bootstrapBrokerAddresses: [brokerAddress]
    )
    let kafkaConsumer = try KafkaConsumer(configuration: kafkaConsumerConfig, logger: kafkaConsumerLogger)

    // Postgres
    var postgresLogger = Logger(label: "postgres")
    postgresLogger.logLevel = logLevel
    let postgresConfig = try PostgresClient.Configuration(reader: reader.scoped(to: "postgres"))
    let postgresClient = PostgresClient(configuration: postgresConfig, backgroundLogger: postgresLogger)

    // Temporal
    var temporalWorkerLogger = Logger(label: "temporal-worker")
    temporalWorkerLogger.logLevel = logLevel
    let temporalWorker = try TemporalService.temporalWorker(
        reader: reader.scoped(to: "temporal"),
        activityContainers: GreetingActivities(),
        activities: [],
        workflows: [],
        logger: temporalWorkerLogger
    )

    var temporalClientLogger = Logger(label: "temporal-client")
    temporalClientLogger.logLevel = logLevel
    let temporalClient = try TemporalService.temporalClient(
        reader: reader.scoped(to: "temporal"), 
        logger: temporalClientLogger
    )

    // Profiler
    var profileLogger = Logger(label: "profiler")
    profileLogger.logLevel = logLevel
    async let _ = ProfileRecorderServer
        .init(configuration: .parseFromEnvironment())
        .runIgnoringFailures(logger: profileLogger)

    // Service Group
    var serviceLogger = Logger(label: "servicegroup")
    serviceLogger.logLevel = logLevel

    return ServiceGroup(
        services: [
            server,
            observability,
            valkeyClient,
            jobQueueService, // TODO run out of process
            // jobSchedule.scheduler(on: jobQueue, named: "order"), <- causing crash?
            kafkaConsumer,
            kafkaProducer,
            postgresClient,
            temporalWorker,
            temporalClient,
        ],
        gracefulShutdownSignals: [.sigterm, .sigint],
        logger: serviceLogger
    )
}
