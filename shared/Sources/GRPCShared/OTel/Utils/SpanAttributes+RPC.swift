internal import Logging
internal import OTelSemanticConventions
package import Tracing

@dynamicMemberLookup
package struct RPCAttributes: SpanAttributeNamespace {
    package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
        package var system: Key<String> {
            "rpc.system"
        }

        package var service: Key<String> {
            "rpc.service"
        }

        package var method: Key<String> {
            "rpc.method"
        }

        package init() {}
    }

    package var attributes: SpanAttributes

    init(attributes: SpanAttributes) {
        self.attributes = attributes
    }
}

extension RPCAttributes {
    /// Message Event Attributes.
    ///
    /// See https://github.com/open-telemetry/semantic-conventions/blob/v1.27.0/docs/rpc/rpc-spans.md#events
    struct MessageAttributes: SpanAttributeNamespace {
        struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            var type: Key<String> {
                "rpc.message.type"
            }

            var id: Key<Int> {
                "rpc.message.id"
            }

            var compressedSizeInBytes: Key<Int> {
                "rpc.message.compressed_size"
            }

            var uncompressedSizeInBytes: Key<Int> {
                "rpc.message.uncompressed_size"
            }

            init() {}
        }

        var attributes: SpanAttributes

        init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    var message: MessageAttributes {
        get {
            MessageAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes {
    /// `https://opentelemetry.io/docs/specs/semconv/rpc/grpc`.
    package struct GRPCAttributes: SpanAttributeNamespace {
        package struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            /// The [numeric status code](https://github.com/grpc/grpc/blob/v1.33.2/doc/statuscodes.md) of the gRPC request.
            ///
            /// E.g. ``RPCAttributes/GRPCAttributes/StatusCode/ok``.
            package var statusCode: Key<String> {
                "rpc.grpc.status_code"
            }

            package static var requestMetadata: Key<String> {
                "rpc.grpc.request.metdata"
            }

            package static var responseMetadata: Key<String> {
                "rpc.grpc.response.metdata"
            }

            package init() {}
        }

        package var attributes: SpanAttributes

        init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    package var gRPC: GRPCAttributes {
        get {
            GRPCAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes.GRPCAttributes {
    struct RequestAttributes: SpanAttributeNamespace {
        struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            init() {}
        }

        var attributes: SpanAttributes

        init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    struct ResponseAttributes: SpanAttributeNamespace {
        struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            init() {}
        }

        var attributes: SpanAttributes

        init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    var request: RequestAttributes {
        get {
            RequestAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }

    var response: ResponseAttributes {
        get {
            ResponseAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes.GRPCAttributes.RequestAttributes {
    struct MetadataAttributes: SpanAttributeNamespace {
        struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            init() {}
        }

        var attributes: SpanAttributes

        init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    var metadata: MetadataAttributes {
        get {
            MetadataAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension RPCAttributes.GRPCAttributes.ResponseAttributes {
    struct MetadataAttributes: SpanAttributeNamespace {
        struct NestedSpanAttributes: NestedSpanAttributesProtocol {
            init() {}
        }

        var attributes: SpanAttributes

        init(attributes: SpanAttributes) {
            self.attributes = attributes
        }
    }

    var metadata: MetadataAttributes {
        get {
            MetadataAttributes(attributes: self.attributes)
        }
        set {
            self.attributes = newValue.attributes
        }
    }
}

extension SpanAttributes {
    package var rpc: RPCAttributes {
        get {
            RPCAttributes(attributes: self)
        }
        set {
            self = newValue.attributes
        }
    }
}

extension RPCAttributes.MessageAttributes.NestedSpanAttributes {
    /// Flag to indicate if the message is compressed.
    var compressed: Key<Bool> {
        "rpc.message.compressed"
    }
}

extension RPCAttributes.GRPCAttributes.RequestAttributes.NestedSpanAttributes {
    var streaming: Key<Bool> {
        "rpc.grpc.request.streaming"
    }
}

extension RPCAttributes.GRPCAttributes.ResponseAttributes.NestedSpanAttributes {
    var streaming: Key<Bool> {
        "rpc.grpc.response.streaming"
    }
}