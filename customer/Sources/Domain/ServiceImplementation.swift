import GRPCCore
import GRPCShared
import GRPCServer
import SwiftProtobuf

package struct ServiceImplementation: CustomerServiceServer {
    package init() {
    }
    
    func healthCheck(
        request: Everything_Customer_V1_HealthCheckRequest,
        context: ServerContext
    ) async throws -> Everything_Customer_V1_HealthCheckResponse {
        .with {
            $0.status = "SERVING"
            $0.service = "customer"
        }
    }
}
