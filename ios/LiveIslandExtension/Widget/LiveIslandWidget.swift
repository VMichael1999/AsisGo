import ActivityKit
import SwiftUI
import WidgetKit

// Diseño propio de AsisGo para la Dynamic Island y la pantalla de bloqueo.
//
// Sustituye al renderizador genérico de live_island_kit: los datos llegan en
// `ContentState.values` (los envía LiveActivityService desde Dart) y aquí se
// dibujan con medidas fijas. Los contadores y el anillo los anima iOS según la
// hora, así que siguen avanzando con la app en segundo plano.
//
// OJO: `dart run live_island_kit:setup` reescribe este archivo. Si se vuelve a
// ejecutar, hay que restaurarlo desde git.

// MARK: - Datos

@available(iOS 16.1, *)
struct ShiftData {
    let isLunch: Bool
    let title: String
    let schedule: String
    let checkInText: String
    let checkOutText: String
    let checkIn: Date
    let shiftEnd: Date
    let lunchStart: Date

    init(_ state: LiveIslandAttributes.ContentState) {
        let v = state.values
        let now = Date()
        isLunch = v["fase"]?.text == "refrigerio"
        title = v["titulo"]?.text ?? "En jornada"
        schedule = v["horario"]?.text ?? ""
        checkInText = v["entradaTxt"]?.text ?? ""
        checkOutText = v["salidaTxt"]?.text ?? ""
        checkIn = v["entradaTs"]?.date ?? now
        shiftEnd = v["finTs"]?.date ?? now.addingTimeInterval(9 * 3600)
        lunchStart = v["refrigerioDesde"]?.date ?? now
    }

    /// Color de la fase: verde en jornada, naranja en refrigerio.
    var accent: Color { isLunch ? AsisColors.orange : AsisColors.green }

    /// Icono de la fase.
    var icon: String { isLunch ? "fork.knife" : "briefcase" }

    /// Desde cuándo cuenta el contador principal.
    var timerStart: Date { isLunch ? lunchStart : checkIn }

    /// Rango del anillo: la jornada completa o la hora de refrigerio.
    var ringRange: ClosedRange<Date> {
        let start = timerStart
        let end = isLunch ? lunchStart.addingTimeInterval(60 * 60) : shiftEnd
        return start...(end > start ? end : start.addingTimeInterval(60))
    }
}

enum AsisColors {
    static let green = Color(red: 0.302, green: 0.851, blue: 0.471) // #4DD978
    static let orange = Color(red: 1.0, green: 0.624, blue: 0.039)  // #FF9F0A
    static let gray = Color(red: 0.557, green: 0.557, blue: 0.576)  // #8E8E93
    static let track = Color(red: 0.227, green: 0.227, blue: 0.235) // #3A3A3C
    static let card = Color(red: 0.110, green: 0.110, blue: 0.118)  // #1C1C1E
}

// MARK: - Piezas

/// Anillo de progreso animado por iOS, con un icono opcional en el centro.
@available(iOS 16.1, *)
struct ShiftRing: View {
    let data: ShiftData
    let size: CGFloat
    var iconSize: CGFloat? = nil

    var body: some View {
        ZStack {
            ProgressView(timerInterval: data.ringRange, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.circular)
            .tint(data.accent)
            .frame(width: size, height: size)

            if let iconSize {
                Image(systemName: data.icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(data.accent)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Contador ascendente "2:14:45".
@available(iOS 16.1, *)
struct ElapsedTimer: View {
    let since: Date

    var body: some View {
        Text(timerInterval: since...Date.distantFuture, countsDown: false)
            .monospacedDigit()
    }
}

/// Contador ascendente corto "2:14" (horas y minutos).
@available(iOS 16.1, *)
struct ShortElapsedTimer: View {
    let since: Date

    var body: some View {
        if #available(iOS 18.0, *) {
            Text(.currentDate, format: .timer(
                countingUpIn: since..<Date.distantFuture,
                maxFieldCount: 2
            ))
            .monospacedDigit()
        } else {
            ElapsedTimer(since: since)
        }
    }
}

/// Cuenta regresiva corta "6:45 h" hasta la hora de salida.
@available(iOS 16.1, *)
struct RemainingTimer: View {
    let until: Date

    var body: some View {
        let now = Date()
        if until <= now {
            Text("0:00 h")
        } else if #available(iOS 18.0, *) {
            Text(.currentDate, format: .timer(
                countingDownIn: now..<until,
                maxFieldCount: 2
            ))
            .monospacedDigit() + Text(" h")
        } else {
            Text(timerInterval: now...until, countsDown: true)
                .monospacedDigit()
        }
    }
}

// MARK: - Isla expandida

@available(iOS 16.1, *)
struct ExpandedShiftView: View {
    let data: ShiftData

    var body: some View {
        HStack(spacing: 12) {
            ShiftRing(data: data, size: 38, iconSize: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(data.schedule)
                    .font(.system(size: 12))
                    .foregroundColor(AsisColors.gray)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            ElapsedTimer(since: data.timerStart)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(data.accent)
                .multilineTextAlignment(.trailing)
                .frame(width: 128, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

// MARK: - Pantalla de bloqueo

@available(iOS 16.1, *)
struct LockScreenShiftView: View {
    let data: ShiftData

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ShiftRing(data: data, size: 54, iconSize: 18)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle().fill(data.accent).frame(width: 7, height: 7)
                        Text(data.isLunch ? "En refrigerio" : "En jornada")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(data.accent)
                    }
                    ElapsedTimer(since: data.timerStart)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 170, alignment: .leading)
                }
                Spacer(minLength: 0)
                VStack {
                    Text("AsisGo")
                        .font(.system(size: 12))
                        .foregroundColor(AsisColors.gray)
                    Spacer(minLength: 0)
                }
            }
            .frame(height: 56)

            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)

            HStack(spacing: 0) {
                column("Entrada") { Text(data.checkInText) }
                divider
                column("Faltan") { RemainingTimer(until: data.shiftEnd) }
                divider
                column("Salida") { Text(data.checkOutText) }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(width: 1, height: 30)
    }

    private func column<V: View>(_ label: String, @ViewBuilder value: () -> V) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AsisColors.gray)
            value()
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget

@available(iOS 16.1, *)
struct LiveIslandWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveIslandAttributes.self) { context in
            LockScreenShiftView(data: ShiftData(context.state))
                .activityBackgroundTint(AsisColors.card)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let data = ShiftData(context.state)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedShiftView(data: data)
                }
            } compactLeading: {
                Image(systemName: data.isLunch ? "fork.knife" : "checkmark.circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(data.accent)
            } compactTrailing: {
                ShortElapsedTimer(since: data.timerStart)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(data.accent)
                    .frame(maxWidth: 64, alignment: .trailing)
            } minimal: {
                ShiftRing(data: data, size: 22)
            }
        }
    }
}
