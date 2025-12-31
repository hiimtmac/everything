import API
import Hummingbird
import Logging
import OpenAPIHummingbird
import OpenAPIServer

typealias AppRequestContext = BasicRequestContext

/// Build router
func buildRouter(
    orderService: some OrderServiceClient,
    customerService: some CustomerServiceClient
) throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        TracingMiddleware()
        MetricsMiddleware()
        LogRequestsMiddleware(.info)
        OpenAPIRequestContextMiddleware()
    }

    // Add OpenAPI handlers
    let api = APIImplementation(
        orderService: orderService,
        customerService: customerService
    )
    try api.registerHandlers(on: router)

    // Add default endpoint
    router.get("/") { _, _ in
        return "Hello!"
    }

    return router
}
