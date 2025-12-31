import GRPCCore
import GRPCShared
import GRPCServer

package struct ServiceImplementation: CustomerServiceServer {
    package init() {
    }
    
    func healthCheck(
        request: ServerRequest<Homebrews_Customer_V1_HealthCheckRequest>,
        context: ServerContext
    ) async throws -> GRPCCore.ServerResponse<Homebrews_Customer_V1_HealthCheckResponse> {
        fatalError()
    }
}
