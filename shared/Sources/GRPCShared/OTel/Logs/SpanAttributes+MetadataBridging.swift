internal import Logging
package import Tracing

extension Logger.Metadata {
    package mutating func append<T: SpanAttributeConvertible>(attribute keyPath: WritableKeyPath<SpanAttributes, T?>, _ value: T) {
        var attributes = SpanAttributes()
        attributes[keyPath: keyPath] = value

        // swift-format-ignore: ReplaceForEachWithForLoop
        attributes.forEach { key, attribute in
            self[key] = .string(attribute.dimensionDescription)
        }
    }
}