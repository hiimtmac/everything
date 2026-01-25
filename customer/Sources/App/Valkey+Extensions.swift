import Configuration
import Logging
import Valkey

extension ValkeyClient {
    convenience init(reader: ConfigReader, logger: Logger) throws {
        let snapshot = reader.snapshot()
        try self.init(
            .hostname(
                snapshot.requiredString(forKey: "host"),
                port: snapshot.int(forKey: "port", default: 6379)
            ),
            logger: logger
        )
    }   
}