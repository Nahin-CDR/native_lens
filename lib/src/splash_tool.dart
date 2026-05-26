import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

class NativeLensSplashException implements Exception {
  const NativeLensSplashException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NativeLensSplashConfig {
  const NativeLensSplashConfig({
    required this.backgroundColor,
    required this.imagePath,
    required this.android,
    required this.ios,
  });

  final String backgroundColor;
  final String imagePath;
  final bool android;
  final bool ios;
}

class NativeLensSplashPlatformSelection {
  const NativeLensSplashPlatformSelection({
    required this.android,
    required this.ios,
  });

  final bool android;
  final bool ios;

  bool get hasAnyPlatform => android || ios;
}

class NativeLensSplashPlan {
  const NativeLensSplashPlan({
    required this.projectRoot,
    required this.pubspecPath,
    required this.config,
    required this.platforms,
    required this.androidProjectPath,
    required this.iosProjectPath,
    required this.plannedFiles,
  });

  final String projectRoot;
  final String pubspecPath;
  final NativeLensSplashConfig config;
  final NativeLensSplashPlatformSelection platforms;
  final String? androidProjectPath;
  final String? iosProjectPath;
  final List<String> plannedFiles;
}

typedef StdoutWriter = void Function(String message);

Future<int> runNativeLensSplash(
  List<String> arguments, {
  Directory? workingDirectory,
  StdoutWriter? stdoutWriter,
  StdoutWriter? stderrWriter,
}) async {
  final ArgParser parser = buildSplashArgParser();
  final StdoutWriter out = stdoutWriter ?? stdout.writeln;
  final StdoutWriter err = stderrWriter ?? stderr.writeln;

  try {
    final ArgResults results = parser.parse(arguments);

    if (results['help'] as bool) {
      out(buildSplashUsage(parser));
      return 0;
    }

    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: workingDirectory ?? Directory.current,
      androidOnly: results['android'] as bool,
      iosOnly: results['ios'] as bool,
    );

    out(formatSplashPlan(plan, dryRun: results['dry-run'] as bool));

    if (!(results['dry-run'] as bool)) {
      out('');
      out('Native splash generation is not implemented in this preview.');
      out('No Android or iOS files were modified.');
    }

    return 0;
  } on FormatException catch (error) {
    err('NativeLens splash setup error: ${error.message}');
    err('');
    err(buildSplashUsage(parser));
    return 64;
  } on NativeLensSplashException catch (error) {
    err('NativeLens splash setup error: ${error.message}');
    return 1;
  }
}

ArgParser buildSplashArgParser() {
  return ArgParser()
    ..addFlag(
      'dry-run',
      help: 'Preview the native splash plan without modifying files.',
      negatable: false,
    )
    ..addFlag(
      'android',
      help: 'Plan Android native splash changes only.',
      negatable: false,
    )
    ..addFlag(
      'ios',
      help: 'Plan iOS native splash changes only.',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);
}

String buildSplashUsage(ArgParser parser) {
  return [
    'NativeLens native splash setup preview',
    '',
    'Usage: dart run native_lens:splash [options]',
    '',
    parser.usage,
  ].join('\n');
}

NativeLensSplashPlan buildSplashPlan({
  required Directory workingDirectory,
  bool androidOnly = false,
  bool iosOnly = false,
}) {
  final File pubspecFile = findNearestPubspec(workingDirectory);
  final Directory projectRoot = pubspecFile.parent;
  final NativeLensSplashConfig config = parseSplashConfig(pubspecFile);
  final NativeLensSplashPlatformSelection platforms = resolvePlatforms(
    config,
    androidOnly: androidOnly,
    iosOnly: iosOnly,
  );

  if (!platforms.hasAnyPlatform) {
    throw const NativeLensSplashException(
      'No splash platforms are enabled. Enable android or ios in '
      'native_lens.splash.',
    );
  }

  final String? androidProjectPath = platforms.android
      ? detectAndroidProjectPath(projectRoot)
      : null;
  final String? iosProjectPath = platforms.ios
      ? detectIosProjectPath(projectRoot)
      : null;

  final List<String> plannedFiles = buildPlannedFiles(platforms: platforms);

  return NativeLensSplashPlan(
    projectRoot: projectRoot.path,
    pubspecPath: pubspecFile.path,
    config: config,
    platforms: platforms,
    androidProjectPath: androidProjectPath,
    iosProjectPath: iosProjectPath,
    plannedFiles: plannedFiles,
  );
}

File findNearestPubspec(Directory startDirectory) {
  Directory current = startDirectory.absolute;

  while (true) {
    final File candidate = File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    );
    if (candidate.existsSync()) {
      return candidate;
    }

    final Directory parent = current.parent;
    if (parent.path == current.path) {
      throw NativeLensSplashException(
        'Could not find pubspec.yaml from ${startDirectory.path}. '
        'Run this command inside a Flutter project.',
      );
    }

    current = parent;
  }
}

NativeLensSplashConfig parseSplashConfig(File pubspecFile) {
  final Object? document = loadYaml(pubspecFile.readAsStringSync());

  if (document is! YamlMap) {
    throw const NativeLensSplashException(
      'pubspec.yaml must contain a YAML map.',
    );
  }

  final Object? nativeLens = document['native_lens'];
  if (nativeLens is! YamlMap) {
    throw const NativeLensSplashException(
      'Missing native_lens config in pubspec.yaml.',
    );
  }

  final Object? splash = nativeLens['splash'];
  if (splash is! YamlMap) {
    throw const NativeLensSplashException(
      'Missing native_lens.splash config in pubspec.yaml.',
    );
  }

  final Object? backgroundColor = splash['background_color'];
  if (backgroundColor is! String || !_isValidColor(backgroundColor)) {
    throw const NativeLensSplashException(
      'native_lens.splash.background_color must be #RRGGBB or #AARRGGBB.',
    );
  }

  final Object? imagePath = splash['image'];
  if (imagePath is! String || imagePath.trim().isEmpty) {
    throw const NativeLensSplashException(
      'native_lens.splash.image must be a non-empty file path.',
    );
  }

  final File imageFile = File(
    '${pubspecFile.parent.path}${Platform.pathSeparator}$imagePath',
  );
  if (!imageFile.existsSync()) {
    throw NativeLensSplashException('Splash image does not exist: $imagePath');
  }

  return NativeLensSplashConfig(
    backgroundColor: backgroundColor,
    imagePath: imagePath,
    android: _readOptionalBool(splash, 'android', defaultValue: true),
    ios: _readOptionalBool(splash, 'ios', defaultValue: true),
  );
}

NativeLensSplashPlatformSelection resolvePlatforms(
  NativeLensSplashConfig config, {
  required bool androidOnly,
  required bool iosOnly,
}) {
  final bool hasPlatformFlag = androidOnly || iosOnly;
  final bool android = hasPlatformFlag ? androidOnly : config.android;
  final bool ios = hasPlatformFlag ? iosOnly : config.ios;

  if (android && !config.android) {
    throw const NativeLensSplashException(
      'Android splash is disabled in native_lens.splash.android.',
    );
  }

  if (ios && !config.ios) {
    throw const NativeLensSplashException(
      'iOS splash is disabled in native_lens.splash.ios.',
    );
  }

  return NativeLensSplashPlatformSelection(android: android, ios: ios);
}

String? detectAndroidProjectPath(Directory projectRoot) {
  final Directory androidDirectory = Directory(
    '${projectRoot.path}${Platform.pathSeparator}android',
  );
  return androidDirectory.existsSync() ? androidDirectory.path : null;
}

String? detectIosProjectPath(Directory projectRoot) {
  final Directory iosDirectory = Directory(
    '${projectRoot.path}${Platform.pathSeparator}ios',
  );
  return iosDirectory.existsSync() ? iosDirectory.path : null;
}

List<String> buildPlannedFiles({
  required NativeLensSplashPlatformSelection platforms,
}) {
  final List<String> files = <String>[];

  if (platforms.android) {
    files.addAll(<String>[
      'android/app/src/main/res/values/colors.xml',
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-v31/styles.xml',
      'android/app/src/main/res/drawable/launch_background.xml',
      'android/app/src/main/res/drawable-v21/launch_background.xml',
      'android/app/src/main/AndroidManifest.xml',
    ]);
  }

  if (platforms.ios) {
    files.addAll(<String>[
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/Contents.json',
      'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/splash.png',
    ]);
  }

  return files;
}

String formatSplashPlan(NativeLensSplashPlan plan, {required bool dryRun}) {
  final List<String> lines = <String>[
    dryRun
        ? 'NativeLens native splash dry run'
        : 'NativeLens native splash setup preview',
    '',
    'Project root: ${plan.projectRoot}',
    'Pubspec: ${plan.pubspecPath}',
    '',
    'Config:',
    '  background_color: ${plan.config.backgroundColor}',
    '  image: ${plan.config.imagePath}',
    '  android: ${plan.config.android}',
    '  ios: ${plan.config.ios}',
    '',
    'Selected platforms:',
    '  android: ${plan.platforms.android}',
    '  ios: ${plan.platforms.ios}',
    '',
    'Detected project paths:',
    '  android: ${plan.androidProjectPath ?? 'not found'}',
    '  ios: ${plan.iosProjectPath ?? 'not found'}',
    '',
    'Files that would be modified later:',
  ];

  for (final String file in plan.plannedFiles) {
    lines.add('  - $file');
  }

  lines.add('');
  lines.add('No Android or iOS files were modified.');

  return lines.join('\n');
}

bool _isValidColor(String value) {
  return RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value);
}

bool _readOptionalBool(YamlMap map, String key, {required bool defaultValue}) {
  final Object? value = map[key];
  if (value == null) {
    return defaultValue;
  }

  if (value is bool) {
    return value;
  }

  throw NativeLensSplashException(
    'native_lens.splash.$key must be true or false.',
  );
}
