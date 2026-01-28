import GRPCShared
public import GRPCCore
public import Metrics
public import OTelSemanticConventions
public import Tracing

public struct ServerOTelMetricsInterceptor: ServerInterceptor {
    private let serverHostname: String
    private let networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    private let metricsFactory: (any MetricsFactory)?

    public init(
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    ) {
        self.init(
            serverHostname: serverHostname, 
            networkTransportMethod: networkTransportMethod, 
            metricsFactory: nil
        )
    }

    /// A server interceptor that records metrics information for a request.
    ///
    /// For more information, refer to the documentation for `swift-metrics`.
    ///
    /// This interceptor will record all required and recommended metrics and dimensions as defined by OpenTelemetry's documentation on:
    /// - https://opentelemetry.io/docs/specs/semconv/rpc/rpc-metrics
    public init(
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum,
        metricsFactory: (any MetricsFactory)?
    ) {
        self.serverHostname = serverHostname
        self.networkTransportMethod = networkTransportMethod
        self.metricsFactory = metricsFactory
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next: (StreamingServerRequest<Input>, ServerContext) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        try await self.intercept(
            metricsFactory: self.metricsFactory ?? MetricsSystem.factory,
            request: request,
            context: context,
            next: next
        )
    }

    package func intercept<Input: Sendable, Output: Sendable>(
        metricsFactory: any MetricsFactory,
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next: (StreamingServerRequest<Input>, ServerContext) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        let dimensions = context.dimensions(serverHostname: self.serverHostname, networkTransportMethod: self.networkTransportMethod)

        let metricsContext = GRPCMetricsContext(kind: .server, dimensions: dimensions, metricsFactory: metricsFactory)

        var request = request
        request.messages = RPCAsyncSequence(
            wrapping: request.messages.map({ element in
                metricsContext.recordReceivedMessage()
                return element
            })
        )

        var response = try await next(request, context)

        switch response.accepted {
        case .success(var success):
            let wrappedProducer = success.producer

            success.producer = { writer in
                let hookedWriter = HookedRPCWriter(wrapping: writer) {
                    metricsContext.recordSentMessage()
                }

                let metadata: Metadata
                do {
                    metadata = try await wrappedProducer(RPCWriter(wrapping: hookedWriter))
                } catch {
                    metricsContext.recordCallFinished(error: error)
                    throw error
                }

                metricsContext.recordCallFinished(error: nil)
                return metadata
            }

            response.accepted = .success(success)
            return response
        case .failure(let rpcError):
            metricsContext.recordCallFinished(error: rpcError)
        }

        return response
    }
}
