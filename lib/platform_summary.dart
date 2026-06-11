/// Basic information about the native platform running the app.
class PlatformSummary {
  /// Creates a platform summary with native platform details.
  const PlatformSummary({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.product,
    required this.androidSdk,
    required this.androidRelease,
    this.platformName,
    this.osName,
    this.osVersion,
    this.localizedModel,
    this.appEnvironment,
    this.isPhysicalDevice,
    this.isSimulator,
    this.physicalMemoryBytes,
    this.processorCount,
    this.activeProcessorCount,
    this.thermalState,
    this.isIosNative = false,
  });

  /// The device manufacturer, such as Google, Samsung, Xiaomi, or Apple.
  final String manufacturer;

  /// The consumer-facing device brand reported by Android.
  final String brand;

  /// The device model reported by Android.
  final String model;

  /// The device code name reported by Android.
  final String device;

  /// The product name reported by Android.
  final String product;

  /// The Android SDK version number.
  final int androidSdk;

  /// The Android release version, such as 14 or 15.
  final String androidRelease;

  /// Lowercase platform name, such as `android` or `ios`, when provided.
  final String? platformName;

  /// Operating system name reported by the native platform.
  final String? osName;

  /// Operating system version reported by the native platform.
  final String? osVersion;

  /// Localized device model reported by the native platform, when available.
  final String? localizedModel;

  /// Safe app/device runtime environment hint, such as `device` or `simulator`.
  final String? appEnvironment;

  /// Whether the app is running on physical hardware, when safely known.
  final bool? isPhysicalDevice;

  /// Whether the app is running in a simulator, when safely known.
  final bool? isSimulator;

  /// Physical memory in bytes, when safely available.
  final int? physicalMemoryBytes;

  /// Total processor count, when safely available.
  final int? processorCount;

  /// Active processor count, when safely available.
  final int? activeProcessorCount;

  /// Current thermal state, when safely available.
  final String? thermalState;

  /// Whether this summary was produced by the iOS native implementation.
  final bool isIosNative;

  /// Creates a [PlatformSummary] from a map returned by the native platform.
  factory PlatformSummary.fromMap(Map<Object?, Object?> map) {
    final int androidSdk = _readInt(map, 'androidSdk');
    final String androidRelease = _readString(map, 'androidRelease');

    return PlatformSummary(
      manufacturer: _readString(map, 'manufacturer'),
      brand: _readString(map, 'brand'),
      model: _readString(map, 'model'),
      device: _readString(map, 'device'),
      product: _readString(map, 'product'),
      androidSdk: androidSdk,
      androidRelease: androidRelease,
      platformName:
          _readOptionalString(map, 'platformName') ??
          (androidSdk > 0 ? 'android' : null),
      osName:
          _readOptionalString(map, 'osName') ??
          (androidSdk > 0 ? 'Android' : null),
      osVersion: _readOptionalString(map, 'osVersion') ?? androidRelease,
      localizedModel: _readOptionalString(map, 'localizedModel'),
      appEnvironment: _readOptionalString(map, 'appEnvironment'),
      isPhysicalDevice: _readOptionalBool(map, 'isPhysicalDevice'),
      isSimulator: _readOptionalBool(map, 'isSimulator'),
      physicalMemoryBytes: _readOptionalInt(map, 'physicalMemoryBytes'),
      processorCount: _readOptionalInt(map, 'processorCount'),
      activeProcessorCount: _readOptionalInt(map, 'activeProcessorCount'),
      thermalState: _readOptionalString(map, 'thermalState'),
      isIosNative: _readBool(map, 'isIosNative'),
    );
  }

  /// Converts this summary to a map using the native field names.
  Map<String, Object> toMap() {
    final Map<String, Object> map = <String, Object>{
      'manufacturer': manufacturer,
      'brand': brand,
      'model': model,
      'device': device,
      'product': product,
      'androidSdk': androidSdk,
      'androidRelease': androidRelease,
      'isIosNative': isIosNative,
    };

    void addOptional(String key, Object? value) {
      if (value != null) {
        map[key] = value;
      }
    }

    addOptional('platformName', platformName);
    addOptional('osName', osName);
    addOptional('osVersion', osVersion);
    addOptional('localizedModel', localizedModel);
    addOptional('appEnvironment', appEnvironment);
    addOptional('isPhysicalDevice', isPhysicalDevice);
    addOptional('isSimulator', isSimulator);
    addOptional('physicalMemoryBytes', physicalMemoryBytes);
    addOptional('processorCount', processorCount);
    addOptional('activeProcessorCount', activeProcessorCount);
    addOptional('thermalState', thermalState);

    return map;
  }

  /// Returns a readable string containing all summary fields.
  @override
  String toString() {
    return 'PlatformSummary('
        'manufacturer: $manufacturer, '
        'brand: $brand, '
        'model: $model, '
        'device: $device, '
        'product: $product, '
        'androidSdk: $androidSdk, '
        'androidRelease: $androidRelease, '
        'platformName: $platformName, '
        'osName: $osName, '
        'osVersion: $osVersion, '
        'localizedModel: $localizedModel, '
        'appEnvironment: $appEnvironment, '
        'isPhysicalDevice: $isPhysicalDevice, '
        'isSimulator: $isSimulator, '
        'physicalMemoryBytes: $physicalMemoryBytes, '
        'processorCount: $processorCount, '
        'activeProcessorCount: $activeProcessorCount, '
        'thermalState: $thermalState, '
        'isIosNative: $isIosNative'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static String? _readOptionalString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  static bool _readBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return false;
  }

  static bool? _readOptionalBool(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is bool) {
      return value;
    }
    return null;
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }

  static int? _readOptionalInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return null;
  }
}
