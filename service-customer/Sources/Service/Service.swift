import Configuration
import Foundation
import Logging
import ServiceLifecycle
import ProfileRecorderServer
import SystemPackage

@main
struct Service {
    static func main() async throws {
        let reader = try await ConfigReader(providers: [
            CommandLineArgumentsProvider(),
            EnvironmentVariablesProvider(),
            EnvironmentVariablesProvider(environmentFilePath: ".env", allowMissing: true),
            InMemoryProvider(values: [:])
        ])

        var logger = Logger(label: "customer-service")
        let serviceGroup = try await buildServiceGroup(reader: reader, logger: &logger)
        
        async let _ = ProfileRecorderServer(configuration: .parseFromEnvironment())
            .runIgnoringFailures(logger: logger)

        try await serviceGroup.run()
    }
}
