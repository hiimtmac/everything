import Configuration
import PostgresNIO

extension PostgresClient.Configuration {
    init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        try self.init(
            host: snapshot.requiredString(forKey: "host"),
            port: snapshot.int(forKey: "port", default: 5432),
            username: snapshot.requiredString(forKey: "username"),
            password: snapshot.requiredString(forKey: "password"),
            database: snapshot.requiredString(forKey: "database"),
            tls: .disable
        )
    }
}