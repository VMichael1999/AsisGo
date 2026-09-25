import ActivityKit
import WidgetKit
import SwiftUI

// Struct matching live_activities plugin's LiveActivitiesAppAttributes
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState
    
    public struct ContentState: Codable, Hashable {
        var appGroupId: String
    }
    
    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

struct ShiftLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            let appGroupId = context.state.appGroupId
            let sharedDefault = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
            let prefix = context.attributes.id
            
            let isBreak = (sharedDefault.object(forKey: "\(prefix)_isBreak") as? Bool)
                ?? (sharedDefault.object(forKey: "isBreak") as? Bool)
                ?? false
            let isInsideGeozone = (sharedDefault.object(forKey: "\(prefix)_isInsideGeozone") as? Bool)
                ?? (sharedDefault.object(forKey: "isInsideGeozone") as? Bool)
                ?? true
            let title = sharedDefault.string(forKey: "\(prefix)_title")
                ?? sharedDefault.string(forKey: "title")
                ?? (isBreak ? "Refrigerio en Curso" : "Jornada Activa")
            let subtitle = sharedDefault.string(forKey: "\(prefix)_subtitle")
                ?? sharedDefault.string(forKey: "subtitle")
                ?? "AsisGo"
            let companyName = sharedDefault.string(forKey: "\(prefix)_companyName")
                ?? sharedDefault.string(forKey: "companyName")
                ?? "Sede Central San Isidro"
            let checkInTimeStr = sharedDefault.string(forKey: "\(prefix)_checkInTimeStr")
                ?? sharedDefault.string(forKey: "checkInTimeStr")
                ?? "08:30 AM"
            let checkInEpoch = sharedDefault.double(forKey: "\(prefix)_checkInEpoch") > 0
                ? sharedDefault.double(forKey: "\(prefix)_checkInEpoch")
                : sharedDefault.double(forKey: "checkInEpoch")
            
            let startDate = checkInEpoch > 0 ? Date(timeIntervalSince1970: checkInEpoch / 1000) : Date()
            let endDate = startDate.addingTimeInterval(8 * 3600)
            let timerRange = startDate...endDate
            
            // Dynamic theme color:
            // Break: Orange
            // Inside Geozone: Emerald Green
            // Outside Geozone: Coral Red
            let themeColor: Color = isBreak
                ? Color.orange
                : (isInsideGeozone ? Color(red: 0.0, green: 0.78, blue: 0.45) : Color(red: 0.94, green: 0.27, blue: 0.27))
            let themeBgColor: Color = themeColor.opacity(0.16)
            
            return DynamicIsland {
                // Dynamic Island Expanded (long press)
                DynamicIslandExpandedRegion(.leading) {
                    ZStack {
                        Circle()
                            .fill(themeBgColor)
                            .frame(width: 36, height: 36)
                        Image(systemName: isBreak ? "cup.and.saucer.fill" : (isInsideGeozone ? "person.badge.shield.checkmark.fill" : "exclamationmark.triangle.fill"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeColor)
                    }
                    .padding(.leading, 8)
                    .padding(.top, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: timerRange, countsDown: false)
                            .monospacedDigit()
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(themeColor)
                            .multilineTextAlignment(.trailing)
                        Text("Desde \(checkInTimeStr)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.trailing, 8)
                    .padding(.top, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Fila 1: Título y Sede con ancho total (sin puntos suspensivos ni recortes)
                        HStack(alignment: .center) {
                            Text(title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(companyName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        
                        // Fila 2: Pill de estado de geozona / refrigerio y nombre de sede
                        HStack {
                            // Geozone / State Badge Pill
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(themeColor)
                                    .frame(width: 7, height: 7)
                                Text(isBreak ? "Refrigerio en Curso" : (isInsideGeozone ? "Dentro de Geozona" : "Fuera de Geozona"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(themeColor)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(themeBgColor)
                            .clipShape(Capsule())
                            
                            Spacer()
                            
                            // Sede / Subtitle
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: isBreak ? "cup.and.saucer.fill" : (isInsideGeozone ? "clock.badge.checkmark.fill" : "location.slash.fill"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(themeColor)
                    Text(isBreak ? "PAUSA" : (isInsideGeozone ? "TURNO" : "FUERA"))
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(themeColor)
                }
                .padding(.leading, 5)
            } compactTrailing: {
                Text(timerInterval: timerRange, countsDown: false)
                    .monospacedDigit()
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(themeColor)
                    .frame(minWidth: 52, alignment: .trailing)
                    .padding(.trailing, 4)
            } minimal: {
                Image(systemName: isBreak ? "cup.and.saucer.fill" : (isInsideGeozone ? "checkmark.shield.fill" : "exclamationmark.triangle.fill"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(themeColor)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LiveActivitiesAppAttributes>
    
    var body: some View {
        let appGroupId = context.state.appGroupId
        let sharedDefault = UserDefaults(suiteName: appGroupId) ?? UserDefaults.standard
        let prefix = context.attributes.id
        
        let isBreak = (sharedDefault.object(forKey: "\(prefix)_isBreak") as? Bool)
            ?? (sharedDefault.object(forKey: "isBreak") as? Bool)
            ?? false
        let isInsideGeozone = (sharedDefault.object(forKey: "\(prefix)_isInsideGeozone") as? Bool)
            ?? (sharedDefault.object(forKey: "isInsideGeozone") as? Bool)
            ?? true
        let title = sharedDefault.string(forKey: "\(prefix)_title")
            ?? sharedDefault.string(forKey: "title")
            ?? (isBreak ? "Refrigerio en Curso" : "Jornada Activa")
        let subtitle = sharedDefault.string(forKey: "\(prefix)_subtitle")
            ?? sharedDefault.string(forKey: "subtitle")
            ?? "AsisGo • Asistencia en Vivo"
        let companyName = sharedDefault.string(forKey: "\(prefix)_companyName")
            ?? sharedDefault.string(forKey: "companyName")
            ?? "Sede Central San Isidro"
        let checkInTimeStr = sharedDefault.string(forKey: "\(prefix)_checkInTimeStr")
            ?? sharedDefault.string(forKey: "checkInTimeStr")
            ?? "08:30 AM"
        let checkInEpoch = sharedDefault.double(forKey: "\(prefix)_checkInEpoch") > 0
            ? sharedDefault.double(forKey: "\(prefix)_checkInEpoch")
            : sharedDefault.double(forKey: "checkInEpoch")
        
        let startDate = checkInEpoch > 0 ? Date(timeIntervalSince1970: checkInEpoch / 1000) : Date()
        let endDate = startDate.addingTimeInterval(8 * 3600)
        let timerRange = startDate...endDate
        
        let themeColor: Color = isBreak
            ? Color.orange
            : (isInsideGeozone ? Color(red: 0.0, green: 0.78, blue: 0.45) : Color(red: 0.94, green: 0.27, blue: 0.27))
        let themeBgColor: Color = themeColor.opacity(0.16)
        
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.13))
            
            VStack(alignment: .leading, spacing: 10) {
                // Top header row
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundColor(themeColor)
                        Text("AsisGo")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        Text(isBreak ? "REFRIGERIO" : (isInsideGeozone ? "EN TURNO" : "FUERA DE GEOZONA"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeBgColor)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Timer
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        Text(timerInterval: timerRange, countsDown: false)
                            .monospacedDigit()
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(themeColor)
                    }
                }
                
                // Middle body
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(themeBgColor)
                            .frame(width: 42, height: 42)
                        Image(systemName: isBreak ? "cup.and.saucer.fill" : (isInsideGeozone ? "building.2.crop.circle.fill" : "location.slash.fill"))
                            .font(.system(size: 20))
                            .foregroundColor(themeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(companyName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Hora Entrada")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text(checkInTimeStr)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Bottom footer chip
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: isInsideGeozone ? "location.fill" : "location.slash.fill")
                            .font(.system(size: 9))
                            .foregroundColor(themeColor)
                        Text(isInsideGeozone ? "Geocerca validada por GPS" : "Fuera del perímetro de geozona")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isInsideGeozone ? .white.opacity(0.65) : Color(red: 0.94, green: 0.27, blue: 0.27))
                    }
                    
                    Spacer()
                    
                    Text("Jornada esperada: 8h 00m")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                }
            }
            .padding(14)
        }
        .activityBackgroundTint(Color.clear)
        .activitySystemActionForegroundColor(.white)
    }
}
