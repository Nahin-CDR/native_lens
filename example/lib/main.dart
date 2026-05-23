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
  CompatibilitySummary? _compatibilitySummary;
  DeviceOrientationInfo? _deviceOrientation;
  StreamSubscription<NetworkCapability>? _networkCapabilitySubscription;
  StreamSubscription<NetworkSpeedSample>? _networkSpeedSubscription;
  StreamSubscription<DeviceOrientationInfo>? _deviceOrientationSubscription;
  bool _isGeneratingReport = false;
  bool _isAnalyzingCompatibility = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    listenToNetworkCapability();
    listenToNetworkSpeed();
    listenToDeviceOrientation();
  }

  @override
  void dispose() {
    _networkCapabilitySubscription?.cancel();
    _networkSpeedSubscription?.cancel();
    _deviceOrientationSubscription?.cancel();
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
      _deviceOrientation = await _nativeLensPlugin.getDeviceOrientation();
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

  void listenToDeviceOrientation() {
    _deviceOrientationSubscription =
        _nativeLensPlugin.deviceOrientationStream.listen(
      (DeviceOrientationInfo orientation) {
        if (!mounted) return;

        setState(() {
          _deviceOrientation = orientation;
        });
      },
      onError: (Object error) {
        // Orientation updates are optional and may not be supported on all devices.
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

  Future<void> generateFullReport() async {
    setState(() {
      _isGeneratingReport = true;
      _errorMessage = null;
    });

    
    String? errorMessage;

    try {
      await _nativeLensPlugin.generateReport();
    } on PlatformException {
      errorMessage = 'Failed to generate NativeLens report.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    }

    if (!mounted) return;

    setState(() {
      _isGeneratingReport = false;
      _errorMessage = errorMessage;
    });
  }

  Future<void> analyzeCompatibility() async {
    setState(() {
      _isAnalyzingCompatibility = true;
      _errorMessage = null;
    });

    CompatibilitySummary? summary;
    String? errorMessage;

    try {
      summary = await _nativeLensPlugin.analyzeCompatibility();
    } on PlatformException {
      errorMessage = 'Failed to analyze compatibility.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    }

    if (!mounted) return;

    setState(() {
      _compatibilitySummary = summary;
      _isAnalyzingCompatibility = false;
      _errorMessage = errorMessage;
    });
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
    final DeviceOrientationInfo? deviceOrientation = _deviceOrientation;
    final NetworkSpeedSample? networkSpeedSample = _networkSpeedSample;
    final CompatibilitySummary? compatibilitySummary = _compatibilitySummary;

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

    
    final bool isNetworkConnected = networkCapability.isConnected;
    final NetworkSpeedSample? visibleNetworkSpeedSample = isNetworkConnected
        ? networkSpeedSample
        : _zeroNetworkSpeedSample();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('NativeLens Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 6),
                        Text('${summary.manufacturer} ${summary.model}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isGeneratingReport ? null : generateFullReport,
                    child: Text(_isGeneratingReport
                        ? 'Generating...'
                        : 'Generate Report'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _isAnalyzingCompatibility ? null : analyzeCompatibility,
                    child: Text(_isAnalyzingCompatibility
                        ? 'Analyzing...'
                        : 'Analyze'),
                  ),
                ],
              ),
            ),
          ),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _gaugeCard(
                title: 'Compatibility',
                value: compatibilitySummary == null
                    ? 'Wait'
                    : '${compatibilitySummary.overallScore}',
                subtitle: compatibilitySummary?.overallLevel ?? 'Analyze',
                progress: compatibilitySummary == null
                    ? 0
                    : compatibilitySummary.overallScore / 100.0,
              ),
              _gaugeCard(
                title: 'Battery',
                value: '${powerState.batteryLevel}%',
                subtitle: 'Live battery level',
                progress: powerState.batteryLevel / 100.0,
              ),
              _capabilityChartCard(
                sensors: sensors,
                cameras: cameraCapabilities,
                codecs: mediaCodecs,
                features: features,
              ),
              _networkSpeedChartCard(
                visibleNetworkSpeedSample: visibleNetworkSpeedSample,
                isConnected: isNetworkConnected,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _sectionCard(
            title: 'Orientation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SummaryRow(
                  label: 'Orientation',
                  value: deviceOrientation?.orientationName ?? 'Unknown',
                ),
                _SummaryRow(
                  label: 'Degrees',
                  value: deviceOrientation?.rotationDegrees.toString() ?? 'Unknown',
                ),
                _SummaryRow(
                  label: 'Source',
                  value: deviceOrientation?.source ?? 'Unknown',
                ),
              ],
            ),
          ),

          _sectionCard(
            title: 'Network & App Traffic',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SummaryRow(
                  label: 'Status',
                  value: isNetworkConnected ? 'Connected' : 'Disconnected',
                ),
                _SummaryRow(
                  label: 'Download',
                  value: _formatSpeed(visibleNetworkSpeedSample?.rxBytesPerSecond),
                ),
                _SummaryRow(
                  label: 'Upload',
                  value: _formatSpeed(visibleNetworkSpeedSample?.txBytesPerSecond),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _sectionCard(
            title: 'Platform Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SummaryRow(label: 'Manufacturer', value: summary.manufacturer),
                _SummaryRow(label: 'Model', value: summary.model),
                _SummaryRow(label: 'Android Release', value: summary.androidRelease),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _sectionCard(
            title: 'Power',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Battery', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: powerState.batteryLevel / 100.0),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${powerState.batteryLevel}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
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

  
}

Widget _gaugeCard({
  required String title,
  required String value,
  required String subtitle,
  required double progress,
}) {
  return SizedBox(
    width: 180,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _capabilityChartCard({
  required List<NativeSensor> sensors,
  required List<CameraCapability> cameras,
  required List<MediaCodecCapability> codecs,
  required List<SystemFeature> features,
}) {
  final int maxCount = [
    sensors.length,
    cameras.length,
    codecs.length,
    features.length,
    1,
  ].reduce((int a, int b) => a > b ? a : b);

  return SizedBox(
    width: 280,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Capability Counts',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _capabilityBarRow('Sensors', sensors.length, maxCount),
            _capabilityBarRow('Cameras', cameras.length, maxCount),
            _capabilityBarRow('Codecs', codecs.length, maxCount),
            _capabilityBarRow('Features', features.length, maxCount),
          ],
        ),
      ),
    ),
  );
}

Widget _capabilityBarRow(String label, int count, int maxCount) {
  final double fraction = count / maxCount;

  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: fraction.clamp(0.0, 1.0)),
      ],
    ),
  );
}

Widget _networkSpeedChartCard({
  required NetworkSpeedSample? visibleNetworkSpeedSample,
  required bool isConnected,
}) {
  final int rx = visibleNetworkSpeedSample?.rxBytesPerSecond ?? 0;
  final int tx = visibleNetworkSpeedSample?.txBytesPerSecond ?? 0;
  final int maxSpeed = [rx, tx, 1].reduce((int a, int b) => a > b ? a : b);

  return SizedBox(
    width: 280,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Live Network Speed',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  isConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _speedBarRow('Download', rx, maxSpeed),
            _speedBarRow('Upload', tx, maxSpeed),
          ],
        ),
      ),
    ),
  );
}

Widget _speedBarRow(String label, int bytesPerSecond, int maxSpeed) {
  final double fraction = maxSpeed == 0 ? 0 : bytesPerSecond / maxSpeed;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: fraction.clamp(0.0, 1.0)),
      ],
    ),
  );
}

Widget _sectionCard({required String title, required Widget child}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
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

// Removed unused detailed rows and text sections after dashboard refactor.
