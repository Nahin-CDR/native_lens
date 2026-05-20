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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    PlatformSummary? platformSummary;
    List<SystemFeature>? systemFeatures;
    List<NativeSensor>? sensors;
    DisplayInfo? displayInfo;
    String? errorMessage;

    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformSummary = await _nativeLensPlugin.getPlatformSummary();
      systemFeatures = await _nativeLensPlugin.getSystemFeatures();
      sensors = await _nativeLensPlugin.getSensors();
      displayInfo = await _nativeLensPlugin.getDisplayInfo();
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
      _errorMessage = errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        displayInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
