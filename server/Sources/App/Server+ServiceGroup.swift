import Configuration
import GRPCClient
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCServiceLifecycle
import Hummingbird
import HummingbirdValkey
import Logging
import OTel
import ServiceLifecycle
import UnixSignals
import Valkey

func buildServiceGroup(
    reader: ConfigReader,
    logger: inout Logger
) async throws -> ServiceGroup {
    // TODO give services their own loggers
    logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)

    let orderClient = try GRPCClient(
        transport: HTTP2ClientTransport.Posix(reader: reader.scoped(to: "order")),
        interceptors: [
            ClientOTelTracingInterceptor(
                reader: reader.scoped(to: "otel.client"),
                serverHostname: "order"
            )
        ]
    )
    let orderService = Homebrews_Order_V1_OrderService.Client(wrapping: orderClient)

    let customerClient = try GRPCClient(
        transport: HTTP2ClientTransport.Posix(reader: reader.scoped(to: "customer")),
        interceptors: [
            ClientOTelTracingInterceptor(
                reader: reader.scoped(to: "otel.client"),
                serverHostname: "customer"
            )
        ]
    )
    let customerService = Homebrews_Customer_V1_CustomerService.Client(wrapping: customerClient)

    let router = try buildRouter(
        orderService: orderService,
        customerService: customerService
    )

    let app = Application(
        router: router,
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
        logger: logger
    )

    let observability = try OTel.bootstrap(reader: reader.scoped(to: "otel.server"))

    let valkeyClient = try ValkeyClient(
        reader: reader.scoped(to: "valkey"),
        logger: logger
    )

    // let persist = ValkeyPersistDriver(client: valkeyClient)

    return ServiceGroup(
        services: [
            app,
            orderClient,
            customerClient,
            observability,
            valkeyClient
        ],
        gracefulShutdownSignals: [.sigterm, .sigint],
        logger: logger
    )
}
