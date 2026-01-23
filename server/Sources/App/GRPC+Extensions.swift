import API
import Configuration
import GRPCClient
import GRPCCore
import GRPCNIOTransportHTTP2
import GRPCOTelTracingInterceptors

enum GRPCService {
    static func orderSerivce(
        reader: ConfigReader
    ) throws -> some OrderServiceClient {
        let client = try GRPCClient(reader: reader)
        let service = Everything_Order_V1_OrderService.Client(wrapping: client)
        return service
    }

    static func customerService(
        reader: ConfigReader
    ) throws -> some CustomerServiceClient {
        let client = try GRPCClient(reader: reader)
        let service = Everything_Customer_V1_CustomerService.Client(wrapping: client)
        return service
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