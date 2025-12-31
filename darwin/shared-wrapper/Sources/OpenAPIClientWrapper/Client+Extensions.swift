import OpenAPIURLSession

public import struct Foundation.URL
public import protocol OpenAPIRuntime.ClientMiddleware

#if canImport(Darwin)
    public import class Foundation.URLSession
#else
    #if canImport(FoundationNetworking)
        public import class FoundationNetworking.URLSession
    #endif
#endif

extension Client {
    public init(
        serverURL: URL,
        session: URLSession = .shared,
        middleware: [any ClientMiddleware]
    ) {
        self.init(
            serverURL: serverURL,
            configuration: .init(),
            transport: URLSessionTransport(configuration: .init(session: session)),
            middlewares: middleware
        )
    }
}
