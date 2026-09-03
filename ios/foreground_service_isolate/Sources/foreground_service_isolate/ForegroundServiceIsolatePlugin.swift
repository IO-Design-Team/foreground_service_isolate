import Flutter

public class ForegroundServiceIsolatePlugin: NSObject, FlutterPlugin {
  private let engineGroup = FlutterEngineGroup(name: "foreground_service_isolate", project: nil)
  private var engine: FlutterEngine?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "foreground_service_isolate",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(ForegroundServiceIsolatePlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "spawn":
      spawn(call.arguments as! [String: Any])
      result(nil)
    case "stopService":
      engine?.destroyContext()
      engine = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func spawn(_ args: [String: Any]) {
    guard engine == nil else { return }

    let callback = FlutterCallbackCache.lookupCallbackInformation(
      (args["entryPoint"] as! NSNumber).int64Value
    )!

    let options = FlutterEngineGroupOptions()
    options.entrypoint = callback.callbackName
    options.libraryURI = callback.callbackLibraryPath
    options.entrypointArgs = [
      args["isolateId"] as! String,
      String((args["userEntryPoint"] as! NSNumber).int64Value),
    ]

    engine = engineGroup.makeEngine(with: options)
    (NSClassFromString("GeneratedPluginRegistrant") as? NSObject.Type)?
      .perform(NSSelectorFromString("registerWithRegistry:"), with: engine)
  }
}
