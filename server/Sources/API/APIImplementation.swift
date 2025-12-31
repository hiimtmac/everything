import OpenAPIShared

package struct APIImplementation: APIProtocol {
    let orderService: any OrderServiceClient
    let customerService: any CustomerServiceClient
    
    package init(
        orderService: some OrderServiceClient,
        customerService: some CustomerServiceClient
    ) {
        self.orderService = orderService
        self.customerService = customerService
    }
    
    func healthCheck(
        _ input: Operations.healthCheck.Input
    ) async throws -> Operations.healthCheck.Output {
        fatalError()
    }
}
