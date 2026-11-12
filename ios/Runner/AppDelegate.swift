import Flutter
import CoreLocation
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSystemStatusChannel(engineBridge.applicationRegistrar.messenger())
  }

  /// Canal `com.asisgo.app/system_status`: estado de solo lectura que ningun
  /// paquete expone con precision.
  ///  - `backgroundRefreshStatus`: Background App Refresh.
  ///  - `locationAuthorization`: autorizacion real de Core Location (distingue
  ///    "sin preguntar" de "rechazada", que permission_handler no separa).
  /// iOS no permite cambiar ninguno de los dos desde la app.
  private func registerSystemStatusChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.asisgo.app/system_status",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      DispatchQueue.main.async {
        switch call.method {
        case "backgroundRefreshStatus":
          switch UIApplication.shared.backgroundRefreshStatus {
          case .available: result("available")
          case .denied: result("denied")
          case .restricted: result("restricted")
          @unknown default: result("unknown")
          }
        case "locationAuthorization":
          switch CLLocationManager().authorizationStatus {
          case .notDetermined: result("notDetermined")
          case .restricted: result("restricted")
          case .denied: result("denied")
          case .authorizedWhenInUse: result("whenInUse")
          case .authorizedAlways: result("always")
          @unknown default: result("unknown")
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
