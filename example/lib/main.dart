import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_lens/native_lens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _nativeLensPlugin = NativeLens();
  PlatformSummary? _platformSummary;
  List<SystemFeature>? _systemFeatures;
  List<NativeSensor>? _sensors;
  DisplayInfo? _displayInfo;
  List<MediaCodecCapability>? _mediaCodecs;
  List<CameraCapability>? _cameraCapabilities;
  PowerState? _powerState;
  NetworkCapability? _networkCapability;
  NetworkSpeedSample? _networkSpeedSample;
  StreamSubscription<NetworkCapability>? _networkCapabilitySubscription;
  StreamSubscription<NetworkSpeedSample>? _networkSpeedSubscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    listenToNetworkCapability();
    listenToNetworkSpeed();
  }

  @override
  void dispose() {
    _networkCapabilitySubscription?.cancel();
    _networkSpeedSubscription?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    PlatformSummary? platformSummary;
    List<SystemFeature>? systemFeatures;
    List<NativeSensor>? sensors;
    DisplayInfo? displayInfo;
    List<MediaCodecCapability>? mediaCodecs;
    List<CameraCapability>? cameraCapabilities;
    PowerState? powerState;
    NetworkCapability? networkCapability;
    String? errorMessage;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformSummary = await _nativeLensPlugin.getPlatformSummary();
      systemFeatures = await _nativeLensPlugin.getSystemFeatures();
      sensors = await _nativeLensPlugin.getSensors();
      displayInfo = await _nativeLensPlugin.getDisplayInfo();
      mediaCodecs = await _nativeLensPlugin.getMediaCodecs();
      cameraCapabilities = await _nativeLensPlugin.getCameraCapabilities();
      powerState = await _nativeLensPlugin.getPowerState();
      networkCapability = await _nativeLensPlugin.getNetworkCapability();
    } on PlatformException {
      errorMessage = 'Failed to load NativeLens details.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformSummary = platformSummary;
      _systemFeatures = systemFeatures;
      _sensors = sensors;
      _displayInfo = displayInfo;
      _mediaCodecs = mediaCodecs;
      _cameraCapabilities = cameraCapabilities;
      _powerState = powerState;
      _networkCapability = networkCapability;
      _errorMessage = errorMessage;
    });
  }

  void listenToNetworkCapability() {
    _networkCapabilitySubscription = _nativeLensPlugin.networkCapabilityStream
        .listen(
          (NetworkCapability capability) {
            if (!mounted) return;

            setState(() {
              _networkCapability = capability;

              if (!capability.isConnected) {
                _networkSpeedSample = _zeroNetworkSpeedSample();
              }
            });
          },
          onError: (Object error) {
            // The one-shot network capability call still provides a fallback
            // if the stream is unavailable in a test or unsupported platform.
          },
        );
  }

  void listenToNetworkSpeed() {
    _networkSpeedSubscription = _nativeLensPlugin.networkSpeedStream.listen(
      (NetworkSpeedSample sample) {
        if (!mounted) return;

        setState(() {
          _networkSpeedSample = sample;
        });
      },
      onError: (Object error) {
        // The example can still show the one-shot capability sections if the
        // stream is unavailable in a test or unsupported platform environment.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('NativeLens Example')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final PlatformSummary? summary = _platformSummary;
    final List<SystemFeature>? features = _systemFeatures;
    final List<NativeSensor>? sensors = _sensors;
    final DisplayInfo? displayInfo = _displayInfo;
    final List<MediaCodecCapability>? mediaCodecs = _mediaCodecs;
    final List<CameraCapability>? cameraCapabilities = _cameraCapabilities;
    final PowerState? powerState = _powerState;
    final NetworkCapability? networkCapability = _networkCapability;
    final NetworkSpeedSample? networkSpeedSample = _networkSpeedSample;

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (summary == null ||
        features == null ||
        sensors == null ||
        displayInfo == null ||
        mediaCodecs == null ||
        cameraCapabilities == null ||
        powerState == null ||
        networkCapability == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final int encoderCount = mediaCodecs
        .where((MediaCodecCapability codec) => codec.isEncoder)
        .length;
    final int decoderCount = mediaCodecs.length - encoderCount;
    final bool isNetworkConnected = networkCapability.isConnected;
    final NetworkSpeedSample? visibleNetworkSpeedSample = isNetworkConnected
        ? networkSpeedSample
        : _zeroNetworkSpeedSample();

    return ListView(
      children: <Widget>[
        _SectionTitle(title: 'Platform Summary'),
        const SizedBox(height: 16),
        _SummaryRow(label: 'Manufacturer', value: summary.manufacturer),
        _SummaryRow(label: 'Brand', value: summary.brand),
        _SummaryRow(label: 'Model', value: summary.model),
        _SummaryRow(label: 'Device', value: summary.device),
        _SummaryRow(label: 'Product', value: summary.product),
        _SummaryRow(label: 'Android SDK', value: summary.androidSdk.toString()),
        _SummaryRow(label: 'Android Release', value: summary.androidRelease),
        const SizedBox(height: 28),
        _SectionTitle(title: 'Power'),
        const SizedBox(height: 16),
        _SummaryRow(label: 'Battery', value: '${powerState.batteryLevel}%'),
        _SummaryRow(
          label: 'Charging',
          value: powerState.isCharging ? 'Yes' : 'No',
        ),
        _SummaryRow(label: 'Source', value: powerState.chargingSource),
        _SummaryRow(label: 'Health', value: powerState.batteryHealth),
        _SummaryRow(label: 'Status', value: powerState.batteryStatus),
        _SummaryRow(
          label: 'Temperature',
          value: '${powerState.batteryTemperatureCelsius} C',
        ),
        _SummaryRow(
          label: 'Power saver',
          value: powerState.isPowerSaveMode ? 'On' : 'Off',
        ),
        _SummaryRow(
          label: 'Optimization',
          value: powerState.isIgnoringBatteryOptimizations
              ? 'Ignoring'
              : 'Active',
        ),
        const SizedBox(height: 28),
        _SectionTitle(title: 'Network'),
        const SizedBox(height: 16),
        _SummaryRow(
          label: 'Status',
          value: isNetworkConnected ? 'Connected' : 'Disconnected',
        ),
        _SummaryRow(label: 'Transport', value: networkCapability.transportType),
        _SummaryRow(
          label: 'Validated',
          value: networkCapability.isValidated ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Metered',
          value: networkCapability.isMetered ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'VPN',
          value: networkCapability.hasVpn ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Wi-Fi',
          value: networkCapability.hasWifi ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Cellular',
          value: networkCapability.hasCellular ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Ethernet',
          value: networkCapability.hasEthernet ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Bluetooth',
          value: networkCapability.hasBluetooth ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Low latency',
          value: networkCapability.hasLowLatency ? 'Yes' : 'No',
        ),
        _SummaryRow(
          label: 'Bandwidth',
          value: networkCapability.hasHighBandwidth ? 'High' : 'Normal',
        ),
        const SizedBox(height: 28),
        _SectionTitle(title: 'App Traffic Speed'),
        const SizedBox(height: 16),
        _SummaryRow(
          label: 'Download',
          value: _formatSpeed(visibleNetworkSpeedSample?.rxBytesPerSecond),
        ),
        _SummaryRow(
          label: 'Upload',
          value: _formatSpeed(visibleNetworkSpeedSample?.txBytesPerSecond),
        ),
        _SummaryRow(
          label: 'Received',
          value: _formatBytes(visibleNetworkSpeedSample?.totalRxBytes),
        ),
        _SummaryRow(
          label: 'Sent',
          value: _formatBytes(visibleNetworkSpeedSample?.totalTxBytes),
        ),
        _SummaryRow(
          label: 'Supported',
          value: visibleNetworkSpeedSample == null
              ? 'Waiting'
              : visibleNetworkSpeedSample.isSupported
              ? 'Yes'
              : 'No',
        ),
        const SizedBox(height: 28),
        _SectionTitle(title: 'Display'),
        const SizedBox(height: 16),
        _SummaryRow(
          label: 'Resolution',
          value: '${displayInfo.widthPixels} x ${displayInfo.heightPixels}',
        ),
        _SummaryRow(label: 'Density', value: displayInfo.density.toString()),
        _SummaryRow(
          label: 'Density DPI',
          value: displayInfo.densityDpi.toString(),
        ),
        _SummaryRow(
          label: 'Refresh Rate',
          value: '${displayInfo.refreshRate} Hz',
        ),
        _SummaryRow(
          label: 'Supported',
          value: _formatRefreshRates(displayInfo.supportedRefreshRates),
        ),
        _SummaryRow(
          label: 'HDR',
          value: displayInfo.isHdrSupported ? 'Supported' : 'Not supported',
        ),
        _SummaryRow(
          label: 'HDR Types',
          value: _formatTextList(displayInfo.supportedHdrTypes),
        ),
        const SizedBox(height: 28),
        _SectionTitle(title: 'Media Codecs'),
        const SizedBox(height: 8),
        Text('Total codecs: ${mediaCodecs.length}'),
        Text('Encoders: $encoderCount'),
        Text('Decoders: $decoderCount'),
        const SizedBox(height: 12),
        for (final MediaCodecCapability codec in mediaCodecs)
          _MediaCodecRow(codec: codec),
        const SizedBox(height: 28),
        _SectionTitle(title: 'Cameras'),
        const SizedBox(height: 8),
        Text('Total cameras: ${cameraCapabilities.length}'),
        const SizedBox(height: 12),
        for (final CameraCapability camera in cameraCapabilities)
          _CameraCapabilityRow(camera: camera),
        const SizedBox(height: 28),
        _SectionTitle(title: 'System Features'),
        const SizedBox(height: 8),
        Text('Total features: ${features.length}'),
        const SizedBox(height: 12),
        for (final SystemFeature feature in features)
          _FeatureRow(feature: feature),
        const SizedBox(height: 28),
        _SectionTitle(title: 'Sensors'),
        const SizedBox(height: 8),
        Text('Total sensors: ${sensors.length}'),
        const SizedBox(height: 12),
        for (final NativeSensor sensor in sensors) _SensorRow(sensor: sensor),
      ],
    );
  }

  String _formatRefreshRates(List<double> refreshRates) {
    if (refreshRates.isEmpty) {
      return 'Unknown';
    }

    return refreshRates.map((double rate) => '$rate Hz').join(', ');
  }

  String _formatTextList(List<String> values) {
    if (values.isEmpty) {
      return 'None';
    }

    return values.join(', ');
  }

  NetworkSpeedSample _zeroNetworkSpeedSample() {
    return NetworkSpeedSample(
      timestampMillis: DateTime.now().millisecondsSinceEpoch,
      rxBytesPerSecond: 0,
      txBytesPerSecond: 0,
      rxKbps: 0,
      txKbps: 0,
      totalRxBytes: 0,
      totalTxBytes: 0,
      isSupported: true,
    );
  }

  String _formatSpeed(int? bytesPerSecond) {
    if (bytesPerSecond == null) {
      return 'Waiting';
    }

    final double kiloBytesPerSecond = bytesPerSecond / 1024;
    return '${kiloBytesPerSecond.toStringAsFixed(2)} KB/s';
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) {
      return 'Waiting';
    }

    return '$bytes bytes';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineSmall);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final SystemFeature feature;

  @override
  Widget build(BuildContext context) {
    final String versionText = feature.version == null
        ? ''
        : '  Version ${feature.version}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text('${feature.name}$versionText'),
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.sensor});

  final NativeSensor sensor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sensor.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text('Type: ${sensor.typeName}'),
          Text('Vendor: ${sensor.vendor}'),
          Text('Power: ${sensor.power} mA'),
          Text('Resolution: ${sensor.resolution}'),
        ],
      ),
    );
  }
}

class _MediaCodecRow extends StatelessWidget {
  const _MediaCodecRow({required this.codec});

  final MediaCodecCapability codec;

  @override
  Widget build(BuildContext context) {
    final String codecKind = codec.isEncoder ? 'Encoder' : 'Decoder';
    final String supportedTypes = codec.supportedTypes.isEmpty
        ? 'None'
        : codec.supportedTypes.join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(codec.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(codecKind),
          Text('Types: $supportedTypes'),
        ],
      ),
    );
  }
}

class _CameraCapabilityRow extends StatelessWidget {
  const _CameraCapabilityRow({required this.camera});

  final CameraCapability camera;

  @override
  Widget build(BuildContext context) {
    final String fpsRanges = camera.supportedFpsRanges.isEmpty
        ? 'Unknown'
        : camera.supportedFpsRanges.join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Camera ${camera.cameraId}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text('Lens: ${camera.lensFacing}'),
          Text('Hardware: ${camera.hardwareLevel}'),
          Text('Flash: ${camera.hasFlash ? 'Yes' : 'No'}'),
          Text('RAW: ${camera.supportsRawCapture ? 'Yes' : 'No'}'),
          Text('Manual sensor: ${camera.supportsManualSensor ? 'Yes' : 'No'}'),
          Text(
            'Manual post: '
            '${camera.supportsManualPostProcessing ? 'Yes' : 'No'}',
          ),
          Text('Autofocus: ${camera.supportsAutoFocus ? 'Yes' : 'No'}'),
          Text('OIS: ${camera.supportsOpticalStabilization ? 'Yes' : 'No'}'),
          Text('FPS: $fpsRanges'),
        ],
      ),
    );
  }
}
