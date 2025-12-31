import Configuration
import OTel
import ServiceLifecycle

extension OTel {
    static func bootstrap(reader: ConfigReader) throws -> some Service {
        let host = try reader.requiredString(forKey: "host")
        let port = reader.int(forKey: "port") ?? 4318
        let endpoint = "http://\(host):\(port)"

        var config = OTel.Configuration.default
        config.serviceName = "order"
        config.diagnosticLogLevel = .error
        config.logs.batchLogRecordProcessor.scheduleDelay = .seconds(3)
        config.metrics.exportInterval = .seconds(3)
        config.traces.batchSpanProcessor.scheduleDelay = .seconds(3)
        config.logs.otlpExporter.endpoint = endpoint
        config.metrics.otlpExporter.endpoint = endpoint
        config.traces.otlpExporter.endpoint = endpoint

        return try OTel.bootstrap(configuration: config)
    }
}
