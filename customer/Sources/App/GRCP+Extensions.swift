import Configuration
import Domain
import GRPCServer
import GRPCCore
import GRPCHealthService
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import GRPCReflectionService
import GRPCServiceLifecycle
import Logging
import ServiceLifecycle
import OTelSemanticConventions

enum GRPCService {
    static func customerService(
        reader: ConfigReader,
        service: ServiceImplementation,
        logger: Logger
    ) throws -> some Service {
        let health = HealthService()

        // let paths = Bundle.module.paths(forResourcesOfType: "pb", inDirectory: "DescriptorSets") // todo acutally bundle these
        let reflection = try ReflectionService(descriptorSetFilePaths: [])

        return try GRPCServer(
            transport: HTTP2ServerTransport.Posix(reader: reader.scoped(to: "transport")),
            services: [
                health,
                reflection,
                service,
            ],
            interceptors: [
                ServerOTelTracingInterceptor(reader: reader.scoped(to: "otel")),
                ServerOTelMetricsInterceptor(reader: reader.scoped(to: "otel")),
                ServerOTelLoggingInterceptor(reader: reader.scoped(to: "otel"), logger: logger),
            ]
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

extension ServerOTelMetricsInterceptor {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        try self.init(
            serverHostname: snapshot.requiredString(forKey: "serverHostname"),
            networkTransportMethod: .init(rawValue: snapshot.string(forKey: "transportMethod", default: "tcp")),
        )
    }
}

extension ServerOTelLoggingInterceptor {
    fileprivate init(reader: ConfigReader, logger: Logger) throws {
        let snapshot = reader.snapshot()
        try self.init(
            logger: logger,
            serverHostname: snapshot.requiredString(forKey: "serverHostname"),
            networkTransportMethod: .init(rawValue: snapshot.string(forKey: "transportMethod", default: "tcp")),
            includeRequestMetadata: snapshot.bool(forKey: "includeRequestMetadata", default: false),
            includeResponseMetadata: snapshot.bool(forKey: "includeResponseMetadata", default: false)
        )
    }
}