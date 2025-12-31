package import GRPCCore
package import GRPCShared
import GRPCServer

package struct ServiceImplementation: OrderServiceServer {
    let customerService: any CustomerServiceClient
    
    package init(
        customerService: some CustomerServiceClient
    ) {
        self.customerService = customerService
    }
    
    package func healthCheck(
        request: ServerRequest<Homebrews_Order_V1_HealthCheckRequest>,
        context: ServerContext
    ) async throws -> ServerResponse<Homebrews_Order_V1_HealthCheckResponse> {
        fatalError()
    }
}
