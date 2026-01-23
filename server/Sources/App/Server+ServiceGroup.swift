import Configuration
import Hummingbird
import HummingbirdValkey
import Logging
import OTel
import ProfileRecorderServer
import ServiceLifecycle
import UnixSignals
import Valkey

func buildServiceGroup(
    reader: ConfigReader
) async throws -> ServiceGroup {
    // OTEL - must be bootstrapped BEFORE creating loggers or traced services
    let observability = try OTel.bootstrap(reader: reader.scoped(to: "otel"))

    let logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)

    // GRPC
    let orderService = try GRPCService.orderSerivce(reader: reader.scoped(to: "order"))
    let customerService = try GRPCService.customerService(reader: reader.scoped(to: "customer"))

    // Server
    let router = try buildRouter(
        orderService: orderService,
        customerService: customerService
    )

    var appLogger = Logger(label: "server")
    appLogger.logLevel = logLevel
    let app = Application(
        router: router,
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
        logger: appLogger
    )

    // Valkey
    var valkeyLogger = Logger(label: "valkey")
    valkeyLogger.logLevel = logLevel
    let valkeyClient = try ValkeyClient(
        reader: reader.scoped(to: "valkey"),
        logger: valkeyLogger
    )

    // let persist = ValkeyPersistDriver(client: valkeyClient)

    // Profiler
    var profileLogger = Logger(label: "profiler")
    profileLogger.logLevel = logLevel
    async let _ = ProfileRecorderServer
        .init(configuration: .parseFromEnvironment())
        .runIgnoringFailures(logger: profileLogger)

    // Service Group
    var serviceLogger = Logger(label: "servicegroup")
    serviceLogger.logLevel = logLevel

    // Note (from claude): gRPC clients connect lazily on first RPC, so they don't need to be                                                                                              
    // managed as services in the ServiceGroup. Adding them causes shutdown hangs                                                                                            
    // when remote services aren't available. Keep references alive by storing them                                                                                          
    // in variables above (orderClient, customerClient). They'll clean up on exit.     
    return ServiceGroup(
        services: [
            app,
            observability,
            valkeyClient
        ],
        gracefulShutdownSignals: [.sigterm, .sigint],
        logger: serviceLogger
    )
}
