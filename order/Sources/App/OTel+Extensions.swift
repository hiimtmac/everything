import Configuration
import OTel
import ServiceLifecycle

extension OTel {
    static func bootstrap(reader: ConfigReader) throws -> some Service {
        let snapshot = reader.snapshot()
        
        let host = try snapshot.requiredString(forKey: "host")
        let port = snapshot.int(forKey: "port") ?? 4318
        let endpoint = "http://\(host):\(port)"

        var config = OTel.Configuration.default
        config.serviceName = try snapshot.requiredString(forKey: "serviceName")
        config.diagnosticLogLevel = .error
        config.logs.batchLogRecordProcessor.scheduleDelay = .seconds(3)
        config.metrics.exportInterval = .seconds(3)
        config.traces.batchSpanProcessor.scheduleDelay = .seconds(3)
        config.logs.otlpExporter.endpoint = "\(endpoint)/v1/logs"
        config.metrics.otlpExporter.endpoint = "\(endpoint)/v1/metrics"
        config.traces.otlpExporter.endpoint = "\(endpoint)/v1/traces"

        return try OTel.bootstrap(configuration: config)
    }
}

