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
      case "share":
        guard let args = call.arguments as? [String: Any],
          let text = args["text"] as? String
        else {
          result(FlutterError(code: "bad_args", message: "text required", details: nil))
          return
        }
        var items: [Any] = [text]
        if let png = args["image"] as? FlutterStandardTypedData,
          let image = UIImage(data: png.data)
        {
          items.insert(image, at: 0)
        }
        self.presentShareSheet(items: items)
        result(nil)
      case "openSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      case "calendars":
        result(self.calendars())
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

  private func presentShareSheet(items: [Any]) {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    guard var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
      return
    }
    while let presented = top.presentedViewController { top = presented }
    let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // iPad needs an anchor for the popover.
    sheet.popoverPresentationController?.sourceView = top.view
    sheet.popoverPresentationController?.sourceRect = CGRect(
      x: top.view.bounds.midX, y: top.view.bounds.maxY - 80, width: 1, height: 1)
    top.present(sheet, animated: true)
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

  private func calendars() -> [[String: Any]] {
    guard calendarStatus() == "granted" else { return [] }
    return eventStore.calendars(for: .event).map { calendar in
      var color = 0xFF0EA5A0
      if let c = calendar.cgColor?.converted(
        to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil
      )?.components, c.count >= 3 {
        color =
          0xFF00_0000 | (Int(c[0] * 255) << 16) | (Int(c[1] * 255) << 8) | Int(c[2] * 255)
      }
      return [
        "id": calendar.calendarIdentifier,
        "title": calendar.title,
        "source": calendar.source?.title ?? "",
        "color": color,
      ]
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
        "calendarId": event.calendar?.calendarIdentifier ?? "",
      ]
    }
  }
}
