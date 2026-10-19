import Flutter
import UIKit
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let eventStore = EKEventStore()
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MossLockScreen")
    let channel = FlutterMethodChannel(
      name: "com.moss.moss/lockscreen",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "applyLockScreen" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let typedData = arguments["bytes"] as? FlutterStandardTypedData
      else {
        result(FlutterError(code: "INVALID_IMAGE", message: "Wallpaper bytes are missing", details: nil))
        return
      }
      self?.shareWallpaper(data: typedData.data, result: result)
    }

    let calendarChannel = FlutterMethodChannel(
      name: "com.moss.moss/calendar",
      binaryMessenger: registrar.messenger()
    )
    calendarChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "checkAccess":
        let status: EKAuthorizationStatus
        if #available(iOS 17.0, *) {
          status = EKEventStore.authorizationStatus(for: .event)
          result(status == .fullAccess ? "granted" : (status == .notDetermined ? "undetermined" : "denied"))
        } else {
          status = EKEventStore.authorizationStatus(for: .event)
          result(status == .authorized ? "granted" : (status == .notDetermined ? "undetermined" : "denied"))
        }
      case "requestAccess":
        self.requestCalendarAccess(result: result)
      case "fetchEvents":
        guard
          let arguments = call.arguments as? [String: Any],
          let startMs = arguments["start"] as? NSNumber,
          let endMs = arguments["end"] as? NSNumber
        else {
          result(FlutterError(code: "INVALID_RANGE", message: "Calendar date range is missing", details: nil))
          return
        }
        self.fetchCalendarEvents(startMs: startMs.int64Value, endMs: endMs.int64Value, result: result)
      case "addCompletedTask":
        guard
          let arguments = call.arguments as? [String: Any],
          let title = arguments["title"] as? String,
          let startMs = arguments["start"] as? NSNumber,
          let endMs = arguments["end"] as? NSNumber
        else {
          result(false)
          return
        }
        self.addCompletedTask(title: title, startMs: startMs.int64Value, endMs: endMs.int64Value, result: result)
      case "upsertTaskEvent":
        guard
          let arguments = call.arguments as? [String: Any],
          let title = arguments["title"] as? String,
          let startMs = arguments["start"] as? NSNumber,
          let endMs = arguments["end"] as? NSNumber
        else {
          result(nil)
          return
        }
        self.upsertTaskEvent(
          eventId: arguments["eventId"] as? String,
          title: title,
          startMs: startMs.int64Value,
          endMs: endMs.int64Value,
          completed: arguments["completed"] as? Bool ?? false,
          notes: arguments["notes"] as? String,
          result: result
        )
      case "deleteEvent":
        guard
          let arguments = call.arguments as? [String: Any],
          let eventId = arguments["eventId"] as? String
        else {
          result(false)
          return
        }
        self.deleteCalendarEvent(eventId: eventId, result: result)
      case "openAppSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func requestCalendarAccess(result: @escaping FlutterResult) {
    let completion: (Bool, Error?) -> Void = { granted, _ in
      DispatchQueue.main.async { result(granted ? "granted" : "denied") }
    }
    if #available(iOS 17.0, *) {
      eventStore.requestFullAccessToEvents(completion: completion)
    } else {
      eventStore.requestAccess(to: .event, completion: completion)
    }
  }

  private func fetchCalendarEvents(startMs: Int64, endMs: Int64, result: FlutterResult) {
    let start = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
    let end = Date(timeIntervalSince1970: Double(endMs) / 1000.0)
    let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
    let events = eventStore.events(matching: predicate).map { event in
      [
        "id": event.eventIdentifier ?? "",
        "title": event.title ?? "",
        "start": Int64(event.startDate.timeIntervalSince1970 * 1000),
        "end": Int64(event.endDate.timeIntervalSince1970 * 1000),
        "allDay": event.isAllDay,
        "calendarName": event.calendar.title,
        "location": event.location ?? "",
        "description": event.notes ?? "",
      ] as [String: Any]
    }
    result(events)
  }

  private func addCompletedTask(title: String, startMs: Int64, endMs: Int64, result: FlutterResult) {
    upsertTaskEvent(
      eventId: nil,
      title: title,
      startMs: startMs,
      endMs: endMs,
      completed: true,
      notes: nil,
      result: result
    )
  }

  private func upsertTaskEvent(
    eventId: String?,
    title: String,
    startMs: Int64,
    endMs: Int64,
    completed: Bool,
    notes: String?,
    result: FlutterResult
  ) {
    guard let calendar = eventStore.defaultCalendarForNewEvents else {
      result(nil)
      return
    }
    let event = eventId.flatMap { eventStore.event(withIdentifier: $0) } ?? EKEvent(eventStore: eventStore)
    if event.calendar == nil { event.calendar = calendar }
    event.title = completed ? "✓ \(title)" : title
    event.notes = [notes, "ซิงก์จาก Moss"]
      .compactMap { $0 }
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")
    event.startDate = Date(timeIntervalSince1970: Double(startMs) / 1000.0)
    event.endDate = Date(timeIntervalSince1970: Double(endMs) / 1000.0)
    do {
      try eventStore.save(event, span: .thisEvent)
      result(event.eventIdentifier)
    } catch {
      result(nil)
    }
  }

  private func deleteCalendarEvent(eventId: String, result: FlutterResult) {
    guard let event = eventStore.event(withIdentifier: eventId) else {
      result(true)
      return
    }
    do {
      try eventStore.remove(event, span: .thisEvent, commit: true)
      result(true)
    } catch {
      result(false)
    }
  }

  private func shareWallpaper(data: Data, result: @escaping FlutterResult) {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("moss-lockscreen-\(Int(Date().timeIntervalSince1970)).png")
    do {
      try data.write(to: url, options: .atomic)
      DispatchQueue.main.async {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let presenter = self.topViewController() else {
          result(FlutterError(code: "NO_PRESENTER", message: "Cannot open the system share sheet", details: nil))
          return
        }
        if let popover = controller.popoverPresentationController {
          popover.sourceView = presenter.view
          popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY, width: 1, height: 1)
        }
        presenter.present(controller, animated: true)
        result(["action": "shared", "location": url.path])
      }
    } catch {
      result(FlutterError(code: "WRITE_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}
