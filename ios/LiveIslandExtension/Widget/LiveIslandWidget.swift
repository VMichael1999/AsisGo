import ActivityKit
import SwiftUI
import WidgetKit

/// Pantalla de bloqueo, Dynamic Island, StandBy, Watch y CarPlay de toda
/// actividad de live_island. El diseño se lee del App Group por [layoutId].
@available(iOS 16.1, *)
struct LiveIslandWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveIslandAttributes.self) { context in
            LiveLockScreenView(attributes: context.attributes, state: context.state,
                               isStale: LiveIslandSurfaces.isStale(context))
        } dynamicIsland: { context in
            LiveIslandSurfaces.dynamicIsland(context)
        }
    }
}

@available(iOS 16.1, *)
enum LiveIslandSurfaces {
    /// `ActivityViewContext.isStale` existe desde iOS 16.2.
    static func isStale(_ context: ActivityViewContext<LiveIslandAttributes>) -> Bool {
        if #available(iOS 16.2, *) { return context.isStale }
        return false
    }

    /// A dónde lleva el toque: el `$url` del estado (cambia con cada actualización)
    /// y, si no hay, el `deepLink` con el que empezó la actividad.
    static func tapURL(_ attributes: LiveIslandAttributes,
                       _ state: LiveIslandAttributes.ContentState) -> URL? {
        if let text = state.values["$url"]?.text, !text.isEmpty, let url = URL(string: text) { return url }
        return attributes.deepLink.flatMap { URL(string: $0) }
    }

    private static func ctx(_ attributes: LiveIslandAttributes,
                            _ state: LiveIslandAttributes.ContentState,
                            stale: Bool = false) -> LiveCtx? {
        guard let doc = LiveLayoutDoc.load(attributes.layoutId) else { return nil }
        // `$stale` es un campo reservado: lo pone el sistema, no el estado.
        return LiveCtx(doc: doc, values: stateValues(state, stale: stale),
                       style: LiveStyle(tone: .dark, accent: doc.accent, mutedAlpha: 0.62))
    }

    private static func region(_ name: String, _ c: LiveCtx?, slot: CGFloat? = nil,
                               iconSize: CGFloat? = nil, align: String? = nil) -> AnyView {
        guard let c = c, let n = c.doc.region(name) else { return AnyView(EmptyView()) }
        return LiveRenderer.render(n, c, slot: slot, iconSize: iconSize, align: align)
    }

    private static func zone(_ name: String, _ c: LiveCtx?, slot: CGFloat? = nil,
                             iconSize: CGFloat? = nil, align: String? = nil) -> AnyView {
        guard let c = c, let n = c.doc.expanded(name) else { return AnyView(EmptyView()) }
        let island = LiveCtx(doc: c.doc, values: c.values, style: c.style, island: true)
        return LiveRenderer.render(n, island, slot: slot, iconSize: iconSize, align: align)
    }

    static func stateValues(_ state: LiveIslandAttributes.ContentState,
                            stale: Bool) -> [String: LiveValue] {
        var values = state.values
        values["$stale"] = .bool(stale)
        return values
    }

    static func dynamicIsland(
        _ context: ActivityViewContext<LiveIslandAttributes>
    ) -> DynamicIsland {
        let c = ctx(context.attributes, context.state, stale: isStale(context))
        let minimalNode = c?.doc.region("minimal")
        let minimalIsRing = minimalNode?.t == "ring"
        let url = LiveIslandSurfaces.tapURL(context.attributes, context.state)

        return DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                zone("leading", c, slot: 46, iconSize: 38)
            }
            DynamicIslandExpandedRegion(.trailing) {
                // Margen: la curva de la isla recorta lo que va pegado al borde (el «78'»).
                zone("trailing", c, slot: 46, align: "end").padding(.trailing, 4)
            }
            DynamicIslandExpandedRegion(.center) {
                zone("center", c)
            }
            DynamicIslandExpandedRegion(.bottom) {
                // Margen: las esquinas redondeadas de la isla recortan el borde.
                zone("bottom", c).padding(.horizontal, 6).padding(.bottom, 8)
            }
        } compactLeading: {
            region("compactLeading", c, slot: 22, iconSize: 18)
        } compactTrailing: {
            region("compactTrailing", c)
        } minimal: {
            region("minimal", c, slot: minimalIsRing ? 33 : 24, iconSize: minimalIsRing ? 14 : 18)
        }
        .widgetURL(url)
    }
}

/// Tarjeta de la pantalla de bloqueo (y banner de notificación).
@available(iOS 16.1, *)
struct LiveLockScreenView: View {
    let attributes: LiveIslandAttributes
    let state: LiveIslandAttributes.ContentState
    var isStale: Bool = false

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if let doc = LiveLayoutDoc.load(attributes.layoutId) {
            if let h = hoisted(doc) {
                // Un solo contenedor: el color de la caja raíz es el fondo de
                // toda la tarjeta y el diseño trae sus propios márgenes.
                content(doc, override: h.child)
                    .activityBackgroundTint(h.color)
                    .widgetURL(LiveIslandSurfaces.tapURL(attributes, state))
            } else {
                content(doc)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .activityBackgroundTint(tint(doc))
                    .widgetURL(LiveIslandSurfaces.tapURL(attributes, state))
            }
        } else {
            EmptyView()
        }
    }

    /// Si la raíz del diseño es una caja con color opaco (sin borde, halo ni
    /// tamaño fijo), ese color pasa a ser el fondo de la tarjeta y se dibuja
    /// solo su contenido: así no quedan dos contenedores uno dentro del otro.
    private func hoisted(_ doc: LiveLayoutDoc) -> (color: Color, child: LNode)? {
        guard let root = doc.lockCustom, root.t == "box",
              let hex = root.string("color"),
              root.string("border") == nil, root.double("glow") == nil,
              root.double("size") == nil,
              let child = root.node("child") else { return nil }
        return (Color(hex: hex), child)
    }

    private func tone(_ doc: LiveLayoutDoc) -> LiveTone {
        switch doc.background {
        case "light": return .light
        case "accent": return .accent
        default: return scheme == .dark ? .dark : .light
        }
    }

    /// `system` deja el fondo al sistema (nil).
    private func tint(_ doc: LiveLayoutDoc) -> Color? {
        switch doc.background {
        case "light": return Color(red: 250 / 255, green: 250 / 255, blue: 252 / 255).opacity(0.86)
        case "accent": return doc.accent
        default: return nil
        }
    }

    @ViewBuilder
    private func content(_ doc: LiveLayoutDoc, override: LNode? = nil) -> some View {
        let c = LiveCtx(doc: doc,
                        values: LiveIslandSurfaces.stateValues(state, stale: isStale),
                        style: LiveStyle(tone: tone(doc), accent: doc.accent))
        if let custom = override ?? doc.lockCustom {
            LiveRenderer.render(custom, c)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    if let lead = LiveLockLeading.view(doc, c) { lead }
                    if let center = doc.expanded("center") {
                        LiveRenderer.render(center, c).frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer(minLength: 0)
                    }
                    if let trailing = doc.expanded("trailing") {
                        LiveRenderer.render(trailing, c, slot: 46, align: "end")
                            .frame(maxWidth: 124, alignment: .trailing)
                    }
                }
                if let bottom = doc.expanded("bottom") {
                    LiveRenderer.render(bottom, c)
                }
            }
        }
    }
}

/// Ícono de la app en la tarjeta de bloqueo (40 pt): logo, avatar o ícono
/// sobre un cuadro de acento (ver doc/contract/README.md).
enum LiveLockLeading {
    static func view(_ doc: LiveLayoutDoc, _ c: LiveCtx) -> AnyView? {
        let logo = doc.appLogo
        if let logo = logo, logo.t == "image" {
            return LiveRenderer.image(logo, c, size: 40)
        }
        let lead = doc.expanded("leading")
        if let lead = lead, lead.t == "avatar" {
            return LiveRenderer.avatar(lead, c, size: 40,
                                       background: c.style.isAccent ? Color.white.opacity(0.25) : nil)
        }
        if let lead = lead, lead.t == "image" {
            return LiveRenderer.image(lead, c, size: 40)
        }
        let icon: LNode? = (logo?.t == "icon" ? logo : nil)
            ?? (lead?.t == "box" ? lead?.node("child").flatMap { $0.t == "icon" ? $0 : nil } : nil)
        guard let ic = icon else { return nil }
        return AnyView(LiveRenderer.icon(ic, c, size: 22, color: .white)
            .frame(width: 40, height: 40)
            .background(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(c.style.isAccent ? Color.white.opacity(0.22) : c.style.accent)))
    }
}
