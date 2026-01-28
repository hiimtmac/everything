import API
import Configuration
import GRPCClient
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors
import Logging
import OTelSemanticConventions

enum GRPCService {
    static func orderSerivce(
        reader: ConfigReader,
        logger: Logger
    ) throws -> some OrderServiceClient {
        let client = try GRPCClient(reader: reader, logger: logger)
        let service = Everything_Order_V1_OrderService.Client(wrapping: client)
        return service
    }

    static func customerService(
        reader: ConfigReader,
        logger: Logger
    ) throws -> some CustomerServiceClient {
        let client = try GRPCClient(reader: reader, logger: logger)
        let service = Everything_Customer_V1_CustomerService.Client(wrapping: client)
        return service
    }
}

extension GRPCClient where Transport == HTTP2ClientTransport.Posix {
    fileprivate convenience init(reader: ConfigReader, logger: Logger) throws {
        try self.init(
            transport: HTTP2ClientTransport.Posix(reader: reader.scoped(to: "service")),
            interceptors: [
                ClientOTelTracingInterceptor(reader: reader.scoped(to: "tracing")),
                ClientOTelMetricsInterceptor(reader: reader.scoped(to: "metrics")),
                ClientOTelLoggingInterceptor(reader: reader.scoped(to: "logging"), logger: logger),
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

extension ClientOTelMetricsInterceptor {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        try self.init(
            serverHostname: snapshot.requiredString(forKey: "serverHostname"),
            networkTransportMethod: .init(rawValue: snapshot.string(forKey: "transportMethod", default: "tcp")),
        )
    }
}

extension ClientOTelLoggingInterceptor {
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