import Configuration
import GRPCCore
import GRPCNIOTransportHTTP2

// extension HTTP2ClientTransport.Posix {
//     init(reader: ConfigReader) throws {
//         let host = try reader.requiredString(forKey: "host")
//         let port = reader.int(forKey: "port") ?? 50051
//         try self.init(
//             target: .dns(host: host, port: port),
//             transportSecurity: .plaintext
//         )
//     }
// }

extension HTTP2ServerTransport.Posix {
    init(reader: ConfigReader) throws {
        let host = try reader.requiredString(forKey: "host")
        let port = reader.int(forKey: "port") ?? 50051
        self.init(
            address: .ipv4(host: host, port: port),
            transportSecurity: .plaintext
        )
    }
}
