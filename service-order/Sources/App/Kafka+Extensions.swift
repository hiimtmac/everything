import Configuration
import Kafka

extension KafkaConfiguration.BrokerAddress {
    init(reader: ConfigReader) throws {
        let snapshot = reader.snapshot()
        let host = try snapshot.requiredString(forKey: "host")
        let port = try snapshot.int(forKey: "port", default: 9092)
        self = .init(host: host, port: port)
    }
}