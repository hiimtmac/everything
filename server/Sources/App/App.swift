import Configuration
import ServiceLifecycle
import SystemPackage

@main
struct App {
    static func main() async throws {
        let reader = try await ConfigReader(providers: [
            CommandLineArgumentsProvider(),
            EnvironmentVariablesProvider(),
            EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
            InMemoryProvider(values: [
                "http.serverName": "server"
            ]),
        ])

        let serviceGroup = try await buildServiceGroup(reader: reader)
        try await serviceGroup.run()
    }
}
