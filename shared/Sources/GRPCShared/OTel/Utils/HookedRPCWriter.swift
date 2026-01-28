package import GRPCCore

package struct HookedRPCWriter<Writer: RPCWriterProtocol>: RPCWriterProtocol {
    private let writer: Writer
    private let afterEachWrite: @Sendable () -> Void

    package init(
        wrapping other: Writer,
        afterEachWrite: @Sendable @escaping () -> Void
    ) {
        self.writer = other
        self.afterEachWrite = afterEachWrite
    }

    package func write(_ element: Writer.Element) async throws {
        try await self.writer.write(element)
        self.afterEachWrite()
    }

    package func write(contentsOf elements: some Sequence<Writer.Element>) async throws {
        try await self.writer.write(contentsOf: elements)
        self.afterEachWrite()
    }
}