import Foundation

/// Dónde guarda la app el diseño y las imágenes para que la extensión los lea.
/// `<App Group>/live_island/<layoutId>/layout.json` y `<id>.png`.
enum LiveStorage {
    /// Los diseños con nombre (`registerLayout`) se guardan como `tpl_<nombre>` y no se borran.
    static let templatePrefix = "tpl_"

    /// Nombre del App Group, escrito por `dart run live_island_kit:setup` en el
    /// Info.plist de la app y de la extensión (`LiveIslandAppGroup`).
    static var appGroup: String? {
        Bundle.main.object(forInfoDictionaryKey: "LiveIslandAppGroup") as? String
    }

    static func directory(for layoutId: String, create: Bool = false) -> URL? {
        guard let group = appGroup,
              let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { return nil }
        let dir = root.appendingPathComponent("live_island/\(layoutId)", isDirectory: true)
        if create {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func removeDirectory(for layoutId: String) {
        if let dir = directory(for: layoutId) { try? FileManager.default.removeItem(at: dir) }
    }

    /// Borra los diseños que ya no tienen una actividad viva.
    static func removeAll(except keep: Set<String>) {
        guard let group = appGroup,
              let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
                .appendingPathComponent("live_island", isDirectory: true),
              let items = try? FileManager.default.contentsOfDirectory(atPath: root.path)
        else { return }
        for name in items where !keep.contains(name) && !name.hasPrefix(templatePrefix) {
            try? FileManager.default.removeItem(at: root.appendingPathComponent(name))
        }
    }
}
