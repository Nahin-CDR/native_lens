/// Native network capability information for the active network.
class NetworkCapability {
  /// Creates a network capability description.
  const NetworkCapability({
    required this.isConnected,
    required this.transportType,
    required this.isValidated,
    required this.isMetered,
    required this.hasVpn,
    required this.hasWifi,
    required this.hasCellular,
    required this.hasEthernet,
    required this.hasBluetooth,
    required this.hasLowLatency,
    required this.hasHighBandwidth,
    this.interfaceTypes,
    this.isConstrained,
    this.isIosNative = false,
  });

  /// Whether the native platform reports an active connected network.
  final bool isConnected;

  /// A readable active transport type summary.
  final String transportType;

  /// Whether the native platform has validated internet access on the active network.
  final bool isValidated;

  /// Whether the active network is metered.
  final bool isMetered;

  /// Whether the active network uses a VPN transport.
  final bool hasVpn;

  /// Whether the active network uses a Wi-Fi transport.
  final bool hasWifi;

  /// Whether the active network uses a cellular transport.
  final bool hasCellular;

  /// Whether the active network uses an ethernet transport.
  final bool hasEthernet;

  /// Whether the active network uses a Bluetooth transport.
  final bool hasBluetooth;

  /// Whether the active network reports a low-latency capability.
  final bool hasLowLatency;

  /// Whether the active network reports a high-bandwidth capability.
  final bool hasHighBandwidth;

  /// Native interface type names when available.
  final List<String>? interfaceTypes;

  /// Whether the current network is constrained, such as iOS Low Data Mode.
  final bool? isConstrained;

  /// Whether this payload came from the iOS native implementation.
  final bool isIosNative;

  /// Creates a [NetworkCapability] from a map returned by the native platform.
  factory NetworkCapability.fromMap(Map<Object?, Object?> map) {
    return NetworkCapability(
      isConnected: _readBool(map, 'isConnected'),
      transportType: _readString(map, 'transportType'),
      isValidated: _readBool(map, 'isValidated'),
      isMetered: _readBool(map, 'isMetered'),
      hasVpn: _readBool(map, 'hasVpn'),
      hasWifi: _readBool(map, 'hasWifi'),
      hasCellular: _readBool(map, 'hasCellular'),
      hasEthernet: _readBool(map, 'hasEthernet'),
      hasBluetooth: _readBool(map, 'hasBluetooth'),
      hasLowLatency: _readBool(map, 'hasLowLatency'),
      hasHighBandwidth: _readBool(map, 'hasHighBandwidth'),
      interfaceTypes: _readOptionalStringList(map, 'interfaceTypes'),
      isConstrained: _readOptionalBool(map, 'isConstrained'),
      isIosNative: _readBool(map, 'isIosNative'),
    );
  }

  /// Converts this network capability to a map using the native field names.
  Map<String, Object> toMap() {
    return <String, Object>{
      'isConnected': isConnected,
      'transportType': transportType,
      'isValidated': isValidated,
      'isMetered': isMetered,
      'hasVpn': hasVpn,
      'hasWifi': hasWifi,
      'hasCellular': hasCellular,
      'hasEthernet': hasEthernet,
      'hasBluetooth': hasBluetooth,
      'hasLowLatency': hasLowLatency,
      'hasHighBandwidth': hasHighBandwidth,
      'isIosNative': isIosNative,
      'interfaceTypes': ?interfaceTypes,
      'isConstrained': ?isConstrained,
    };
  }

  /// Returns a readable string containing all network fields.
  @override
  String toString() {
    return 'NetworkCapability('
        'isConnected: $isConnected, '
        'transportType: $transportType, '
        'isValidated: $isValidated, '
        'isMetered: $isMetered, '
        'hasVpn: $hasVpn, '
        'hasWifi: $hasWifi, '
        'hasCellular: $hasCellular, '
        'hasEthernet: $hasEthernet, '
        'hasBluetooth: $hasBluetooth, '
        'hasLowLatency: $hasLowLatency, '
        'hasHighBandwidth: $hasHighBandwidth, '
        'interfaceTypes: $interfaceTypes, '
        'isConstrained: $isConstrained, '
        'isIosNative: $isIosNative'
        ')';
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

  static String _readString(Map<Object?, Object?> map, String key) {
    final Object? value = map[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'Unknown';
  }

  static List<String>? _readOptionalStringList(
    Map<Object?, Object?> map,
    String key,
  ) {
    final Object? value = map[key];
    if (value is Iterable<Object?>) {
      return value
          .whereType<String>()
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return null;
  }
}
