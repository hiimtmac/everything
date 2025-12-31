import Configuration
import PostgresNIO

extension PostgresClient.Configuration {
    init(reader: ConfigReader) throws {
        self.init(
            host: reader.string(forKey: "host"),
            port: reader.int(forKey: "port", default: 5432),
            username: reader.string(forKey: "username"),
            password: reader.string(forKey: "password"),
            database: reader.string(forKey: "database"),
            tls: .disable
        )
    }
}