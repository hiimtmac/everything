import GRPCShared
public import GRPCCore
public import Metrics
public import OTelSemanticConventions
public import Tracing

/// Instruments the `GRPCClient` with metrics in the OTel convention.
public struct ClientOTelMetricsInterceptor: GRPCCore.ClientInterceptor {
    private let serverHostname: String
    private let networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    private let metricsFactory: (any MetricsFactory)?

    /// Create a new instance of a `ClientOTelMetricsInterceptor`.
    /// - Parameters:
    ///   - serverHostname: The hostname of the RPC server. This will be the value for the `server.address` dimension in metrics.
    ///   - networkTransport: The transport in use (e.g. "tcp", "unix"). This will be the value for the
    ///  `network.transport` dimension in metrics.
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
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        try await self.intercept(
            metricsFactory: self.metricsFactory ?? MetricsSystem.factory,
            request: request,
            context: context,
            next: next
        )
    }

    package func intercept<Input: Sendable, Output: Sendable>(
        metricsFactory: any MetricsFactory,
        request: StreamingClientRequest<Input>,
        context: ClientContext,
        next: (StreamingClientRequest<Input>, ClientContext) async throws -> StreamingClientResponse<Output>
    ) async throws -> StreamingClientResponse<Output> {
        let dimensions = context.dimensions(serverHostname: self.serverHostname, networkTransportMethod: self.networkTransportMethod)

        let metricsContext = GRPCMetricsContext(kind: .client, dimensions: dimensions, metricsFactory: metricsFactory)
        metricsContext.startCall()

        var request = request
        let wrappedProducer = request.producer
        request.producer = { writer in
            let metricsWriter = HookedRPCWriter(wrapping: writer) {
                metricsContext.recordSentMessage()
            }
            try await wrappedProducer(RPCWriter(wrapping: metricsWriter))
        }

        var response = try await next(request, context)

        switch response.accepted {
        case var .success(contents):
            let sequence = HookedAsyncSequence(wrapping: contents.bodyParts) { _ in
                metricsContext.recordReceivedMessage()
            } onFinish: { error in
                metricsContext.recordCallFinished(error: error)
            }

            contents.bodyParts = RPCAsyncSequence(wrapping: sequence)
            response.accepted = .success(contents)
        case let .failure(rpcError):
            metricsContext.recordCallFinished(error: rpcError)
        }

        return response
    }
}