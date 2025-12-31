import Configuration
import GRPCOTelTracingInterceptors

extension ClientOTelTracingInterceptor {
    init(reader: ConfigReader) throws {
        try self.init(
            serverHostname: reader.string(forKey: "serverHostname", default: "customer"),
            networkTransportMethod: reader.string(forKey: "transportMethod", default: "tcp"),
            traceEachMessage: reader.bool(forKey: "traceEachMessage", default: true),
            includeRequestMetadata: reader.bool(forKey: "includeRequestMetadata", default: false),
            includeResponseMetadata: reader.bool(forKey: "includeResponseMetadata", default: false)
        )
    }
}

extension ServerOTelTracingInterceptor {
    init(reader: ConfigReader) throws {
        try self.init(
            serverHostname: reader.string(forKey: "serverHostname", default: "order"),
            networkTransportMethod: reader.string(forKey: "transportMethod", default: "tcp"),
            traceEachMessage: reader.bool(forKey: "traceEachMessage", default: true),
            includeRequestMetadata: reader.bool(forKey: "includeRequestMetadata", default: false),
            includeResponseMetadata: reader.bool(forKey: "includeResponseMetadata", default: false)
        )
    }
}