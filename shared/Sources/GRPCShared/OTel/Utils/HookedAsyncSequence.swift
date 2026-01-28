package struct HookedAsyncSequence<Wrapped: AsyncSequence & Sendable>: AsyncSequence, Sendable where Wrapped.Element: Sendable {
    package struct HookedAsyncIterator: AsyncIteratorProtocol {
        package typealias Element = Wrapped.Element

        private var wrapped: Wrapped.AsyncIterator
        private let forEachElement: @Sendable (Wrapped.Element) -> Void
        private let onFinish: @Sendable ((any Error)?) -> Void

        init(
            _ iterator: Wrapped.AsyncIterator,
            forEachElement: @escaping @Sendable (Wrapped.Element) -> Void,
            onFinish: @escaping @Sendable ((any Error)?) -> Void
        ) {
            self.wrapped = iterator
            self.forEachElement = forEachElement
            self.onFinish = onFinish
        }

        package mutating func next(isolation actor: isolated (any Actor)?) async throws(Wrapped.Failure) -> Wrapped.Element? {
            do {
                guard let element = try await self.wrapped.next(isolation: actor) else {
                    onFinish(nil)
                    return nil
                }
                forEachElement(element)
                return element
            } catch {
                onFinish(error)
                throw error
            }
        }

        package mutating func next() async throws -> Wrapped.Element? {
            try await self.next(isolation: nil)
        }
    }

    private let wrapped: Wrapped
    private let forEachElement: @Sendable (Wrapped.Element) -> Void
    private let onFinish: @Sendable ((any Error)?) -> Void

    package init(
        wrapping sequence: Wrapped,
        forEachElement: @escaping @Sendable (Wrapped.Element) -> Void,
        onFinish: @escaping @Sendable ((any Error)?) -> Void
    ) {
        self.wrapped = sequence
        self.forEachElement = forEachElement
        self.onFinish = onFinish
    }

    package func makeAsyncIterator() -> HookedAsyncIterator {
        HookedAsyncIterator(
            self.wrapped.makeAsyncIterator(),
            forEachElement: forEachElement,
            onFinish: onFinish
        )
    }
}