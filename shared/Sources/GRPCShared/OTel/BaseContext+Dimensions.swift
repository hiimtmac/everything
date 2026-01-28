package import OTelSemanticConventions
package import Tracing

extension BaseContext {
    package func dimensions(
        serverHostname: String,
        networkTransportMethod: SpanAttributes.NetworkAttributes.NestedSpanAttributes.TransportEnum
    ) -> [(String, String)] {
        var dimensions: [(String, String)] = []
        dimensions.append(attribute: \.rpc.system, "grpc")
        dimensions.append(attribute: \.server.address, serverHostname)
        dimensions.append(attribute: \.network.transport, networkTransportMethod)
        dimensions.append(attribute: \.rpc.service, self.descriptor.service.fullyQualifiedService)
        dimensions.append(attribute: \.rpc.method, self.descriptor.method)

        switch PeerAddress(self.remotePeer) {
        case let .ipv4(address, port):
            dimensions.append(attribute: \.network.type, .ipv4)
            dimensions.append(attribute: \.network.peer.address, address)
            if let port {
                dimensions.append(attribute: \.network.peer.port, port)
                dimensions.append(attribute: \.server.port, port)
            }
        case let .ipv6(address, port):
            dimensions.append(attribute: \.network.type, .ipv6)
            dimensions.append(attribute: \.network.peer.address, address)
            if let port {
                dimensions.append(attribute: \.network.peer.port, port)
                dimensions.append(attribute: \.server.port, port)
            }
        case let .unixDomainSocket(path):
            dimensions.append(attribute: \.network.peer.address, path)
        case .none:
            break
        }

        return dimensions
    }
}