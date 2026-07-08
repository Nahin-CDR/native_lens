import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:native_lens/src/backup.dart';
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

typedef NativeLensSplashBackupEntry = NativeLensBackupEntry;

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

const List<String> _androidLauncherIconRelativePaths = <String>[
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
];

const String _iosMarketingIconRelativePath =
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
    'Icon-App-1024x1024@1x.png';

// SHA-256 hashes for stock Flutter template launcher icons. These are used
// only to warn when a project still appears to use Flutter's default branding.
const Set<String> _stockFlutterAndroidLauncherIconSha256 = <String>{
  // mipmap-mdpi/ic_launcher.png
  'c7c0c0189145e4e32a401c61c9bdc615754b0264e7afae24e834bb81049eaf81',
  // mipmap-hdpi/ic_launcher.png
  '6a7c8f0d703e3682108f9662f813302236240d3f8f638bb391e32bfb96055fef',
  // mipmap-xhdpi/ic_launcher.png
  'e14aa40904929bf313fded22cf7e7ffcbf1d1aac4263b5ef1be8bfce650397aa',
  // mipmap-xxhdpi/ic_launcher.png
  '4d470bf22d5c17d84edc5f82516d1ba8a1c09559cd761cefb792f86d9f52b540',
  // mipmap-xxxhdpi/ic_launcher.png
  '3c34e1f298d0c9ea3455d46db6b7759c8211a49e9ec6e44b635fc5c87dfb4180',
};

// SHA-256 hash for Flutter's stock iOS AppIcon marketing image.
const Set<String> _stockFlutterIosMarketingIconSha256 = <String>{
  '7770183009e914112de7d8ef1d235a6a30c5834424858e0d2f8253f6b8d31926',
};

const String _defaultAndroidLauncherIconWarning =
    'Your Android launcher icon still appears to be the default Flutter '
    'template icon. Some OEMs, including Samsung One UI, may fall back to '
    'showing the launcher icon instead of your custom splash icon on Android '
    "12+. Run 'dart run native_lens:icon' or otherwise customize your "
    'launcher icon to avoid a mismatched splash.';

const String _defaultIosAppIconWarning =
    'Your iOS AppIcon still appears to be the default Flutter template icon. '
    "Run 'dart run native_lens:icon' or otherwise customize your AppIcon so "
    'launcher and splash branding stay consistent.';

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

    if (_usesDefaultFlutterAndroidLauncherIcon(projectRoot)) {
      warnings.add(_defaultAndroidLauncherIconWarning);
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

    if (_usesDefaultFlutterIosAppIcon(projectRoot)) {
      warnings.add(_defaultIosAppIconWarning);
    }
  }

  return warnings;
}

bool _usesDefaultFlutterAndroidLauncherIcon(Directory projectRoot) {
  for (final String relativePath in _androidLauncherIconRelativePaths) {
    final File iconFile = File(_join(projectRoot.path, relativePath));
    if (!iconFile.existsSync()) {
      continue;
    }

    return _stockFlutterAndroidLauncherIconSha256.contains(
      _sha256File(iconFile),
    );
  }

  return false;
}

bool _usesDefaultFlutterIosAppIcon(Directory projectRoot) {
  final File iconFile = File(
    _join(projectRoot.path, _iosMarketingIconRelativePath),
  );
  if (!iconFile.existsSync()) {
    return false;
  }

  return _stockFlutterIosMarketingIconSha256.contains(_sha256File(iconFile));
}

String _sha256File(File file) {
  return sha256.convert(file.readAsBytesSync()).toString();
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
  final List<NativeLensBackupEntry> backupEntries = backupSplashFiles(
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
    restoreNativeLensBackup(
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
  final List<NativeLensBackupEntry> backupEntries = backupSplashFiles(
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
    restoreNativeLensBackup(
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
  return createNativeLensBackupDirectory(
    projectRoot: projectRoot,
    toolName: 'splash',
    timestamp: DateTime.now().toUtc(),
    timestampName: timestamp,
  );
}

List<NativeLensBackupEntry> backupSplashFiles({
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensSplashFilePlan> files,
}) {
  return backupNativeLensFiles(
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    relativePaths: files.map(
      (NativeLensSplashFilePlan filePlan) => filePlan.relativePath,
    ),
  );
}

void writeBackupManifest({
  required File manifestFile,
  required String phase,
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensBackupEntry> entries,
}) {
  writeNativeLensBackupManifest(
    manifestFile: manifestFile,
    tool: 'native_lens:splash',
    phase: phase,
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    entries: entries,
  );
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
