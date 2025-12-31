import Configuration
import Kafka

extension KafkaConfiguration.BrokerAddress {
    init(reader: ConfigReader) throws {
        let host = try reader.string(forKey: "host")
        let port = try reader.int(forKey: "port", default: 9092)
        self = .init(host: host, port: port)
    }
}