import GRPCShared
public import GRPCCore
public import Logging
public import OTelSemanticConventions
public import Tracing

/// Logging interceptor for the `GRPCServer`.
public struct ServerOTelLoggingInterceptor: ServerInterceptor {
    private let logger: Logger
    private let serverHostname: String
    private let networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    private var includeRequestMetadata: Bool
    private var includeResponseMetadata: Bool

    /// Initialize an OTel logging interceptor for the gRPC client.
    ///
    /// - Parameters:
    ///   - logger: The `Logger` instance to-be-used in the interceptor. The `Logger.Metadata` should include trace and span IDs for log correlation.
    ///   - severHostname: The hostname of the RPC server. This will be the value for the `server.address` attribute in spans.
    ///   - networkTransportMethod: The transport in use (e.g. "tcp", "unix"). This will be the value for the `network.transport` attribute in spans.
    ///   - includeRequestMetadata: if `true`, **all** metadata keys with string values included in the request will be added to the logger metadata.
    ///   - includeResponseMetadata: if `true`, **all** metadata keys with string values included in the response will be added to the logger metadata.
    public init(
        logger: Logger,
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum,
        includeRequestMetadata: Bool = false,
        includeResponseMetadata: Bool = false
    ) {
        self.logger = logger  // Should include trace and span IDs for log correlation
        self.serverHostname = serverHostname
        self.networkTransportMethod = networkTransportMethod
        self.includeRequestMetadata = includeRequestMetadata
        self.includeResponseMetadata = includeResponseMetadata
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next: (StreamingServerRequest<Input>, ServerContext) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        // Build logging metadata
        var metadata = context.metadata(
            serverHostname: self.serverHostname,
            networkTransportMethod: self.networkTransportMethod,
            requestMetadata: self.includeRequestMetadata ? request.metadata : [:]
        )

        self.logger.trace("Received RPC", metadata: metadata)

        // Invoke handler chain
        var response: StreamingServerResponse<Output>
        do {
            response = try await next(request, context)
        } catch {
            // Indicates a failure triggered down the interceptor chain, not a failure in the actual request processing.
            let errorType = String(describing: type(of: error))
            metadata.append(attribute: \.error.type, .init(rawValue: errorType))
            metadata.append(attribute: \.exception.message, "\(error)")
            metadata.append(attribute: \.exception.type, errorType)

            self.logger.log(
                level: error is CancellationError ? .trace : .info,
                "RPC failed in interceptor chain",
                metadata: metadata
            )
            throw error
        }

        switch response.accepted {
        case .success(var success):
            let wrappedProducer = success.producer

            // Capture Sendable values for the closure (Logger.Metadata is not Sendable)
            let logger = self.logger
            let serverHostname = self.serverHostname
            let networkTransportMethod = self.networkTransportMethod
            let includeResponseMetadata = self.includeResponseMetadata
            let requestMetadataSnapshot = self.includeRequestMetadata ? request.metadata : Metadata()

            success.producer = { writer in
                let responseMetadata: Metadata
                do {
                    responseMetadata = try await wrappedProducer(writer)
                } catch {
                    // Rebuild metadata for error logging
                    var errorMetadata = context.metadata(
                        serverHostname: serverHostname,
                        networkTransportMethod: networkTransportMethod,
                        requestMetadata: requestMetadataSnapshot
                    )
                    let errorType = String(describing: type(of: error))
                    errorMetadata.append(attribute: \.error.type, .init(rawValue: errorType))
                    errorMetadata.append(attribute: \.exception.message, "\(error)")
                    errorMetadata.append(attribute: \.exception.type, errorType)

                    logger.log(
                        level: error is CancellationError ? .trace : .info,
                        "RPC handler failed",
                        metadata: errorMetadata
                    )
                    throw error
                }

                // Rebuild metadata for success logging
                var completionMetadata = context.metadata(
                    serverHostname: serverHostname,
                    networkTransportMethod: networkTransportMethod,
                    requestMetadata: requestMetadataSnapshot
                )
                if includeResponseMetadata {
                    for responseMetadataEntry in responseMetadata {
                        completionMetadata[
                            RPCAttributes.GRPCAttributes.NestedSpanAttributes.responseMetadata.name + "." + responseMetadataEntry.key.lowercased()
                        ] = .string(responseMetadataEntry.value.encoded())
                    }
                }

                logger.trace("Completed RPC", metadata: completionMetadata)
                return responseMetadata
            }

            response.accepted = .success(success)
            return response

        case .failure(let rpcError):
            // A "rejected" request is one where the server responds with a status as the first and only response part.
            metadata.append(attribute: \.rpc.gRPC.statusCode, rpcError.code.description)
            metadata.append(attribute: \.error.type, .init(rawValue: "RPCError"))
            metadata.append(attribute: \.exception.message, rpcError.message)
            metadata.append(attribute: \.exception.type, "RPCError")
            if let cause = rpcError.cause {
                metadata.append(attribute: \.exception.stacktrace, "\(cause)")
            }

            // Error response metadata
            if self.includeResponseMetadata {
                for responseErrorMetadataEntry in rpcError.metadata {
                    metadata[
                        RPCAttributes.GRPCAttributes.NestedSpanAttributes.responseMetadata.name + "." + responseErrorMetadataEntry.key.lowercased()
                    ] = .string(responseErrorMetadataEntry.value.encoded())
                }
            }

            self.logger.log(
                level: rpcError.cause is CancellationError ? .trace : .info,
                "Rejected RPC",
                metadata: metadata
            )
            return response
        }
    }
}