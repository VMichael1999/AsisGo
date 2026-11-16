import SwiftUI
import UIKit

/// Un nodo del contrato JSON (`layout.schema.json`): un objeto con `t`.
struct LNode {
    let d: [String: Any]

    var t: String { d["t"] as? String ?? "" }
    func string(_ k: String) -> String? { d[k] as? String }
    func double(_ k: String) -> Double? { (d[k] as? NSNumber)?.doubleValue }
    func int(_ k: String) -> Int? { (d[k] as? NSNumber)?.intValue }
    func bool(_ k: String) -> Bool { (d[k] as? NSNumber)?.boolValue ?? false }
    func has(_ k: String) -> Bool { d[k] != nil }

    func node(_ k: String) -> LNode? {
        guard let m = d[k] as? [String: Any] else { return nil }
        return LNode(d: m)
    }

    var children: [LNode] {
        (d["c"] as? [[String: Any]] ?? []).map { LNode(d: $0) }
    }

    /// Este nodo y todos sus descendientes.
    var descendants: [LNode] {
        var out = [self]
        for c in children { out += c.descendants }
        for k in ["child", "then", "else", "tracker", "visual", "start", "end", "icon"] {
            if let n = node(k) { out += n.descendants }
        }
        return out
    }
}

/// El diseño de una actividad, leído del App Group.
final class LiveLayoutDoc {
    let root: [String: Any]
    let dir: URL?

    private var imageCache: [String: UIImage] = [:]
    private static var cache: [String: LiveLayoutDoc] = [:]

    init(root: [String: Any], dir: URL?) {
        self.root = root
        self.dir = dir
    }

    /// Lee (y recuerda) el diseño con ese id.
    static func load(_ layoutId: String) -> LiveLayoutDoc? {
        if let c = cache[layoutId] { return c }
        guard let dir = LiveStorage.directory(for: layoutId),
              let data = try? Data(contentsOf: dir.appendingPathComponent("layout.json")),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        let doc = LiveLayoutDoc(root: json, dir: dir)
        cache[layoutId] = doc
        return doc
    }

    static func forget(_ layoutId: String) { cache[layoutId] = nil }

    private var theme: [String: Any] { root["theme"] as? [String: Any] ?? [:] }
    private var regions: [String: Any] { root["regions"] as? [String: Any] ?? [:] }

    var accent: Color { Color(hex: theme["accent"] as? String ?? "#1F6FEB") }
    var background: String { theme["background"] as? String ?? "system" }

    func region(_ name: String) -> LNode? {
        (regions[name] as? [String: Any]).map { LNode(d: $0) }
    }

    func expanded(_ zone: String) -> LNode? {
        guard let e = regions["expanded"] as? [String: Any],
              let z = e[zone] as? [String: Any] else { return nil }
        return LNode(d: z)
    }

    /// `nil` = reutiliza la isla expandida.
    var lockCustom: LNode? {
        guard let l = regions["lockScreen"] as? [String: Any], l["same"] == nil else { return nil }
        return LNode(d: l)
    }

    var appLogo: LNode? { (root["appLogo"] as? [String: Any]).map { LNode(d: $0) } }

    /// Todos los nodos de las regiones, para buscar progreso, botones, etc.
    var expandedNodes: [LNode] {
        ["leading", "center", "trailing", "bottom"].compactMap { expanded($0) }.flatMap { $0.descendants }
    }

    /// Ids de los botones en el orden en que aparecen (isla expandida y bloqueo).
    lazy var buttonOrder: [String] = {
        var nodes = expandedNodes
        if let custom = lockCustom { nodes += custom.descendants }
        var seen: [String] = []
        for n in nodes where n.t == "button" || n.t == "toggle" {
            if let id = n.string("id"), !seen.contains(id) { seen.append(id) }
        }
        return seen
    }()

    func image(_ id: String) -> UIImage? {
        if let c = imageCache[id] { return c }
        guard let dir = dir else { return nil }
        let meta = (root["images"] as? [String: Any])?[id] as? [String: Any]
        let file = meta?["file"] as? String ?? "\(id).png"
        guard let img = UIImage(contentsOfFile: dir.appendingPathComponent(file).path) else { return nil }
        imageCache[id] = img
        return img
    }
}

extension Color {
    /// `#RRGGBB` o `#RRGGBBAA`.
    init(hex: String) {
        var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        if s.count == 6 { s += "FF" }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 24) & 0xFF) / 255,
                  green: Double((v >> 16) & 0xFF) / 255,
                  blue: Double((v >> 8) & 0xFF) / 255,
                  opacity: Double(v & 0xFF) / 255)
    }
}
