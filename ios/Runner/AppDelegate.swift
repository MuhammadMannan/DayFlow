import EventKit
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let eventStore = EKEventStore()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets reminders appear as banners while DayFlow is in the foreground.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Read-only access to the phone's calendars for the Home and Calendar tabs.
    let channel = FlutterMethodChannel(
      name: "dayflow/calendar",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "status":
        result(self.calendarStatus())
      case "request":
        self.requestCalendarAccess(result: result)
      case "events":
        guard let args = call.arguments as? [String: Any],
          let startMs = args["start"] as? NSNumber,
          let endMs = args["end"] as? NSNumber
        else {
          result(FlutterError(code: "bad_args", message: "start and end required", details: nil))
          return
        }
        result(self.events(startMs: startMs.doubleValue, endMs: endMs.doubleValue))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func calendarStatus() -> String {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *), status == .fullAccess { return "granted" }
    switch status {
    case .authorized: return "granted"
    case .notDetermined: return "notDetermined"
    default: return "denied"
    }
  }

  private func requestCalendarAccess(result: @escaping FlutterResult) {
    let done: (Bool, Error?) -> Void = { granted, _ in
      DispatchQueue.main.async { result(granted ? "granted" : "denied") }
    }
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents(completion: done)
    } else {
      eventStore.requestAccess(to: .event, completion: done)
    }
  }

  private func events(startMs: Double, endMs: Double) -> [[String: Any]] {
    guard calendarStatus() == "granted" else { return [] }
    let start = Date(timeIntervalSince1970: startMs / 1000)
    let end = Date(timeIntervalSince1970: endMs / 1000)
    let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
    return eventStore.events(matching: predicate).map { event in
      [
        "title": event.title ?? "",
        "start": event.startDate.timeIntervalSince1970 * 1000,
        "end": event.endDate.timeIntervalSince1970 * 1000,
        "location": event.location ?? "",
        "allDay": event.isAllDay,
      ]
    }
  }
}
