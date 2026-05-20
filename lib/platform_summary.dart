/// Basic information about the Android device running the app.
class PlatformSummary {
  /// Creates a platform summary with Android build details.
  const PlatformSummary({
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.device,
    required this.product,
    required this.androidSdk,
    required this.androidRelease,
  });

  /// The device manufacturer, such as Google, Samsung, or Xiaomi.
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

  /// Creates a [PlatformSummary] from a map returned by the native platform.
  factory PlatformSummary.fromMap(Map<Object?, Object?> map) {
    return PlatformSummary(
      manufacturer: _readString(map, 'manufacturer'),
      brand: _readString(map, 'brand'),
      model: _readString(map, 'model'),
      device: _readString(map, 'device'),
      product: _readString(map, 'product'),
      androidSdk: _readInt(map, 'androidSdk'),
      androidRelease: _readString(map, 'androidRelease'),
    );
  }

  /// Converts this summary to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'manufacturer': manufacturer,
      'brand': brand,
      'model': model,
      'device': device,
      'product': product,
      'androidSdk': androidSdk,
      'androidRelease': androidRelease,
    };
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
        'androidRelease: $androidRelease'
        ')';
  }

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static int _readInt(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is int) {
      return value;
    }
    return 0;
  }
}
