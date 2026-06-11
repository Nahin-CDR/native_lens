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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _nativeLensPlugin = NativeLens();
  final TextEditingController _customMinBatteryController =
      TextEditingController(text: '20');
  final TextEditingController _featureMinBatteryController =
      TextEditingController(text: '20');
  final TextEditingController _streamingMinBatteryController =
      TextEditingController(text: '15');
  final TextEditingController _streamProbeUrlController = TextEditingController(
    text: 'https://example.com/stream.m3u8',
  );
  final TextEditingController _streamProbeTimeoutController =
      TextEditingController(text: '8');
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
  NativeLensThemeMode? _themeMode;
  NativeLensThemeMode? _liveThemeMode;
  NativeLensTask _selectedTask = NativeLensTask.videoUpload;
  NativeTaskRiskResult? _taskRiskResult;
  NativeLensFeature _selectedFeature = NativeLensFeature.faceFilterCamera;
  NativeLensCustomTaskResult? _smartFeatureResult;
  NativeLensCustomTaskResult? _streamingReadinessResult;
  NativeLensStreamProbeResult? _streamProbeResult;
  NativeLensCustomTaskResult? _customTaskResult;
  NativeLensPreset _selectedPreset = NativeLensPreset.liveStreaming;
  NativeLensCustomTaskResult? _presetTaskResult;
  StreamSubscription<NetworkCapability>? _networkCapabilitySubscription;
  StreamSubscription<NetworkSpeedSample>? _networkSpeedSubscription;
  StreamSubscription<DeviceOrientationInfo>? _deviceOrientationSubscription;
  StreamSubscription<PowerState>? _powerStateSubscription;
  StreamSubscription<NativeLensThemeMode>? _themeModeSubscription;
  bool _isGeneratingReport = false;
  bool _isAnalyzingCompatibility = false;
  bool _isAnalyzingTaskRisk = false;
  bool _isAnalyzingSmartFeature = false;
  bool _isAnalyzingStreamingReadiness = false;
  bool _isProbingStreamUrl = false;
  bool _isAnalyzingCustomTask = false;
  bool _isAnalyzingPresetTask = false;
  bool _isLoadingThemeMode = false;
  bool _featureRealtime = false;
  bool _featureHighPerformance = false;
  bool _featurePreferUnmeteredNetwork = false;
  bool _featureDisallowPowerSaveMode = false;
  bool _streamingRealtime = false;
  bool _streamingHighPerformance = false;
  bool _streamingPreferUnmeteredNetwork = false;
  bool _streamingDisallowPowerSaveMode = false;
  bool _streamProbeFollowRedirects = true;
  bool _streamProbeRequireHttps = false;
  bool _customRequiresCamera = true;
  bool _customRequiresMicrophone = false;
  bool _customRequiresStableNetwork = false;
  String? _errorMessage;
  String? _taskRiskErrorMessage;
  String? _smartFeatureErrorMessage;
  String? _streamingReadinessErrorMessage;
  String? _streamProbeErrorMessage;
  String? _customTaskErrorMessage;
  String? _presetTaskErrorMessage;
  String? _themeModeErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    listenToPowerState();
    listenToNetworkCapability();
    listenToNetworkSpeed();
    listenToDeviceOrientation();
    listenToThemeMode();
    refreshThemeMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamProbeTimeoutController.dispose();
    _streamProbeUrlController.dispose();
    _streamingMinBatteryController.dispose();
    _featureMinBatteryController.dispose();
    _customMinBatteryController.dispose();
    _powerStateSubscription?.cancel();
    _networkCapabilitySubscription?.cancel();
    _networkSpeedSubscription?.cancel();
    _deviceOrientationSubscription?.cancel();
    _themeModeSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshPowerState();
      refreshThemeMode();
    }
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

  Future<void> refreshPowerState() async {
    PowerState? powerState;

    try {
      powerState = await _nativeLensPlugin.getPowerState();
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }

    if (!mounted) return;

    setState(() {
      _powerState = powerState;
    });
  }

  Future<void> refreshThemeMode() async {
    setState(() {
      _isLoadingThemeMode = true;
      _themeModeErrorMessage = null;
    });

    NativeLensThemeMode? themeMode;
    String? errorMessage;

    try {
      themeMode = await _nativeLensPlugin.getThemeMode();
    } on PlatformException {
      errorMessage = 'Failed to read native theme mode.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    }

    if (!mounted) return;

    setState(() {
      _themeMode = themeMode;
      _isLoadingThemeMode = false;
      _themeModeErrorMessage = errorMessage;
    });
  }

  void listenToPowerState() {
    _powerStateSubscription = _nativeLensPlugin.watchPowerState().listen(
      (PowerState powerState) {
        if (!mounted) return;

        setState(() {
          _powerState = powerState;
        });
      },
      onError: (Object error) {
        // The startup snapshot and lifecycle refresh still provide a safe
        // fallback if the stream is unavailable in a test or unsupported host.
      },
    );
  }

  void listenToThemeMode() {
    _themeModeSubscription = _nativeLensPlugin.watchThemeMode().listen(
      (NativeLensThemeMode themeMode) {
        if (!mounted) return;

        setState(() {
          _liveThemeMode = themeMode;
        });
      },
      onError: (Object error) {
        // The snapshot button still provides a safe fallback if live theme
        // updates are unavailable on an unsupported host.
      },
    );
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
    _deviceOrientationSubscription = _nativeLensPlugin.deviceOrientationStream
        .listen(
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

  Future<void> analyzeTaskRisk() async {
    setState(() {
      _isAnalyzingTaskRisk = true;
      _taskRiskErrorMessage = null;
    });

    NativeTaskRiskResult? result;
    String? errorMessage;

    try {
      result = await _nativeLensPlugin.analyzeTaskRisk(task: _selectedTask);
    } on PlatformException {
      errorMessage = 'Failed to analyze task risk.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    } catch (error) {
      errorMessage = 'Failed to analyze task risk: $error';
    }

    if (!mounted) return;

    setState(() {
      _taskRiskResult = result;
      _isAnalyzingTaskRisk = false;
      _taskRiskErrorMessage = errorMessage;
    });
  }

  Future<void> analyzeFaceFilterCamera() async {
    setState(() {
      _isAnalyzingCustomTask = true;
      _customTaskErrorMessage = null;
    });

    NativeLensCustomTaskResult? result;
    String? errorMessage;
    final int? minBatteryLevel = int.tryParse(
      _customMinBatteryController.text.trim(),
    );

    try {
      result = await _nativeLensPlugin.analyzeCustomTask(
        taskName: 'Face Filter Camera',
        requirements: NativeLensTaskRequirements(
          requiresCamera: _customRequiresCamera,
          requiresMicrophone: _customRequiresMicrophone,
          requiresStableNetwork: _customRequiresStableNetwork,
          requiredSensors: const <String>['gyroscope', 'accelerometer'],
          minBatteryLevel: minBatteryLevel,
        ),
      );
    } on PlatformException {
      errorMessage = 'Failed to analyze custom task requirements.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    } catch (error) {
      errorMessage = 'Failed to analyze custom task requirements: $error';
    }

    if (!mounted) return;

    setState(() {
      _customTaskResult = result;
      _isAnalyzingCustomTask = false;
      _customTaskErrorMessage = errorMessage;
    });
  }

  Future<void> analyzeSmartFeature() async {
    setState(() {
      _isAnalyzingSmartFeature = true;
      _smartFeatureErrorMessage = null;
    });

    NativeLensCustomTaskResult? result;
    String? errorMessage;
    final int? minBatteryLevel = int.tryParse(
      _featureMinBatteryController.text.trim(),
    );

    try {
      result = await _nativeLensPlugin.analyzeFeature(
        _selectedFeature,
        options: NativeLensFeatureOptions(
          realtime: _featureRealtime,
          highPerformance: _featureHighPerformance,
          minBatteryLevel: minBatteryLevel,
          preferUnmeteredNetwork: _featurePreferUnmeteredNetwork,
          disallowPowerSaveMode: _featureDisallowPowerSaveMode,
        ),
      );
    } on PlatformException {
      errorMessage = 'Failed to analyze smart feature.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    } catch (error) {
      errorMessage = 'Failed to analyze smart feature: $error';
    }

    if (!mounted) return;

    setState(() {
      _smartFeatureResult = result;
      _isAnalyzingSmartFeature = false;
      _smartFeatureErrorMessage = errorMessage;
    });
  }

  Future<void> analyzeStreamingReadiness() async {
    setState(() {
      _isAnalyzingStreamingReadiness = true;
      _streamingReadinessErrorMessage = null;
    });

    NativeLensCustomTaskResult? result;
    String? errorMessage;
    final int? minBatteryLevel = int.tryParse(
      _streamingMinBatteryController.text.trim(),
    );

    try {
      result = await _nativeLensPlugin.analyzeStreamingReadiness(
        options: NativeLensFeatureOptions(
          realtime: _streamingRealtime,
          highPerformance: _streamingHighPerformance,
          minBatteryLevel: minBatteryLevel,
          preferUnmeteredNetwork: _streamingPreferUnmeteredNetwork,
          disallowPowerSaveMode: _streamingDisallowPowerSaveMode,
        ),
      );
    } on PlatformException {
      errorMessage = 'Failed to analyze streaming readiness.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    } catch (error) {
      errorMessage = 'Failed to analyze streaming readiness: $error';
    }

    if (!mounted) return;

    setState(() {
      _streamingReadinessResult = result;
      _isAnalyzingStreamingReadiness = false;
      _streamingReadinessErrorMessage = errorMessage;
    });
  }

  Future<void> probeStreamUrl() async {
    setState(() {
      _isProbingStreamUrl = true;
      _streamProbeErrorMessage = null;
    });

    NativeLensStreamProbeResult? result;
    String? errorMessage;
    final String url = _streamProbeUrlController.text.trim();
    final int parsedTimeoutSeconds =
        int.tryParse(_streamProbeTimeoutController.text.trim()) ?? 8;
    final int timeoutSeconds = parsedTimeoutSeconds > 0
        ? parsedTimeoutSeconds
        : 8;

    try {
      result = await _nativeLensPlugin.probeStreamingUrl(
        url: url,
        options: NativeLensStreamProbeOptions(
          timeout: Duration(seconds: timeoutSeconds),
          followRedirects: _streamProbeFollowRedirects,
          requireHttps: _streamProbeRequireHttps,
        ),
      );
    } catch (error) {
      errorMessage = 'Failed to probe stream URL: $error';
    }

    if (!mounted) return;

    setState(() {
      _streamProbeResult = result;
      _isProbingStreamUrl = false;
      _streamProbeErrorMessage = errorMessage;
    });
  }

  Future<void> analyzePresetFeature() async {
    setState(() {
      _isAnalyzingPresetTask = true;
      _presetTaskErrorMessage = null;
    });

    NativeLensCustomTaskResult? result;
    String? errorMessage;

    try {
      result = await _nativeLensPlugin.analyzePresetTask(_selectedPreset);
    } on PlatformException {
      errorMessage = 'Failed to analyze preset feature.';
    } on MissingPluginException {
      errorMessage = 'NativeLens is not available on this platform.';
    } catch (error) {
      errorMessage = 'Failed to analyze preset feature: $error';
    }

    if (!mounted) return;

    setState(() {
      _presetTaskResult = result;
      _isAnalyzingPresetTask = false;
      _presetTaskErrorMessage = errorMessage;
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
                        Text(
                          'NativeLens Dashboard',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${summary.manufacturer} ${summary.model}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isGeneratingReport ? null : generateFullReport,
                    child: Text(
                      _isGeneratingReport ? 'Generating...' : 'Generate Report',
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _isAnalyzingCompatibility
                        ? null
                        : analyzeCompatibility,
                    child: Text(
                      _isAnalyzingCompatibility ? 'Analyzing...' : 'Analyze',
                    ),
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

          _datasetExportSection(),

          const SizedBox(height: 16),

          _taskRiskAnalysisSection(),

          const SizedBox(height: 16),

          _smartFeatureIntelligenceSection(),

          const SizedBox(height: 16),

          _streamingReadinessIntelligenceSection(),

          const SizedBox(height: 16),

          _streamUrlProbeIntelligenceSection(),

          const SizedBox(height: 16),

          _customTaskRequirementsSection(),

          const SizedBox(height: 16),

          _themeModeSection(),

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
                  value:
                      deviceOrientation?.rotationDegrees.toString() ??
                      'Unknown',
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
                  value: _formatSpeed(
                    visibleNetworkSpeedSample?.rxBytesPerSecond,
                  ),
                ),
                _SummaryRow(
                  label: 'Upload',
                  value: _formatSpeed(
                    visibleNetworkSpeedSample?.txBytesPerSecond,
                  ),
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
                _SummaryRow(
                  label: 'Platform',
                  value: summary.platformName ?? 'Unknown',
                ),
                _SummaryRow(label: 'Manufacturer', value: summary.manufacturer),
                _SummaryRow(label: 'Model', value: summary.model),
                _SummaryRow(
                  label: 'OS',
                  value:
                      '${summary.osName ?? 'Unknown'} '
                      '${summary.osVersion ?? summary.androidRelease}',
                ),
                if (summary.androidSdk > 0)
                  _SummaryRow(
                    label: 'Android SDK',
                    value: summary.androidSdk.toString(),
                  ),
                if (summary.localizedModel != null)
                  _SummaryRow(
                    label: 'Localized Model',
                    value: summary.localizedModel!,
                  ),
                if (summary.appEnvironment != null)
                  _SummaryRow(
                    label: 'Environment',
                    value: summary.appEnvironment!,
                  ),
                if (summary.physicalMemoryBytes != null)
                  _SummaryRow(
                    label: 'Memory',
                    value: _formatBytes(summary.physicalMemoryBytes!),
                  ),
                if (summary.processorCount != null)
                  _SummaryRow(
                    label: 'Processors',
                    value: summary.activeProcessorCount == null
                        ? summary.processorCount.toString()
                        : '${summary.activeProcessorCount}/${summary.processorCount}',
                  ),
                if (summary.thermalState != null)
                  _SummaryRow(label: 'Thermal', value: summary.thermalState!),
                if (summary.isIosNative)
                  const _SummaryRow(label: 'iOS Native', value: 'Yes'),
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
                            Text(
                              'Battery',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: powerState.batteryLevel / 100.0,
                            ),
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

  String _formatBytes(int bytes) {
    final double gibibytes = bytes / (1024 * 1024 * 1024);
    return '${gibibytes.toStringAsFixed(2)} GiB';
  }

  Widget _themeModeSection() {
    return _sectionCard(
      title: 'Theme Mode Intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryRow(
            label: 'Current Theme',
            value: _themeModeLabel(_themeMode),
          ),
          _SummaryRow(
            label: 'Live Theme',
            value: _themeModeLabel(_liveThemeMode, waitingLabel: 'Waiting'),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isLoadingThemeMode ? null : refreshThemeMode,
            icon: _isLoadingThemeMode
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.brightness_6_rounded),
            label: Text(_isLoadingThemeMode ? 'Reading...' : 'Get Theme Mode'),
          ),
          if (_themeModeErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _themeModeErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  String _themeModeLabel(
    NativeLensThemeMode? themeMode, {
    String waitingLabel = 'Unknown',
  }) {
    if (themeMode == null) {
      return waitingLabel;
    }

    switch (themeMode) {
      case NativeLensThemeMode.light:
        return 'Light';
      case NativeLensThemeMode.dark:
        return 'Dark';
      case NativeLensThemeMode.unknown:
        return 'Unknown';
    }
  }

  Widget _datasetExportSection() {
    return _sectionCard(
      title: 'Dataset Export',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Generate the current NativeLens row and copy it as JSON or CSV.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => _copyDatasetExport(format: 'json'),
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy Dataset JSON'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyDatasetExport(format: 'csv'),
                icon: const Icon(Icons.table_chart_rounded),
                label: const Text('Copy Dataset CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskRiskAnalysisSection() {
    final NativeTaskRiskResult? result = _taskRiskResult;

    return _sectionCard(
      title: 'Task Risk Analysis',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButtonFormField<NativeLensTask>(
            initialValue: _selectedTask,
            decoration: const InputDecoration(
              labelText: 'Task',
              border: OutlineInputBorder(),
            ),
            items: NativeLensTask.values
                .map(
                  (NativeLensTask task) => DropdownMenuItem<NativeLensTask>(
                    value: task,
                    child: Text(_taskLabel(task)),
                  ),
                )
                .toList(),
            onChanged: _isAnalyzingTaskRisk
                ? null
                : (NativeLensTask? task) {
                    if (task == null) return;

                    setState(() {
                      _selectedTask = task;
                    });
                  },
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isAnalyzingTaskRisk ? null : analyzeTaskRisk,
            icon: _isAnalyzingTaskRisk
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_alt_rounded),
            label: Text(
              _isAnalyzingTaskRisk ? 'Analyzing Task...' : 'Analyze Task Risk',
            ),
          ),
          if (_taskRiskErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _taskRiskErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            _taskRiskResultPanel(result),
          ],
        ],
      ),
    );
  }

  Widget _taskRiskResultPanel(NativeTaskRiskResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryRow(label: 'Task', value: _taskLabel(result.task)),
          _SummaryRow(label: 'Risk', value: result.riskLevel),
          _SummaryRow(
            label: 'Confidence',
            value: result.confidence.toStringAsFixed(2),
          ),
          _SummaryRow(
            label: 'Analyzed',
            value: _formatTimestamp(result.analyzedAtMillis),
          ),
          const SizedBox(height: 8),
          _capabilitySection(
            title: 'Required Capabilities',
            capabilities: result.requiredCapabilities,
          ),
          const SizedBox(height: 8),
          _capabilitySection(
            title: 'Available Capabilities',
            capabilities: result.availableCapabilities,
          ),
          const SizedBox(height: 8),
          _capabilitySection(
            title: 'Missing Capabilities',
            capabilities: result.missingCapabilities,
            emptyMessage: 'No missing required capabilities detected.',
          ),
          const SizedBox(height: 8),
          const Text('Reasons', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...result.reasons.map(
            (String reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('- $reason'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recommendation',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(result.recommendation),
        ],
      ),
    );
  }

  Widget _smartFeatureIntelligenceSection() {
    final NativeLensCustomTaskResult? result = _smartFeatureResult;

    return _sectionCard(
      title: 'Smart Feature Intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButtonFormField<NativeLensFeature>(
            initialValue: _selectedFeature,
            decoration: const InputDecoration(
              labelText: 'Feature',
              border: OutlineInputBorder(),
            ),
            items: NativeLensFeature.values
                .map(
                  (NativeLensFeature feature) =>
                      DropdownMenuItem<NativeLensFeature>(
                        value: feature,
                        child: Text(_featureLabel(feature)),
                      ),
                )
                .toList(),
            onChanged: _isAnalyzingSmartFeature
                ? null
                : (NativeLensFeature? feature) {
                    if (feature == null) return;

                    setState(() {
                      _selectedFeature = feature;
                    });
                  },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Realtime'),
            value: _featureRealtime,
            onChanged: _isAnalyzingSmartFeature
                ? null
                : (bool value) {
                    setState(() {
                      _featureRealtime = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('High performance'),
            value: _featureHighPerformance,
            onChanged: _isAnalyzingSmartFeature
                ? null
                : (bool value) {
                    setState(() {
                      _featureHighPerformance = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer unmetered network'),
            value: _featurePreferUnmeteredNetwork,
            onChanged: _isAnalyzingSmartFeature
                ? null
                : (bool value) {
                    setState(() {
                      _featurePreferUnmeteredNetwork = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disallow power save mode'),
            value: _featureDisallowPowerSaveMode,
            onChanged: _isAnalyzingSmartFeature
                ? null
                : (bool value) {
                    setState(() {
                      _featureDisallowPowerSaveMode = value;
                    });
                  },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _featureMinBatteryController,
            enabled: !_isAnalyzingSmartFeature,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minimum battery level',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isAnalyzingSmartFeature ? null : analyzeSmartFeature,
            icon: _isAnalyzingSmartFeature
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              _isAnalyzingSmartFeature ? 'Analyzing...' : 'Analyze Feature',
            ),
          ),
          if (_smartFeatureErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _smartFeatureErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            _customTaskResultPanel(result),
          ],
        ],
      ),
    );
  }

  Widget _streamingReadinessIntelligenceSection() {
    final NativeLensCustomTaskResult? result = _streamingReadinessResult;

    return _sectionCard(
      title: 'Streaming Readiness Intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Checks current device/network readiness for streaming.'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Realtime'),
            value: _streamingRealtime,
            onChanged: _isAnalyzingStreamingReadiness
                ? null
                : (bool value) {
                    setState(() {
                      _streamingRealtime = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('High performance'),
            value: _streamingHighPerformance,
            onChanged: _isAnalyzingStreamingReadiness
                ? null
                : (bool value) {
                    setState(() {
                      _streamingHighPerformance = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Prefer unmetered network'),
            value: _streamingPreferUnmeteredNetwork,
            onChanged: _isAnalyzingStreamingReadiness
                ? null
                : (bool value) {
                    setState(() {
                      _streamingPreferUnmeteredNetwork = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Disallow power save mode'),
            value: _streamingDisallowPowerSaveMode,
            onChanged: _isAnalyzingStreamingReadiness
                ? null
                : (bool value) {
                    setState(() {
                      _streamingDisallowPowerSaveMode = value;
                    });
                  },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _streamingMinBatteryController,
            enabled: !_isAnalyzingStreamingReadiness,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minimum battery level',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isAnalyzingStreamingReadiness
                ? null
                : analyzeStreamingReadiness,
            icon: _isAnalyzingStreamingReadiness
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.live_tv_rounded),
            label: Text(
              _isAnalyzingStreamingReadiness
                  ? 'Analyzing...'
                  : 'Analyze Streaming Readiness',
            ),
          ),
          if (_streamingReadinessErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _streamingReadinessErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            _customTaskResultPanel(result),
          ],
        ],
      ),
    );
  }

  Widget _streamUrlProbeIntelligenceSection() {
    final NativeLensStreamProbeResult? result = _streamProbeResult;

    return _sectionCard(
      title: 'Stream URL Probe Intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Checks URL/manifest readiness before playback startup.'),
          const SizedBox(height: 8),
          TextField(
            controller: _streamProbeUrlController,
            enabled: !_isProbingStreamUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Stream URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _streamProbeTimeoutController,
            enabled: !_isProbingStreamUrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Timeout seconds',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Follow redirects'),
            value: _streamProbeFollowRedirects,
            onChanged: _isProbingStreamUrl
                ? null
                : (bool value) {
                    setState(() {
                      _streamProbeFollowRedirects = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require HTTPS'),
            value: _streamProbeRequireHttps,
            onChanged: _isProbingStreamUrl
                ? null
                : (bool value) {
                    setState(() {
                      _streamProbeRequireHttps = value;
                    });
                  },
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isProbingStreamUrl ? null : probeStreamUrl,
            icon: _isProbingStreamUrl
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.travel_explore_rounded),
            label: Text(
              _isProbingStreamUrl ? 'Probing...' : 'Probe Streaming URL',
            ),
          ),
          if (_streamProbeErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _streamProbeErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            _streamProbeResultPanel(result),
          ],
        ],
      ),
    );
  }

  Widget _customTaskRequirementsSection() {
    final NativeLensCustomTaskResult? result = _customTaskResult;
    final NativeLensCustomTaskResult? presetResult = _presetTaskResult;

    return _sectionCard(
      title: 'Custom Task Requirements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Requires camera'),
            value: _customRequiresCamera,
            onChanged: _isAnalyzingCustomTask
                ? null
                : (bool value) {
                    setState(() {
                      _customRequiresCamera = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Requires microphone'),
            value: _customRequiresMicrophone,
            onChanged: _isAnalyzingCustomTask
                ? null
                : (bool value) {
                    setState(() {
                      _customRequiresMicrophone = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Requires stable network'),
            value: _customRequiresStableNetwork,
            onChanged: _isAnalyzingCustomTask
                ? null
                : (bool value) {
                    setState(() {
                      _customRequiresStableNetwork = value;
                    });
                  },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customMinBatteryController,
            enabled: !_isAnalyzingCustomTask,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minimum battery level',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isAnalyzingCustomTask ? null : analyzeFaceFilterCamera,
            icon: _isAnalyzingCustomTask
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.face_retouching_natural_rounded),
            label: Text(
              _isAnalyzingCustomTask
                  ? 'Analyzing...'
                  : 'Analyze Face Filter Camera',
            ),
          ),
          if (_customTaskErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _customTaskErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 12),
            _customTaskResultPanel(result),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Preset Feature Preflight',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<NativeLensPreset>(
            initialValue: _selectedPreset,
            decoration: const InputDecoration(
              labelText: 'Preset',
              border: OutlineInputBorder(),
            ),
            items: NativeLensPreset.values
                .map(
                  (NativeLensPreset preset) =>
                      DropdownMenuItem<NativeLensPreset>(
                        value: preset,
                        child: Text(preset.name),
                      ),
                )
                .toList(),
            onChanged: _isAnalyzingPresetTask
                ? null
                : (NativeLensPreset? value) {
                    if (value == null) return;

                    setState(() {
                      _selectedPreset = value;
                    });
                  },
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _isAnalyzingPresetTask ? null : analyzePresetFeature,
            icon: _isAnalyzingPresetTask
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.fact_check_rounded),
            label: Text(
              _isAnalyzingPresetTask ? 'Analyzing...' : 'Analyze Preset',
            ),
          ),
          if (_presetTaskErrorMessage != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _presetTaskErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (presetResult != null) ...<Widget>[
            const SizedBox(height: 12),
            _customTaskResultPanel(presetResult),
          ],
        ],
      ),
    );
  }

  Widget _customTaskResultPanel(NativeLensCustomTaskResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryRow(label: 'Risk', value: result.riskLevel),
          _SummaryRow(label: 'Severity', value: result.severity),
          _SummaryRow(
            label: 'Can Continue',
            value: result.canContinue ? 'Yes' : 'No',
          ),
          _SummaryRow(label: 'User Message', value: result.userMessage),
          _SummaryRow(label: 'Developer', value: result.developerMessage),
          const SizedBox(height: 8),
          _capabilitySection(
            title: 'Missing Capabilities',
            capabilities: result.missingCapabilities,
            emptyMessage: 'No missing custom task capabilities detected.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Recommendations',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (result.recommendations.isEmpty)
            const Text('No recommendations.')
          else
            ...result.recommendations.map(
              (String recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $recommendation'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _streamProbeResultPanel(NativeLensStreamProbeResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryRow(label: 'Risk', value: result.riskLevel),
          _SummaryRow(
            label: 'Can Continue',
            value: result.canContinue ? 'Yes' : 'No',
          ),
          _SummaryRow(
            label: 'Status Code',
            value: result.statusCode?.toString() ?? 'Unknown',
          ),
          _SummaryRow(
            label: 'Content Type',
            value: result.contentType ?? 'Unknown',
          ),
          _SummaryRow(label: 'Final URL', value: result.finalUrl),
          _SummaryRow(
            label: 'Reachable',
            value: result.isReachable ? 'Yes' : 'No',
          ),
          _SummaryRow(
            label: 'Manifest',
            value: result.isManifestReadable ? 'Readable' : 'Not readable',
          ),
          _SummaryRow(
            label: 'Likely HLS',
            value: result.isLikelyHls ? 'Yes' : 'No',
          ),
          _SummaryRow(
            label: 'Variants',
            value: result.variantUrls.length.toString(),
          ),
          _SummaryRow(
            label: 'Segments',
            value: result.segmentUrls.length.toString(),
          ),
          const SizedBox(height: 8),
          const Text('Reasons', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (result.reasons.isEmpty)
            const Text('No reasons reported.')
          else
            ...result.reasons.map(
              (String reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $reason'),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Recommendations',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (result.recommendations.isEmpty)
            const Text('No recommendations.')
          else
            ...result.recommendations.map(
              (String recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('- $recommendation'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _capabilitySection({
    required String title,
    required List<String> capabilities,
    String emptyMessage = 'None reported.',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (capabilities.isEmpty)
          Text(emptyMessage)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: capabilities
                .map((String capability) => Chip(label: Text(capability)))
                .toList(),
          ),
      ],
    );
  }

  String _taskLabel(NativeLensTask task) {
    switch (task) {
      case NativeLensTask.videoUpload:
        return 'Video Upload';
      case NativeLensTask.videoRecording:
        return 'Video Recording';
      case NativeLensTask.audioRecording:
        return 'Audio Recording';
      case NativeLensTask.mediaProcessing:
        return 'Media Processing';
      case NativeLensTask.backgroundSync:
        return 'Background Sync';
      case NativeLensTask.cameraCapture:
        return 'Camera Capture';
      case NativeLensTask.realtimeStreaming:
        return 'Realtime Streaming';
      case NativeLensTask.arExperience:
        return 'AR Experience';
      case NativeLensTask.stepTracking:
        return 'Step Tracking';
      case NativeLensTask.compassNavigation:
        return 'Compass Navigation';
    }
  }

  String _featureLabel(NativeLensFeature feature) {
    switch (feature) {
      case NativeLensFeature.liveStreaming:
        return 'Live Streaming';
      case NativeLensFeature.videoUpload:
        return 'Video Upload';
      case NativeLensFeature.faceFilterCamera:
        return 'Face Filter Camera';
      case NativeLensFeature.cameraRecording:
        return 'Camera Recording';
      case NativeLensFeature.backgroundSync:
        return 'Background Sync';
      case NativeLensFeature.arExperience:
        return 'AR Experience';
      case NativeLensFeature.stepTracking:
        return 'Step Tracking';
      case NativeLensFeature.compassNavigation:
        return 'Compass Navigation';
      case NativeLensFeature.mediaProcessing:
        return 'Media Processing';
    }
  }

  String _formatTimestamp(int millis) {
    return DateTime.fromMillisecondsSinceEpoch(
      millis,
    ).toLocal().toIso8601String();
  }

  Future<void> _copyDatasetExport({required String format}) async {
    try {
      final NativeLensDatasetRow row = await _nativeLensPlugin
          .generateDatasetRow();
      final String payload = format == 'csv'
          ? NativeLensDatasetExporter.toCsv(<NativeLensDatasetRow>[row])
          : NativeLensDatasetExporter.toJson(row);

      await Clipboard.setData(ClipboardData(text: payload));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied dataset ${format.toUpperCase()} to clipboard.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to copy dataset $format: $error')),
      );
    }
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
            const Text(
              'Capability Counts',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
                const Text(
                  'Live Network Speed',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
