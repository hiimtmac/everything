import Configuration
import Logging
import Valkey

extension ValkeyClient {
    convenience init(reader: ConfigReader, logger: Logger) throws {
        try self.init(
            .hostname(
                reader.requiredString(forKey: "host"),
                port: reader.int(forKey: "port", default: 6379)
            ),
            logger: logger
        )
    }   
}