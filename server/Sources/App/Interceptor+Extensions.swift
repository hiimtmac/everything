import Configuration
import GRPCOTelTracingInterceptors

extension ClientOTelTracingInterceptor {
    init(reader: ConfigReader, serverHostname: String) throws {
        try self.init(
            serverHostname: serverHostname,
            networkTransportMethod: reader.string(forKey: "transportMethod", default: "tcp"),
            traceEachMessage: reader.bool(forKey: "traceEachMessage", default: true),
            includeRequestMetadata: reader.bool(forKey: "includeRequestMetadata", default: false),
            includeResponseMetadata: reader.bool(forKey: "includeResponseMetadata", default: false)
        )
    }
}
