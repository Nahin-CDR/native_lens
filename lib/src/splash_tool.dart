import 'dart:convert';
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
    required this.warnings,
  });

  final String projectRoot;
  final String pubspecPath;
  final NativeLensSplashConfig config;
  final NativeLensSplashPlatformSelection platforms;
  final String? androidProjectPath;
  final String? iosProjectPath;
  final List<NativeLensSplashFilePlan> plannedFiles;
  final List<String> warnings;
}

class NativeLensSplashFilePlan {
  const NativeLensSplashFilePlan({
    required this.relativePath,
    required this.action,
    required this.willBackup,
  });

  final String relativePath;
  final String action;
  final bool willBackup;
}

class NativeLensSplashGenerationResult {
  const NativeLensSplashGenerationResult({
    required this.backupDirectory,
    required this.manifestPath,
    required this.generatedFiles,
    required this.restoredAfterFailure,
    required this.warnings,
  });

  final String backupDirectory;
  final String manifestPath;
  final List<String> generatedFiles;
  final bool restoredAfterFailure;
  final List<String> warnings;
}

class NativeLensSplashBackupEntry {
  const NativeLensSplashBackupEntry({
    required this.relativePath,
    required this.existed,
    required this.backupRelativePath,
  });

  final String relativePath;
  final bool existed;
  final String? backupRelativePath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'relativePath': relativePath,
      'existed': existed,
      'backupRelativePath': backupRelativePath,
    };
  }
}

typedef StdoutWriter = void Function(String message);

const List<String> androidGeneratedRelativePaths = <String>[
  'android/app/src/main/res/values/colors.xml',
  'android/app/src/main/res/values/styles.xml',
  'android/app/src/main/res/values-v31/styles.xml',
  'android/app/src/main/res/drawable/launch_background.xml',
  'android/app/src/main/res/drawable-v21/launch_background.xml',
  'android/app/src/main/res/drawable/native_lens_splash.png',
];

const List<String> iosPlannedRelativePaths = <String>[
  'ios/Runner/Base.lproj/LaunchScreen.storyboard',
  'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/Contents.json',
  'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/native_lens_splash.png',
];

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

    final bool dryRun = results['dry-run'] as bool;
    out(formatSplashPlan(plan, dryRun: dryRun));

    if (!dryRun) {
      out('');
      if (plan.platforms.android) {
        final NativeLensSplashGenerationResult result = generateAndroidSplash(
          plan,
        );
        out('Android native splash files generated.');
        out('Backup: ${result.backupDirectory}');
        out('Manifest: ${result.manifestPath}');
        out('Generated files:');
        for (final String file in result.generatedFiles) {
          out('  - $file');
        }
        for (final String warning in result.warnings) {
          out('Warning: $warning');
        }
      }

      if (plan.platforms.ios) {
        final NativeLensSplashGenerationResult result = generateIosSplash(plan);
        out('iOS native splash files generated.');
        out('Backup: ${result.backupDirectory}');
        out('Manifest: ${result.manifestPath}');
        out('Generated files:');
        for (final String file in result.generatedFiles) {
          out('  - $file');
        }
        for (final String warning in result.warnings) {
          out('Warning: $warning');
        }
      }
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

  final List<NativeLensSplashFilePlan> plannedFiles = buildPlannedFiles(
    platforms: platforms,
    projectRoot: projectRoot,
  );
  final List<String> warnings = buildPlanWarnings(
    platforms: platforms,
    projectRoot: projectRoot,
    androidProjectPath: androidProjectPath,
    iosProjectPath: iosProjectPath,
  );

  return NativeLensSplashPlan(
    projectRoot: projectRoot.path,
    pubspecPath: pubspecFile.path,
    config: config,
    platforms: platforms,
    androidProjectPath: androidProjectPath,
    iosProjectPath: iosProjectPath,
    plannedFiles: plannedFiles,
    warnings: warnings,
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

List<NativeLensSplashFilePlan> buildPlannedFiles({
  required NativeLensSplashPlatformSelection platforms,
  required Directory projectRoot,
}) {
  final List<NativeLensSplashFilePlan> files = <NativeLensSplashFilePlan>[];

  if (platforms.android) {
    for (final String relativePath in androidGeneratedRelativePaths) {
      files.add(
        NativeLensSplashFilePlan(
          relativePath: relativePath,
          action: File(_join(projectRoot.path, relativePath)).existsSync()
              ? 'modify'
              : 'create',
          willBackup: true,
        ),
      );
    }
  }

  if (platforms.ios) {
    for (final String relativePath in iosPlannedRelativePaths) {
      files.add(
        NativeLensSplashFilePlan(
          relativePath: relativePath,
          action: File(_join(projectRoot.path, relativePath)).existsSync()
              ? 'modify'
              : 'create',
          willBackup: true,
        ),
      );
    }
  }

  return files;
}

List<String> buildPlanWarnings({
  required NativeLensSplashPlatformSelection platforms,
  required Directory projectRoot,
  required String? androidProjectPath,
  required String? iosProjectPath,
}) {
  final List<String> warnings = <String>[];

  if (platforms.android) {
    if (androidProjectPath == null) {
      warnings.add('Android project folder was not found.');
    } else if (!Directory(
      _join(projectRoot.path, 'android', 'app'),
    ).existsSync()) {
      warnings.add('Android app module was not found at android/app.');
    }

    final File manifestFile = File(
      _join(
        projectRoot.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ),
    );
    if (!manifestFile.existsSync()) {
      warnings.add(
        'AndroidManifest.xml was not found for LaunchTheme verification.',
      );
    } else if (!manifestFile.readAsStringSync().contains(
      '@style/LaunchTheme',
    )) {
      warnings.add(
        'AndroidManifest.xml does not appear to use @style/LaunchTheme.',
      );
    }
  }

  if (platforms.ios) {
    if (iosProjectPath == null) {
      warnings.add('iOS project folder was not found.');
    } else if (!Directory(
      _join(projectRoot.path, 'ios', 'Runner'),
    ).existsSync()) {
      warnings.add('iOS Runner project was not found at ios/Runner.');
    }
  }

  return warnings;
}

NativeLensSplashGenerationResult generateAndroidSplash(
  NativeLensSplashPlan plan, {
  String? timestamp,
  bool simulateFailureAfterFirstWrite = false,
}) {
  if (!plan.platforms.android) {
    throw const NativeLensSplashException('Android splash is not selected.');
  }

  final Directory projectRoot = Directory(plan.projectRoot);
  final Directory androidAppDirectory = Directory(
    _join(projectRoot.path, 'android', 'app'),
  );
  if (!androidAppDirectory.existsSync()) {
    throw const NativeLensSplashException(
      'Android app module was not found at android/app.',
    );
  }

  final List<NativeLensSplashFilePlan> androidFiles = plan.plannedFiles
      .where(
        (NativeLensSplashFilePlan file) =>
            androidGeneratedRelativePaths.contains(file.relativePath),
      )
      .toList(growable: false);

  final Directory backupDirectory = createBackupDirectory(
    projectRoot,
    timestamp: timestamp,
  );
  final List<NativeLensSplashBackupEntry> backupEntries = backupSplashFiles(
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    files: androidFiles,
  );

  final File manifestFile = File(_join(backupDirectory.path, 'manifest.json'));
  writeBackupManifest(
    manifestFile: manifestFile,
    phase: 'android',
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    entries: backupEntries,
  );

  final Map<String, List<int>> binaryWrites = <String, List<int>>{
    'android/app/src/main/res/drawable/native_lens_splash.png': File(
      _join(projectRoot.path, plan.config.imagePath),
    ).readAsBytesSync(),
  };

  final Map<String, String> textWrites = <String, String>{
    'android/app/src/main/res/values/colors.xml': buildAndroidColorsXml(
      existingXml: _readOptionalFile(
        projectRoot,
        'android/app/src/main/res/values/colors.xml',
      ),
      backgroundColor: plan.config.backgroundColor,
    ),
    'android/app/src/main/res/values/styles.xml': buildAndroidStylesXml(
      existingXml: _readOptionalFile(
        projectRoot,
        'android/app/src/main/res/values/styles.xml',
      ),
    ),
    'android/app/src/main/res/values-v31/styles.xml':
        buildAndroidV31StylesXml(),
    'android/app/src/main/res/drawable/launch_background.xml':
        buildAndroidLaunchBackgroundXml(),
    'android/app/src/main/res/drawable-v21/launch_background.xml':
        buildAndroidLaunchBackgroundXml(),
  };

  final List<String> generatedFiles = <String>[];
  try {
    var writeCount = 0;

    for (final MapEntry<String, String> entry in textWrites.entries) {
      _writeTextFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
      writeCount += 1;
      if (simulateFailureAfterFirstWrite && writeCount == 1) {
        throw const NativeLensSplashException(
          'Simulated Android splash generation failure.',
        );
      }
    }

    for (final MapEntry<String, List<int>> entry in binaryWrites.entries) {
      _writeBinaryFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
    }
  } catch (error) {
    restoreBackup(
      projectRoot: projectRoot,
      backupDirectory: backupDirectory,
      entries: backupEntries,
    );
    throw NativeLensSplashException(
      'Android splash generation failed and rollback was completed: $error',
    );
  }

  return NativeLensSplashGenerationResult(
    backupDirectory: backupDirectory.path,
    manifestPath: manifestFile.path,
    generatedFiles: generatedFiles,
    restoredAfterFailure: false,
    warnings: plan.warnings,
  );
}

NativeLensSplashGenerationResult generateIosSplash(
  NativeLensSplashPlan plan, {
  String? timestamp,
  bool simulateFailureAfterFirstWrite = false,
}) {
  if (!plan.platforms.ios) {
    throw const NativeLensSplashException('iOS splash is not selected.');
  }

  final Directory projectRoot = Directory(plan.projectRoot);
  final Directory iosRunnerDirectory = Directory(
    _join(projectRoot.path, 'ios', 'Runner'),
  );
  if (!iosRunnerDirectory.existsSync()) {
    throw const NativeLensSplashException(
      'iOS Runner project was not found at ios/Runner.',
    );
  }

  final List<NativeLensSplashFilePlan> iosFiles = plan.plannedFiles
      .where(
        (NativeLensSplashFilePlan file) =>
            iosPlannedRelativePaths.contains(file.relativePath),
      )
      .toList(growable: false);

  final Directory backupDirectory = createBackupDirectory(
    projectRoot,
    timestamp: timestamp,
  );
  final List<NativeLensSplashBackupEntry> backupEntries = backupSplashFiles(
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    files: iosFiles,
  );

  final File manifestFile = File(_join(backupDirectory.path, 'manifest.json'));
  writeBackupManifest(
    manifestFile: manifestFile,
    phase: 'ios',
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    entries: backupEntries,
  );

  final Map<String, String> textWrites = <String, String>{
    'ios/Runner/Base.lproj/LaunchScreen.storyboard':
        buildIosLaunchScreenStoryboard(
          backgroundColor: plan.config.backgroundColor,
        ),
    'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/Contents.json':
        buildIosContentsJson(),
  };
  final Map<String, List<int>> binaryWrites = <String, List<int>>{
    'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/native_lens_splash.png':
        File(_join(projectRoot.path, plan.config.imagePath)).readAsBytesSync(),
  };

  final List<String> generatedFiles = <String>[];
  try {
    var writeCount = 0;

    for (final MapEntry<String, String> entry in textWrites.entries) {
      _writeTextFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
      writeCount += 1;
      if (simulateFailureAfterFirstWrite && writeCount == 1) {
        throw const NativeLensSplashException(
          'Simulated iOS splash generation failure.',
        );
      }
    }

    for (final MapEntry<String, List<int>> entry in binaryWrites.entries) {
      _writeBinaryFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
    }
  } catch (error) {
    restoreBackup(
      projectRoot: projectRoot,
      backupDirectory: backupDirectory,
      entries: backupEntries,
    );
    throw NativeLensSplashException(
      'iOS splash generation failed and rollback was completed: $error',
    );
  }

  return NativeLensSplashGenerationResult(
    backupDirectory: backupDirectory.path,
    manifestPath: manifestFile.path,
    generatedFiles: generatedFiles,
    restoredAfterFailure: false,
    warnings: plan.warnings,
  );
}

Directory createBackupDirectory(Directory projectRoot, {String? timestamp}) {
  final String baseTimestamp = timestamp ?? _timestamp();
  final Directory backupRoot = Directory(
    _join(projectRoot.path, '.native_lens_backup', 'splash'),
  );

  var suffix = 0;
  while (true) {
    final String directoryName = suffix == 0
        ? baseTimestamp
        : '${baseTimestamp}_$suffix';
    final Directory candidate = Directory(
      _join(backupRoot.path, directoryName),
    );
    if (!candidate.existsSync()) {
      candidate.createSync(recursive: true);
      return candidate;
    }
    suffix += 1;
  }
}

List<NativeLensSplashBackupEntry> backupSplashFiles({
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensSplashFilePlan> files,
}) {
  final List<NativeLensSplashBackupEntry> entries =
      <NativeLensSplashBackupEntry>[];

  for (final NativeLensSplashFilePlan filePlan in files) {
    final File source = File(_join(projectRoot.path, filePlan.relativePath));
    if (source.existsSync()) {
      final File backupFile = File(
        _join(backupDirectory.path, filePlan.relativePath),
      );
      backupFile.parent.createSync(recursive: true);
      source.copySync(backupFile.path);
      entries.add(
        NativeLensSplashBackupEntry(
          relativePath: filePlan.relativePath,
          existed: true,
          backupRelativePath: filePlan.relativePath,
        ),
      );
    } else {
      entries.add(
        NativeLensSplashBackupEntry(
          relativePath: filePlan.relativePath,
          existed: false,
          backupRelativePath: null,
        ),
      );
    }
  }

  return entries;
}

void writeBackupManifest({
  required File manifestFile,
  required String phase,
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensSplashBackupEntry> entries,
}) {
  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'tool': 'native_lens:splash',
      'phase': phase,
      'projectRoot': projectRoot.path,
      'backupDirectory': backupDirectory.path,
      'files': entries
          .map((NativeLensSplashBackupEntry entry) => entry.toJson())
          .toList(growable: false),
    }),
  );
}

void restoreBackup({
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensSplashBackupEntry> entries,
}) {
  for (final NativeLensSplashBackupEntry entry in entries) {
    final File target = File(_join(projectRoot.path, entry.relativePath));
    if (entry.existed) {
      final File backupFile = File(
        _join(backupDirectory.path, entry.backupRelativePath!),
      );
      target.parent.createSync(recursive: true);
      backupFile.copySync(target.path);
    } else if (target.existsSync()) {
      target.deleteSync();
    }
  }
}

String buildAndroidColorsXml({
  required String? existingXml,
  required String backgroundColor,
}) {
  const String colorName = 'native_lens_splash_background';
  final String colorElement =
      '    <color name="$colorName">$backgroundColor</color>';

  if (existingXml == null || existingXml.trim().isEmpty) {
    return '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
$colorElement
</resources>
''';
  }

  final RegExp existingColor = RegExp(
    r'\s*<color\s+name="native_lens_splash_background">[^<]*</color>',
  );
  if (existingColor.hasMatch(existingXml)) {
    return existingXml.replaceFirst(existingColor, '\n$colorElement');
  }

  if (existingXml.contains('</resources>')) {
    return existingXml.replaceFirst(
      '</resources>',
      '$colorElement\n</resources>',
    );
  }

  return '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
$colorElement
</resources>
''';
}

String buildAndroidStylesXml({required String? existingXml}) {
  final String launchTheme = _androidLaunchThemeXml();

  if (existingXml == null || existingXml.trim().isEmpty) {
    return '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
$launchTheme
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''';
  }

  final RegExp existingLaunchTheme = RegExp(
    r'\s*<style\s+name="LaunchTheme"[\s\S]*?</style>',
    multiLine: true,
  );
  if (existingLaunchTheme.hasMatch(existingXml)) {
    return existingXml.replaceFirst(existingLaunchTheme, '\n$launchTheme');
  }

  if (existingXml.contains('</resources>')) {
    return existingXml.replaceFirst(
      '</resources>',
      '$launchTheme\n</resources>',
    );
  }

  return '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
$launchTheme
</resources>
''';
}

String buildAndroidV31StylesXml() {
  return '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@color/native_lens_splash_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@drawable/native_lens_splash</item>
    </style>
</resources>
''';
}

String buildAndroidLaunchBackgroundXml() {
  return '''
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/native_lens_splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/native_lens_splash" />
    </item>
</layer-list>
''';
}

String buildIosLaunchScreenStoryboard({required String backgroundColor}) {
  final _IosColor color = _parseIosColor(backgroundColor);

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="23504" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="native-lens-launch">
    <device id="retina6_12" orientation="portrait" appearance="light"/>
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="23506"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="native-lens-scene">
            <objects>
                <viewController id="native-lens-launch" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="native-lens-root-view">
                        <rect key="frame" x="0.0" y="0.0" width="393" height="852"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleAspectFit" horizontalHuggingPriority="251" verticalHuggingPriority="251" image="NativeLensSplash" translatesAutoresizingMaskIntoConstraints="NO" id="native-lens-splash-image">
                                <rect key="frame" x="136.5" y="366" width="120" height="120"/>
                                <constraints>
                                    <constraint firstAttribute="width" constant="120" id="native-lens-image-width"/>
                                    <constraint firstAttribute="height" constant="120" id="native-lens-image-height"/>
                                </constraints>
                            </imageView>
                        </subviews>
                        <viewLayoutGuide key="safeArea" id="native-lens-safe-area"/>
                        <color key="backgroundColor" red="${color.red}" green="${color.green}" blue="${color.blue}" alpha="${color.alpha}" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="native-lens-splash-image" firstAttribute="centerX" secondItem="native-lens-root-view" secondAttribute="centerX" id="native-lens-center-x"/>
                            <constraint firstItem="native-lens-splash-image" firstAttribute="centerY" secondItem="native-lens-root-view" secondAttribute="centerY" id="native-lens-center-y"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="native-lens-first-responder" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="0.0" y="0.0"/>
        </scene>
    </scenes>
    <resources>
        <image name="NativeLensSplash" width="120" height="120"/>
    </resources>
</document>
''';
}

String buildIosContentsJson() {
  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'images': <Object>[
      <String, String>{
        'filename': 'native_lens_splash.png',
        'idiom': 'universal',
        'scale': '1x',
      },
    ],
    'info': <String, Object>{'author': 'native_lens', 'version': 1},
  });
}

String _androidLaunchThemeXml() {
  return '''
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>''';
}

class _IosColor {
  const _IosColor({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final String red;
  final String green;
  final String blue;
  final String alpha;
}

_IosColor _parseIosColor(String color) {
  final String hex = color.substring(1);
  final int alpha;
  final int red;
  final int green;
  final int blue;

  if (hex.length == 8) {
    alpha = int.parse(hex.substring(0, 2), radix: 16);
    red = int.parse(hex.substring(2, 4), radix: 16);
    green = int.parse(hex.substring(4, 6), radix: 16);
    blue = int.parse(hex.substring(6, 8), radix: 16);
  } else {
    alpha = 255;
    red = int.parse(hex.substring(0, 2), radix: 16);
    green = int.parse(hex.substring(2, 4), radix: 16);
    blue = int.parse(hex.substring(4, 6), radix: 16);
  }

  return _IosColor(
    red: _formatIosColorValue(red),
    green: _formatIosColorValue(green),
    blue: _formatIosColorValue(blue),
    alpha: _formatIosColorValue(alpha),
  );
}

String _formatIosColorValue(int value) {
  if (value == 0) {
    return '0.0';
  }
  if (value == 255) {
    return '1.0';
  }

  return (value / 255).toStringAsFixed(6);
}

String? _readOptionalFile(Directory projectRoot, String relativePath) {
  final File file = File(_join(projectRoot.path, relativePath));
  if (!file.existsSync()) {
    return null;
  }

  return file.readAsStringSync();
}

void _writeTextFile(
  Directory projectRoot,
  String relativePath,
  String content,
) {
  final File file = File(_join(projectRoot.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _writeBinaryFile(
  Directory projectRoot,
  String relativePath,
  List<int> bytes,
) {
  final File file = File(_join(projectRoot.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

String _join(
  String first,
  String second, [
  String? third,
  String? fourth,
  String? fifth,
  String? sixth,
]) {
  return <String>[
    first,
    second,
    ?third,
    ?fourth,
    ?fifth,
    ?sixth,
  ].join(Platform.pathSeparator);
}

String _timestamp() {
  final DateTime now = DateTime.now().toUtc();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  String threeDigits(int value) => value.toString().padLeft(3, '0');

  return '${now.year}'
      '${twoDigits(now.month)}'
      '${twoDigits(now.day)}_'
      '${twoDigits(now.hour)}'
      '${twoDigits(now.minute)}'
      '${twoDigits(now.second)}_'
      '${threeDigits(now.millisecond)}';
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

  for (final NativeLensSplashFilePlan file in plan.plannedFiles) {
    lines.add(
      '  - ${file.relativePath} (${file.action}, '
      '${file.willBackup ? 'backup enabled' : 'no backup yet'})',
    );
  }

  if (plan.warnings.isNotEmpty) {
    lines.add('');
    lines.add('Warnings:');
    for (final String warning in plan.warnings) {
      lines.add('  - $warning');
    }
  }

  lines.add('');
  if (dryRun) {
    lines.add('No Android or iOS files were modified.');
  } else {
    lines.add(
      'Selected native splash files will be generated after this preview.',
    );
  }

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
