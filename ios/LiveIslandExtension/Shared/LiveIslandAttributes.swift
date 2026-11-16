import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Un dato del estado: texto, número, booleano o nulo.
/// Es el mismo contrato que `state.schema.json`.
enum LiveValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else { self = .string(try c.decode(String.self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .bool(let b): try c.encode(b)
        case .null: try c.encodeNil()
        }
    }

    /// Convierte el objeto JSON del estado (ya decodificado) a valores simples.
    static func dictionary(from json: [String: Any]) -> [String: LiveValue] {
        var out: [String: LiveValue] = [:]
        for (k, v) in json {
            if v is NSNull { out[k] = .null }
            else if let n = v as? NSNumber {
                // Los booleanos de JSON llegan como NSNumber con tipo "c".
                if CFGetTypeID(n) == CFBooleanGetTypeID() { out[k] = .bool(n.boolValue) }
                else { out[k] = .number(n.doubleValue) }
            } else if let s = v as? String { out[k] = .string(s) }
        }
        return out
    }

    var text: String {
        switch self {
        case .string(let s): return s
        case .number(let n): return n == n.rounded() && abs(n) < 1e15 ? String(Int64(n)) : String(n)
        case .bool(let b): return b ? "true" : "false"
        case .null: return ""
        }
    }

    var number: Double? {
        switch self {
        case .number(let n): return n
        case .string(let s): return Double(s)
        case .bool(let b): return b ? 1 : 0
        case .null: return nil
        }
    }

    var isTruthy: Bool {
        switch self {
        case .string(let s): return !s.isEmpty
        case .number(let n): return n != 0
        case .bool(let b): return b
        case .null: return false
        }
    }

    /// Fecha ISO 8601 (con o sin fracción de segundo).
    var date: Date? {
        guard case .string(let s) = self else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}

#if canImport(ActivityKit)
/// Atributos genéricos de toda actividad de live_island. El diseño no viaja
/// aquí (ActivityKit limita el total a 4 KB): vive en el App Group y se
/// busca por [layoutId].
@available(iOS 16.1, *)
struct LiveIslandAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var values: [String: LiveValue]
    }

    var layoutId: String
    var deepLink: String?
    /// Id propio de la app (`LiveIsland.start(customId:)`). Opcional: las
    /// actividades creadas por un push o por versiones anteriores no lo traen.
    var customId: String? = nil
}
#endif
