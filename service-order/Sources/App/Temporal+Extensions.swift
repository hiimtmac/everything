import Configuration
import GRPCNIOTransportHTTP2
import Logging
import Temporal

enum TemporalService {
    static func temporalClient(
        reader: ConfigReader,
        logger: Logger
    ) throws -> TemporalClient {
        try TemporalClient(
            transport: HTTP2ClientTransport.Posix(reader: reader.scoped(to: "client")),
            configuration: TemporalClient.Configuration(configReader: reader),
            logger: logger
        )
    }

    // TODO: config
    static func temporalWorker<each Container: ActivityContainer>(
        reader: ConfigReader,
        activityContainers: repeat each Container,
        activities: [any ActivityDefinition] = [],
        workflows: [any WorkflowDefinition.Type] = [],
        logger: Logger
    ) throws -> TemporalWorker {
        try TemporalWorker(
            configuration: TemporalWorker.Configuration(configReader: reader),
            transport: try .http2NIOPosix(
                target: .ipv4(address: "localhost", port: 7233),
                transportSecurity: .plaintext
            ),
            activityContainers: repeat each activityContainers,
            activities: activities,
            workflows: workflows,
            logger: logger
        )
    }
}

extension HTTP2ClientTransport.Posix {
    fileprivate init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        let host = try snapshot.requiredString(forKey: "host")
        let port = snapshot.int(forKey: "port") ?? 7233
        try self.init(
            target: .dns(host: host, port: port),
            transportSecurity: .plaintext
        )
    }
}