import Configuration
import Logging
import ProfileRecorderServer
import ServiceLifecycle
import SystemPackage

@main
struct Server {
    static func main() async throws {
        let reader = try await ConfigReader(providers: [
            CommandLineArgumentsProvider(),
            EnvironmentVariablesProvider(),
            EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
            InMemoryProvider(values: [
                "http.serverName": "server",
                "otel.server.serverName": "server",
            ]),
        ])

        var logger = Logger(label: "server")
        let serviceGroup = try await buildServiceGroup(reader: reader, logger: &logger)

        async let _ = ProfileRecorderServer(configuration: .parseFromEnvironment())
            .runIgnoringFailures(logger: logger)

        try await serviceGroup.run()
    }
}
