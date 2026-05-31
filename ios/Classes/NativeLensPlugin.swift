import Flutter
import UIKit
import Network

private final class EventChannelHandler: NSObject, FlutterStreamHandler {
  private let onListen: (Any?, @escaping FlutterEventSink) -> Void
  private let onCancel: (Any?) -> Void

  init(
    onListen: @escaping (Any?, @escaping FlutterEventSink) -> Void,
    onCancel: @escaping (Any?) -> Void
  ) {
    self.onListen = onListen
    self.onCancel = onCancel
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onListen(arguments, events)
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onCancel(arguments)
    return nil
  }
}

private final class ThemeModeObserverView: UIView {
  var onThemeModeChanged: ((UITraitCollection) -> Void)?

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if previousTraitCollection?.userInterfaceStyle == traitCollection.userInterfaceStyle {
      return
    }

    onThemeModeChanged?(traitCollection)
  }
}

public class NativeLensPlugin: NSObject, FlutterPlugin {
  private var networkMonitor: NWPathMonitor?
  private var networkCapabilitySink: FlutterEventSink?
  private var deviceOrientationSink: FlutterEventSink?
  private var orientationObserver: NSObjectProtocol?
  private var networkSpeedSink: FlutterEventSink?
  private var powerStateSink: FlutterEventSink?
  private var themeModeSink: FlutterEventSink?
  private var themeModeObserverView: ThemeModeObserverView?
  private var lastThemeMode: String?
  private var batteryLevelObserver: NSObjectProtocol?
  private var batteryStateObserver: NSObjectProtocol?
  private var lowPowerModeObserver: NSObjectProtocol?
  private var wasBatteryMonitoringEnabled = false
  private let monitorQueue = DispatchQueue(label: "native_lens.network_monitor")

  deinit {
    stopThemeModeStream()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "native_lens", binaryMessenger: registrar.messenger())
    let instance = NativeLensPlugin()

    registrar.addMethodCallDelegate(instance, channel: channel)

    let networkCapabilityChannel = FlutterEventChannel(
      name: "native_lens/network_capability",
      binaryMessenger: registrar.messenger()
    )
    networkCapabilityChannel.setStreamHandler(
      EventChannelHandler(
        onListen: { _, events in instance.startNetworkCapabilityStream(events) },
        onCancel: { _ in instance.stopNetworkCapabilityStream() }
      )
    )

    let deviceOrientationChannel = FlutterEventChannel(
      name: "native_lens/device_orientation",
      binaryMessenger: registrar.messenger()
    )
    deviceOrientationChannel.setStreamHandler(
      EventChannelHandler(
        onListen: { _, events in instance.startDeviceOrientationStream(events) },
        onCancel: { _ in instance.stopDeviceOrientationStream() }
      )
    )

    let networkSpeedChannel = FlutterEventChannel(
      name: "native_lens/network_speed",
      binaryMessenger: registrar.messenger()
    )
    networkSpeedChannel.setStreamHandler(
      EventChannelHandler(
        onListen: { _, events in instance.startNetworkSpeedStream(events) },
        onCancel: { _ in instance.stopNetworkSpeedStream() }
      )
    )

    let powerStateChannel = FlutterEventChannel(
      name: "native_lens/power_state",
      binaryMessenger: registrar.messenger()
    )
    powerStateChannel.setStreamHandler(
      EventChannelHandler(
        onListen: { _, events in instance.startPowerStateStream(events) },
        onCancel: { _ in instance.stopPowerStateStream() }
      )
    )

    let themeModeChannel = FlutterEventChannel(
      name: "native_lens/theme_mode",
      binaryMessenger: registrar.messenger()
    )
    themeModeChannel.setStreamHandler(
      EventChannelHandler(
        onListen: { _, events in instance.startThemeModeStream(events) },
        onCancel: { _ in instance.stopThemeModeStream() }
      )
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformSummary":
      result(getPlatformSummary())
    case "getSystemFeatures":
      result(getSystemFeatures())
    case "getSensors":
      result(getSensors())
    case "getDisplayInfo":
      result(getDisplayInfo())
    case "getMediaCodecs":
      result(getMediaCodecs())
    case "getCameraCapabilities":
      result(getCameraCapabilities())
    case "getPowerState":
      result(getPowerState())
    case "getThemeMode":
      result(getThemeMode())
    case "getNetworkCapability":
      result(getNetworkCapability())
    case "getDeviceOrientation":
      result(getDeviceOrientation())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getPlatformSummary() -> [String: Any] {
    let device = UIDevice.current
    return [
      "manufacturer": "Apple",
      "brand": device.systemName,
      "model": device.model,
      "device": device.localizedModel,
      "product": device.name,
      "androidSdk": 0,
      "androidRelease": device.systemVersion,
    ]
  }

  private func getSystemFeatures() -> [[String: Any?]] {
    return []
  }

  private func getSensors() -> [[String: Any?]] {
    return []
  }

  private func getDisplayInfo() -> [String: Any] {
    let screen = UIScreen.main
    let bounds = screen.nativeBounds
    let refreshRate = Double(screen.maximumFramesPerSecond)
    let density = screen.scale

    return [
      "widthPixels": Int(bounds.width),
      "heightPixels": Int(bounds.height),
      "density": density,
      "densityDpi": Int(160.0 * density),
      "refreshRate": refreshRate,
      "supportedRefreshRates": [refreshRate],
      "isHdrSupported": false,
      "supportedHdrTypes": [String](),
    ]
  }

  private func getMediaCodecs() -> [[String: Any?]] {
    return []
  }

  private func getCameraCapabilities() -> [[String: Any?]] {
    return []
  }

  private func getPowerState() -> [String: Any] {
    let device = UIDevice.current
    let wasMonitoring = device.isBatteryMonitoringEnabled
    device.isBatteryMonitoringEnabled = true

    let payload = createPowerState()

    if !wasMonitoring {
      device.isBatteryMonitoringEnabled = false
    }

    return payload
  }

  private func createPowerState() -> [String: Any] {
    let device = UIDevice.current
    let level = Int((device.batteryLevel >= 0 ? device.batteryLevel : 0.0) * 100.0)
    let state = device.batteryState
    let status = batteryStatusName(from: state)
    let isCharging = state == .charging || state == .full

    return [
      "batteryLevel": level,
      "isCharging": isCharging,
      "chargingSource": status,
      "batteryHealth": "Unknown",
      "batteryStatus": status,
      "batteryTemperatureCelsius": 0.0,
      "isPowerSaveMode": ProcessInfo.processInfo.isLowPowerModeEnabled,
      "isIgnoringBatteryOptimizations": false,
    ]
  }

  private func getNetworkCapability() -> [String: Any] {
    if #available(iOS 12.0, *) {
      let monitor = NWPathMonitor()
      monitor.start(queue: monitorQueue)
      let path = monitor.currentPath
      monitor.cancel()
      return createNetworkCapability(from: path)
    }

    return createUnsupportedNetworkCapability()
  }

  private func createNetworkCapability(from path: NWPath) -> [String: Any] {
    let transportTypes = transportTypes(from: path)
    let transportTypeString = transportTypes.isEmpty ? "Unknown" : transportTypes.joined(separator: ", ")

    return [
      "isConnected": path.status == .satisfied,
      "transportType": transportTypeString,
      "isValidated": path.status == .satisfied,
      "isMetered": path.isExpensive,
      "hasVpn": false,
      "hasWifi": path.usesInterfaceType(.wifi),
      "hasCellular": path.usesInterfaceType(.cellular),
      "hasEthernet": path.usesInterfaceType(.wiredEthernet),
      "hasBluetooth": false,
      "hasLowLatency": false,
      "hasHighBandwidth": false,
    ]
  }

  private func transportTypes(from path: NWPath) -> [String] {
    var transports = [String]()

    if path.usesInterfaceType(.wifi) {
      transports.append("Wi-Fi")
    }
    if path.usesInterfaceType(.cellular) {
      transports.append("Cellular")
    }
    if path.usesInterfaceType(.wiredEthernet) {
      transports.append("Ethernet")
    }
    if path.usesInterfaceType(.loopback) {
      transports.append("Loopback")
    }
    if path.usesInterfaceType(.other) {
      transports.append("Other")
    }

    return transports
  }

  private func createUnsupportedNetworkCapability() -> [String: Any] {
    return [
      "isConnected": false,
      "transportType": "Unknown",
      "isValidated": false,
      "isMetered": false,
      "hasVpn": false,
      "hasWifi": false,
      "hasCellular": false,
      "hasEthernet": false,
      "hasBluetooth": false,
      "hasLowLatency": false,
      "hasHighBandwidth": false,
    ]
  }

  private func getDeviceOrientation() -> [String: Any] {
    let orientation = UIDevice.current.orientation
    return createDeviceOrientation(from: orientation, source: "display")
  }

  private func startNetworkCapabilityStream(_ events: @escaping FlutterEventSink) {
    stopNetworkCapabilityStream()
    networkCapabilitySink = events

    if #available(iOS 12.0, *) {
      let monitor = NWPathMonitor()
      networkMonitor = monitor
      monitor.pathUpdateHandler = { [weak self] _ in
        self?.emitNetworkCapabilityUpdate()
      }
      monitor.start(queue: monitorQueue)
      emitNetworkCapabilityUpdate()
    } else {
      events(createUnsupportedNetworkCapability())
    }
  }

  private func stopNetworkCapabilityStream() {
    networkMonitor?.cancel()
    networkMonitor = nil
    networkCapabilitySink = nil
  }

  private func emitNetworkCapabilityUpdate() {
    guard let sink = networkCapabilitySink else {
      return
    }

    if #available(iOS 12.0, *) {
      let path = networkMonitor?.currentPath
      let payload = path.map(createNetworkCapability) ?? createUnsupportedNetworkCapability()
      sink(payload)
    } else {
      sink(createUnsupportedNetworkCapability())
    }
  }

  private func startDeviceOrientationStream(_ events: @escaping FlutterEventSink) {
    stopDeviceOrientationStream()
    deviceOrientationSink = events
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()

    orientationObserver = NotificationCenter.default.addObserver(
      forName: UIDevice.orientationDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self else {
        return
      }
      self.deviceOrientationSink?(self.createDeviceOrientation(from: UIDevice.current.orientation, source: "orientation"))
    }

    events(createDeviceOrientation(from: UIDevice.current.orientation, source: "orientation"))
  }

  private func stopDeviceOrientationStream() {
    if let observer = orientationObserver {
      NotificationCenter.default.removeObserver(observer)
      orientationObserver = nil
    }
    deviceOrientationSink = nil
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
  }

  private func startNetworkSpeedStream(_ events: @escaping FlutterEventSink) {
    stopNetworkSpeedStream()
    networkSpeedSink = events
    events(createUnsupportedNetworkSpeedSample())
  }

  private func stopNetworkSpeedStream() {
    networkSpeedSink = nil
  }

  private func startPowerStateStream(_ events: @escaping FlutterEventSink) {
    stopPowerStateStream()

    let device = UIDevice.current
    wasBatteryMonitoringEnabled = device.isBatteryMonitoringEnabled
    device.isBatteryMonitoringEnabled = true
    powerStateSink = events

    batteryLevelObserver = NotificationCenter.default.addObserver(
      forName: UIDevice.batteryLevelDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.emitPowerStateUpdate()
    }

    batteryStateObserver = NotificationCenter.default.addObserver(
      forName: UIDevice.batteryStateDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.emitPowerStateUpdate()
    }

    lowPowerModeObserver = NotificationCenter.default.addObserver(
      forName: .NSProcessInfoPowerStateDidChange,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.emitPowerStateUpdate()
    }

    emitPowerStateUpdate()
  }

  private func stopPowerStateStream() {
    if let observer = batteryLevelObserver {
      NotificationCenter.default.removeObserver(observer)
      batteryLevelObserver = nil
    }
    if let observer = batteryStateObserver {
      NotificationCenter.default.removeObserver(observer)
      batteryStateObserver = nil
    }
    if let observer = lowPowerModeObserver {
      NotificationCenter.default.removeObserver(observer)
      lowPowerModeObserver = nil
    }

    powerStateSink = nil

    if !wasBatteryMonitoringEnabled {
      UIDevice.current.isBatteryMonitoringEnabled = false
    }
  }

  private func emitPowerStateUpdate() {
    powerStateSink?(createPowerState())
  }

  private func getThemeMode() -> String {
    guard let traitCollection = activeTraitCollection() else {
      return "unknown"
    }

    return themeMode(from: traitCollection.userInterfaceStyle)
  }

  private func activeTraitCollection() -> UITraitCollection? {
    return activeRootView()?.traitCollection
  }

  private func activeRootView() -> UIView? {
    let activeWindow: UIWindow?

    if #available(iOS 13.0, *) {
      activeWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    } else {
      activeWindow = UIApplication.shared.keyWindow
    }

    return activeWindow?.rootViewController?.view ?? activeWindow
  }

  private func themeMode(from style: UIUserInterfaceStyle) -> String {
    switch style {
    case .dark:
      return "dark"
    case .light:
      return "light"
    default:
      return "unknown"
    }
  }

  private func startThemeModeStream(_ events: @escaping FlutterEventSink) {
    stopThemeModeStream()
    themeModeSink = events
    lastThemeMode = getThemeMode()
    events(lastThemeMode ?? "unknown")

    guard let rootView = activeRootView() else {
      return
    }

    let observerView = ThemeModeObserverView(frame: .zero)
    observerView.isHidden = true
    observerView.isUserInteractionEnabled = false
    observerView.onThemeModeChanged = { [weak self] traitCollection in
      self?.emitThemeModeIfChanged(
        self?.themeMode(from: traitCollection.userInterfaceStyle) ?? "unknown"
      )
    }

    rootView.addSubview(observerView)
    themeModeObserverView = observerView
  }

  private func stopThemeModeStream() {
    themeModeObserverView?.removeFromSuperview()
    themeModeObserverView?.onThemeModeChanged = nil
    themeModeObserverView = nil
    themeModeSink = nil
    lastThemeMode = nil
  }

  private func emitThemeModeIfChanged(_ themeMode: String) {
    if themeMode == lastThemeMode {
      return
    }

    lastThemeMode = themeMode
    themeModeSink?(themeMode)
  }

  private func createDeviceOrientation(
    from orientation: UIDeviceOrientation,
    source: String
  ) -> [String: Any] {
    let mapped = mapOrientation(orientation)
    return [
      "orientationName": mapped.name,
      "rotationDegrees": mapped.degrees,
      "isPortrait": mapped.isPortrait,
      "isLandscape": mapped.isLandscape,
      "source": source,
      "timestampMillis": Int(Date().timeIntervalSince1970 * 1000),
    ]
  }

  private func mapOrientation(_ orientation: UIDeviceOrientation) -> (name: String, degrees: Int, isPortrait: Bool, isLandscape: Bool) {
    switch orientation {
    case .portrait:
      return ("portraitUp", 0, true, false)
    case .portraitUpsideDown:
      return ("portraitDown", 180, true, false)
    case .landscapeLeft:
      return ("landscapeRight", 90, false, true)
    case .landscapeRight:
      return ("landscapeLeft", 270, false, true)
    case .faceUp:
      return ("faceUp", -1, false, false)
    case .faceDown:
      return ("faceDown", -1, false, false)
    default:
      return ("unknown", -1, false, false)
    }
  }

  private func batteryStatusName(from state: UIDevice.BatteryState) -> String {
    switch state {
    case .charging:
      return "Charging"
    case .full:
      return "Full"
    case .unplugged:
      return "Not charging"
    default:
      return "Unknown"
    }
  }

  private func createUnsupportedNetworkSpeedSample() -> [String: Any] {
    return [
      "timestampMillis": Int(Date().timeIntervalSince1970 * 1000),
      "rxBytesPerSecond": 0,
      "txBytesPerSecond": 0,
      "rxKbps": 0.0,
      "txKbps": 0.0,
      "totalRxBytes": 0,
      "totalTxBytes": 0,
      "isSupported": false,
    ]
  }
}
