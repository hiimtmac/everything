import Configuration
import Domain
import GRPCServer
import GRPCClient
import GRPCCore
import GRPCHealthService
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCReflectionService
import GRPCServiceLifecycle
import ServiceLifecycle

// Metrics Interceptors https://github.com/grpc/grpc-swift-extras/pull/62

enum GRPCService {
    static func orderService(
        reader: ConfigReader,
        service: ServiceImplementation
    ) throws -> some Service {
        try GRPCServer(
            reader: reader,
            service: service
        )
    }

    static func customerService(
        reader: ConfigReader
    ) throws -> some CustomerServiceClient {
        let client = try GRPCClient(reader: reader)
        let service = Everything_Customer_V1_CustomerService.Client(wrapping: client)
        return service
    }
}

extension GRPCServer where Transport == HTTP2ServerTransport.Posix {
    fileprivate convenience init(
        reader: ConfigReader,
        service: ServiceImplementation
    ) throws {
        let health = HealthService()

        // let paths = Bundle.module.paths(forResourcesOfType: "pb", inDirectory: "DescriptorSets") // todo acutally bundle these
        let reflection = try ReflectionService(descriptorSetFilePaths: [])

        try self.init(
            transport: HTTP2ServerTransport.Posix(reader: reader.scoped(to: "transport")),
            services: [
                health,
                reflection,
                service,
            ],
            interceptors: [
                ServerOTelTracingInterceptor(reader: reader.scoped(to: "otel")),
                // TODO: ServerMetricsInterceptor(),
                // TODO: ServerLoggingInterceptor()
            ]
        )
    }
}

extension GRPCClient where Transport == HTTP2ClientTransport.Posix {
    fileprivate convenience init(reader: ConfigReader) throws {
        try self.init(
            transport: HTTP2ClientTransport.Posix(reader: reader.scoped(to: "service")),
            interceptors: [
                ClientOTelTracingInterceptor(reader: reader.scoped(to: "otel")),
                // TODO: ClientMetricsInterceptor(),
                // TODO: ClientLoggingInterceptor()
            ]
        )
    }
}

extension HTTP2ClientTransport.Posix {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        let host = try snapshot.requiredString(forKey: "host")
        let port = snapshot.int(forKey: "port") ?? 50051
        try self.init(
            target: .dns(host: host, port: port),
            transportSecurity: .plaintext
        )
    }
}

extension HTTP2ServerTransport.Posix {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        let host = try snapshot.requiredString(forKey: "host")
        let port = snapshot.int(forKey: "port") ?? 50051
        self.init(
            address: .ipv4(host: host, port: port),
            transportSecurity: .plaintext
        )
    }
}

extension ClientOTelTracingInterceptor {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        try self.init(
            serverHostname: snapshot.requiredString(forKey: "serverHostname"),
            networkTransportMethod: snapshot.string(forKey: "transportMethod", default: "tcp"),
            traceEachMessage: snapshot.bool(forKey: "traceEachMessage", default: true),
            includeRequestMetadata: snapshot.bool(forKey: "includeRequestMetadata", default: false),
            includeResponseMetadata: snapshot.bool(forKey: "includeResponseMetadata", default: false)
        )
    }
}

extension ServerOTelTracingInterceptor {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        try self.init(
            serverHostname: snapshot.requiredString(forKey: "serverHostname"),
            networkTransportMethod: snapshot.string(forKey: "transportMethod", default: "tcp"),
            traceEachMessage: snapshot.bool(forKey: "traceEachMessage", default: true),
            includeRequestMetadata: snapshot.bool(forKey: "includeRequestMetadata", default: false),
            includeResponseMetadata: snapshot.bool(forKey: "includeResponseMetadata", default: false)
        )
    }
}