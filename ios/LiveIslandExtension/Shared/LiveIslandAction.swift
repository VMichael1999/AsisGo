import Foundation
#if canImport(AppIntents)
import AppIntents
#endif

/// Cola de botones tocados que aún no llegaron a Dart. Vive en el App Group:
/// el intent se ejecuta en el proceso de la app, que puede estar cerrada.
enum LiveIslandActions {
    private static let key = "live_island.pending_actions"

    private static var defaults: UserDefaults? {
        LiveStorage.appGroup.flatMap { UserDefaults(suiteName: $0) }
    }

    /// Lo asigna el plugin: avisa que hay acciones para entregar a Dart.
    static var onEnqueue: (() -> Void)?

    static func enqueue(_ id: String) {
        var all = defaults?.stringArray(forKey: key) ?? []
        all.append(id)
        defaults?.set(all, forKey: key)
        DispatchQueue.main.async { onEnqueue?() }
    }

    /// Entrega y vacía la cola.
    static func drain() -> [String] {
        let all = defaults?.stringArray(forKey: key) ?? []
        if !all.isEmpty { defaults?.removeObject(forKey: key) }
        return all
    }
}

#if canImport(AppIntents)
/// Lo que ejecuta un botón de la pantalla de bloqueo (iOS 17+). Corre en la app,
/// sin abrirla, y entrega el `id` del botón a Dart (`LiveIsland.onAction`).
@available(iOS 17.0, *)
struct LiveIslandActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "live_island action"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Button")
    var buttonId: String

    init() { buttonId = "" }
    init(buttonId: String) { self.buttonId = buttonId }

    func perform() async throws -> some IntentResult {
        LiveIslandActions.enqueue(buttonId)
        return .result()
    }
}
#endif
