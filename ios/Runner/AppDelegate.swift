import Flutter
import UIKit
import CoreSpotlight
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up Spotlight search method channel
    let controller = window?.rootViewController as! FlutterViewController
    let spotlightChannel = FlutterMethodChannel(
      name: "com.codehive.lifeboard/spotlight",
      binaryMessenger: controller.binaryMessenger
    )

    spotlightChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "indexItems":
        self?.indexSpotlightItems(call: call, result: result)
      case "deindexItem":
        self?.deindexSpotlightItem(call: call, result: result)
      case "deindexAll":
        self?.deindexAllSpotlightItems(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Set up Widget data method channel
    let widgetChannel = FlutterMethodChannel(
      name: "com.codehive.lifeboard/widget",
      binaryMessenger: controller.binaryMessenger
    )

    widgetChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "updateWidgetData":
        guard let args = call.arguments as? [String: Any],
              let appGroupId = args["appGroupId"] as? String,
              let key = args["key"] as? String,
              let data = args["data"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          return
        }
        let defaults = UserDefaults(suiteName: appGroupId)
        defaults?.set(data, forKey: key)
        defaults?.synchronize()
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)

      case "reloadAllTimelines":
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle Spotlight search result tap — pass task ID to Flutter
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == CSSearchableItemActionType,
       let taskId = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
      let controller = window?.rootViewController as? FlutterViewController
      let channel = FlutterMethodChannel(
        name: "com.codehive.lifeboard/spotlight",
        binaryMessenger: controller!.binaryMessenger
      )
      channel.invokeMethod("onSpotlightTap", arguments: ["taskId": taskId])
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  // MARK: - Spotlight Indexing

  private func indexSpotlightItems(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let items = args["items"] as? [[String: String]] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing items", details: nil))
      return
    }

    var searchableItems: [CSSearchableItem] = []

    for item in items {
      let identifier = item["uniqueIdentifier"] ?? ""
      let title = item["title"] ?? ""
      let description = item["contentDescription"] ?? ""

      let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
      attributeSet.title = title
      attributeSet.contentDescription = description
      attributeSet.keywords = title.components(separatedBy: " ")

      let searchableItem = CSSearchableItem(
        uniqueIdentifier: identifier,
        domainIdentifier: "com.codehive.lifeboard.tasks",
        attributeSet: attributeSet
      )
      searchableItems.append(searchableItem)
    }

    CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
      if let error = error {
        result(FlutterError(code: "INDEX_ERROR", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  private func deindexSpotlightItem(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: String],
          let identifier = args["identifier"] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing identifier", details: nil))
      return
    }

    CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
      result(nil)
    }
  }

  private func deindexAllSpotlightItems(result: @escaping FlutterResult) {
    CSSearchableIndex.default().deleteSearchableItems(
      withDomainIdentifiers: ["com.codehive.lifeboard.tasks"]
    ) { error in
      result(nil)
    }
  }
}
