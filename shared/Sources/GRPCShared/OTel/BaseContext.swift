package import GRPCCore

package protocol BaseContext {
    var descriptor: MethodDescriptor { get }
    var remotePeer: String { get }
    var localPeer: String { get }
}

extension ClientContext: BaseContext {}
extension ServerContext: BaseContext {}