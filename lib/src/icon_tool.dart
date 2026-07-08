import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:image/image.dart' as image;
import 'package:native_lens/src/backup.dart';
import 'package:yaml/yaml.dart';

class NativeLensIconException implements Exception {
  const NativeLensIconException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NativeLensIconConfig {
  const NativeLensIconConfig({
    required this.imagePath,
    required this.adaptiveBackground,
    required this.adaptiveForegroundPath,
    required this.monochromePath,
    required this.removeAlphaIos,
    required this.android,
    required this.ios,
  });

  final String imagePath;
  final String? adaptiveBackground;
  final String? adaptiveForegroundPath;
  final String? monochromePath;
  final bool removeAlphaIos;
  final bool android;
  final bool ios;
}

class NativeLensIconPlatformSelection {
  const NativeLensIconPlatformSelection({
    required this.android,
    required this.ios,
  });

  final bool android;
  final bool ios;

  bool get hasAnyPlatform => android || ios;
}

class NativeLensIconPlan {
  const NativeLensIconPlan({
    required this.projectRoot,
    required this.pubspecPath,
    required this.config,
    required this.platforms,
    required this.androidProjectPath,
    required this.iosProjectPath,
    required this.sourceImage,
    required this.adaptiveForegroundImage,
    required this.adaptiveBackgroundImage,
    required this.monochromeImage,
    required this.plannedFiles,
    required this.warnings,
  });

  final String projectRoot;
  final String pubspecPath;
  final NativeLensIconConfig config;
  final NativeLensIconPlatformSelection platforms;
  final String? androidProjectPath;
  final String? iosProjectPath;
  final NativeLensIconImageMetadata sourceImage;
  final NativeLensIconImageMetadata? adaptiveForegroundImage;
  final NativeLensIconImageMetadata? adaptiveBackgroundImage;
  final NativeLensIconImageMetadata? monochromeImage;
  final List<NativeLensIconFilePlan> plannedFiles;
  final List<String> warnings;
}

class NativeLensIconFilePlan {
  const NativeLensIconFilePlan({
    required this.relativePath,
    required this.action,
    required this.willBackup,
  });

  final String relativePath;
  final String action;
  final bool willBackup;
}

class NativeLensIconImageMetadata {
  const NativeLensIconImageMetadata({
    required this.relativePath,
    required this.width,
    required this.height,
    required this.hasTransparentPixels,
  });

  final String relativePath;
  final int width;
  final int height;
  final bool hasTransparentPixels;

  String get dimensions => '${width}x$height';
}

class NativeLensIconImageValidation {
  const NativeLensIconImageValidation({
    required this.sourceImage,
    required this.adaptiveForegroundImage,
    required this.adaptiveBackgroundImage,
    required this.monochromeImage,
    required this.warnings,
  });

  final NativeLensIconImageMetadata sourceImage;
  final NativeLensIconImageMetadata? adaptiveForegroundImage;
  final NativeLensIconImageMetadata? adaptiveBackgroundImage;
  final NativeLensIconImageMetadata? monochromeImage;
  final List<String> warnings;
}

class NativeLensIconGenerationResult {
  const NativeLensIconGenerationResult({
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

typedef StdoutWriter = void Function(String message);

const List<String> androidBaseIconRelativePaths = <String>[
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
];

const List<String> androidAdaptiveIconRelativePaths = <String>[
  'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
  'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
];

const String androidColorsRelativePath =
    'android/app/src/main/res/values/colors.xml';

const String androidAdaptiveBackgroundImageRelativePath =
    'android/app/src/main/res/drawable/ic_launcher_background.png';

const String androidMonochromeIconRelativePath =
    'android/app/src/main/res/drawable/ic_launcher_monochrome.png';

const List<String> iosIconRelativePaths = <String>[
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
];

Future<int> runNativeLensIcon(
  List<String> arguments, {
  Directory? workingDirectory,
  StdoutWriter? stdoutWriter,
  StdoutWriter? stderrWriter,
}) async {
  final ArgParser parser = buildIconArgParser();
  final StdoutWriter out = stdoutWriter ?? stdout.writeln;
  final StdoutWriter err = stderrWriter ?? stderr.writeln;

  try {
    final ArgResults results = parser.parse(arguments);

    if (results['help'] as bool) {
      out(buildIconUsage(parser));
      return 0;
    }

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: workingDirectory ?? Directory.current,
      androidOnly: results['android'] as bool,
      iosOnly: results['ios'] as bool,
    );

    final bool dryRun = results['dry-run'] as bool;
    out(formatIconPlan(plan, dryRun: dryRun));

    if (!dryRun) {
      out('');
      if (plan.platforms.android) {
        final NativeLensIconGenerationResult result = generateAndroidIcons(
          plan,
        );
        out('Android native icon files generated.');
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
        final NativeLensIconGenerationResult result = generateIosIcons(plan);
        out('iOS native icon files generated.');
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
    err('NativeLens icon setup error: ${error.message}');
    err('');
    err(buildIconUsage(parser));
    return 64;
  } on NativeLensIconException catch (error) {
    err('NativeLens icon setup error: ${error.message}');
    return 1;
  }
}

ArgParser buildIconArgParser() {
  return ArgParser()
    ..addFlag(
      'dry-run',
      help: 'Preview the native icon plan without modifying files.',
      negatable: false,
    )
    ..addFlag(
      'android',
      help: 'Plan Android native icon changes only.',
      negatable: false,
    )
    ..addFlag(
      'ios',
      help: 'Plan iOS native icon changes only.',
      negatable: false,
    )
    ..addFlag('help', abbr: 'h', help: 'Show usage.', negatable: false);
}

String buildIconUsage(ArgParser parser) {
  return [
    'NativeLens native icon setup preview',
    '',
    'Usage: dart run native_lens:icon [options]',
    '',
    parser.usage,
  ].join('\n');
}

NativeLensIconPlan buildIconPlan({
  required Directory workingDirectory,
  bool androidOnly = false,
  bool iosOnly = false,
}) {
  final File pubspecFile = findNearestPubspec(workingDirectory);
  final Directory projectRoot = pubspecFile.parent;
  final NativeLensIconConfig config = parseIconConfig(pubspecFile);
  final NativeLensIconPlatformSelection platforms = resolveIconPlatforms(
    config,
    androidOnly: androidOnly,
    iosOnly: iosOnly,
  );

  if (!platforms.hasAnyPlatform) {
    throw const NativeLensIconException(
      'No icon platforms are enabled. Enable android or ios in '
      'native_lens.icon.',
    );
  }

  final String? androidProjectPath = platforms.android
      ? detectAndroidProjectPath(projectRoot)
      : null;
  final String? iosProjectPath = platforms.ios
      ? detectIosProjectPath(projectRoot)
      : null;

  final List<NativeLensIconFilePlan> plannedFiles = buildIconPlannedFiles(
    platforms: platforms,
    config: config,
    projectRoot: projectRoot,
  );
  final NativeLensIconImageValidation imageValidation = validateIconImages(
    projectRoot: projectRoot,
    config: config,
    platforms: platforms,
  );
  validateIconConfigForPlatforms(config: config, platforms: platforms);
  final List<String> warnings = <String>[
    ...buildIconPlanWarnings(
      platforms: platforms,
      projectRoot: projectRoot,
      androidProjectPath: androidProjectPath,
      iosProjectPath: iosProjectPath,
    ),
    ...imageValidation.warnings,
  ];

  return NativeLensIconPlan(
    projectRoot: projectRoot.path,
    pubspecPath: pubspecFile.path,
    config: config,
    platforms: platforms,
    androidProjectPath: androidProjectPath,
    iosProjectPath: iosProjectPath,
    sourceImage: imageValidation.sourceImage,
    adaptiveForegroundImage: imageValidation.adaptiveForegroundImage,
    adaptiveBackgroundImage: imageValidation.adaptiveBackgroundImage,
    monochromeImage: imageValidation.monochromeImage,
    plannedFiles: plannedFiles,
    warnings: warnings,
  );
}

void validateIconConfigForPlatforms({
  required NativeLensIconConfig config,
  required NativeLensIconPlatformSelection platforms,
}) {
  if (platforms.android && config.adaptiveBackground == null) {
    throw const NativeLensIconException(
      'native_lens.icon.adaptive_background is required when Android icon '
      'generation is enabled.',
    );
  }
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
      throw NativeLensIconException(
        'Could not find pubspec.yaml from ${startDirectory.path}. '
        'Run this command inside a Flutter project.',
      );
    }

    current = parent;
  }
}

NativeLensIconConfig parseIconConfig(File pubspecFile) {
  final Object? document = loadYaml(pubspecFile.readAsStringSync());

  if (document is! YamlMap) {
    throw const NativeLensIconException(
      'pubspec.yaml must contain a YAML map.',
    );
  }

  final Object? nativeLens = document['native_lens'];
  if (nativeLens is! YamlMap) {
    throw const NativeLensIconException(
      'Missing native_lens config in pubspec.yaml.',
    );
  }

  final Object? icon = nativeLens['icon'];
  if (icon is! YamlMap) {
    throw const NativeLensIconException(
      'Missing native_lens.icon config in pubspec.yaml.',
    );
  }

  final Object? imagePath = icon['image'];
  if (imagePath is! String || imagePath.trim().isEmpty) {
    throw const NativeLensIconException(
      'native_lens.icon.image must be a non-empty file path.',
    );
  }

  final Object? adaptiveBackground = icon['adaptive_background'];
  if (adaptiveBackground != null) {
    if (adaptiveBackground is! String || adaptiveBackground.trim().isEmpty) {
      throw const NativeLensIconException(
        'native_lens.icon.adaptive_background must be #RRGGBB or #AARRGGBB, '
        'or an image file path.',
      );
    }
    if (!_isValidColor(adaptiveBackground) &&
        !_isLikelyImagePath(adaptiveBackground)) {
      throw const NativeLensIconException(
        'native_lens.icon.adaptive_background must be #RRGGBB or #AARRGGBB, '
        'or an image file path.',
      );
    }
  }

  final String? adaptiveForegroundPath = _readOptionalPath(
    icon,
    'adaptive_foreground',
  );
  final String? monochromePath = _readOptionalPath(icon, 'monochrome');

  return NativeLensIconConfig(
    imagePath: imagePath,
    adaptiveBackground: adaptiveBackground as String?,
    adaptiveForegroundPath: adaptiveForegroundPath,
    monochromePath: monochromePath,
    removeAlphaIos: _readOptionalBool(
      icon,
      'remove_alpha_ios',
      defaultValue: true,
    ),
    android: _readOptionalBool(icon, 'android', defaultValue: true),
    ios: _readOptionalBool(icon, 'ios', defaultValue: true),
  );
}

NativeLensIconImageValidation validateIconImages({
  required Directory projectRoot,
  required NativeLensIconConfig config,
  required NativeLensIconPlatformSelection platforms,
}) {
  final List<String> warnings = <String>[];
  final NativeLensIconImageMetadata sourceImage = _decodeImageMetadata(
    projectRoot: projectRoot,
    relativePath: config.imagePath,
    label: 'Icon image',
  );
  if (sourceImage.width != sourceImage.height) {
    warnings.add(
      'Source icon is not square (${sourceImage.dimensions}). NativeLens will '
      'center-crop/fit during generation in a future step.',
    );
  }
  if (platforms.ios &&
      !config.removeAlphaIos &&
      sourceImage.hasTransparentPixels) {
    warnings.add(
      'remove_alpha_ios is false and the source icon has transparent pixels. '
      'iOS App Store icons may be rejected if alpha remains.',
    );
  }

  NativeLensIconImageMetadata? adaptiveForegroundImage;
  if (platforms.android && config.adaptiveForegroundPath != null) {
    adaptiveForegroundImage = _decodeImageMetadata(
      projectRoot: projectRoot,
      relativePath: config.adaptiveForegroundPath!,
      label: 'Adaptive foreground image',
    );
    if (!adaptiveForegroundImage.hasTransparentPixels) {
      warnings.add(
        'adaptive_foreground appears fully opaque. Adaptive foregrounds should '
        'be transparent PNG glyph layers; otherwise Android adaptive icons may '
        'look wrong.',
      );
    }
  }

  NativeLensIconImageMetadata? adaptiveBackgroundImage;
  final String? adaptiveBackground = config.adaptiveBackground;
  if (adaptiveBackground != null && !_isValidColor(adaptiveBackground)) {
    adaptiveBackgroundImage = _decodeImageMetadata(
      projectRoot: projectRoot,
      relativePath: adaptiveBackground,
      label: 'Adaptive background image',
    );
  }

  NativeLensIconImageMetadata? monochromeImage;
  if (config.monochromePath != null) {
    monochromeImage = _decodeImageMetadata(
      projectRoot: projectRoot,
      relativePath: config.monochromePath!,
      label: 'Monochrome icon image',
    );
  }

  return NativeLensIconImageValidation(
    sourceImage: sourceImage,
    adaptiveForegroundImage: adaptiveForegroundImage,
    adaptiveBackgroundImage: adaptiveBackgroundImage,
    monochromeImage: monochromeImage,
    warnings: warnings,
  );
}

NativeLensIconPlatformSelection resolveIconPlatforms(
  NativeLensIconConfig config, {
  required bool androidOnly,
  required bool iosOnly,
}) {
  final bool hasPlatformFlag = androidOnly || iosOnly;
  final bool android = hasPlatformFlag ? androidOnly : config.android;
  final bool ios = hasPlatformFlag ? iosOnly : config.ios;

  if (android && !config.android) {
    throw const NativeLensIconException(
      'Android icon is disabled in native_lens.icon.android.',
    );
  }

  if (ios && !config.ios) {
    throw const NativeLensIconException(
      'iOS icon is disabled in native_lens.icon.ios.',
    );
  }

  return NativeLensIconPlatformSelection(android: android, ios: ios);
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

List<NativeLensIconFilePlan> buildIconPlannedFiles({
  required NativeLensIconPlatformSelection platforms,
  required NativeLensIconConfig config,
  required Directory projectRoot,
}) {
  final List<NativeLensIconFilePlan> files = <NativeLensIconFilePlan>[];

  if (platforms.android) {
    final List<String> androidPaths = <String>[
      ...androidBaseIconRelativePaths,
      ...androidAdaptiveIconRelativePaths,
      if (_usesAdaptiveBackgroundImage(config))
        androidAdaptiveBackgroundImageRelativePath
      else
        androidColorsRelativePath,
      if (config.monochromePath != null) androidMonochromeIconRelativePath,
    ];

    for (final String relativePath in androidPaths) {
      files.add(_buildIconFilePlan(projectRoot, relativePath));
    }
  }

  if (platforms.ios) {
    for (final String relativePath in iosIconRelativePaths) {
      files.add(_buildIconFilePlan(projectRoot, relativePath));
    }
  }

  return files;
}

List<String> buildIconPlanWarnings({
  required NativeLensIconPlatformSelection platforms,
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
      warnings.add('AndroidManifest.xml was not found for icon verification.');
    } else if (!manifestFile.readAsStringSync().contains(
      '@mipmap/ic_launcher',
    )) {
      warnings.add(
        'AndroidManifest.xml does not appear to use @mipmap/ic_launcher.',
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

    if (!Directory(
      _join(
        projectRoot.path,
        'ios',
        'Runner',
        'Assets.xcassets',
        'AppIcon.appiconset',
      ),
    ).existsSync()) {
      warnings.add('iOS AppIcon.appiconset was not found.');
    }
  }

  return warnings;
}

NativeLensIconGenerationResult generateAndroidIcons(
  NativeLensIconPlan plan, {
  String? timestamp,
  bool simulateFailureAfterFirstWrite = false,
}) {
  if (!plan.platforms.android) {
    throw const NativeLensIconException('Android icon is not selected.');
  }

  final Directory projectRoot = Directory(plan.projectRoot);
  final Directory androidAppDirectory = Directory(
    _join(projectRoot.path, 'android', 'app'),
  );
  if (!androidAppDirectory.existsSync()) {
    throw const NativeLensIconException(
      'Android app module was not found at android/app.',
    );
  }

  final List<NativeLensIconFilePlan> androidFiles = plan.plannedFiles
      .where((NativeLensIconFilePlan file) => _isAndroidPath(file.relativePath))
      .toList(growable: false);

  final Directory backupDirectory = createNativeLensBackupDirectory(
    projectRoot: projectRoot,
    toolName: 'icon',
    timestamp: DateTime.now().toUtc(),
    timestampName: timestamp,
  );
  final List<NativeLensBackupEntry> backupEntries = backupNativeLensFiles(
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    relativePaths: androidFiles.map(
      (NativeLensIconFilePlan file) => file.relativePath,
    ),
  );

  final File manifestFile = File(
    _joinRelative(backupDirectory.path, 'manifest.json'),
  );
  writeNativeLensBackupManifest(
    manifestFile: manifestFile,
    tool: 'native_lens:icon',
    phase: 'android',
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    entries: backupEntries,
  );

  final Map<String, List<int>> binaryWrites = _buildAndroidIconBinaryWrites(
    projectRoot: projectRoot,
    config: plan.config,
  );
  final Map<String, String> textWrites = _buildAndroidIconTextWrites(
    projectRoot: projectRoot,
    config: plan.config,
  );

  final List<String> generatedFiles = <String>[];
  try {
    var writeCount = 0;

    for (final MapEntry<String, String> entry in textWrites.entries) {
      _writeTextFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
      writeCount += 1;
      if (simulateFailureAfterFirstWrite && writeCount == 1) {
        throw const NativeLensIconException(
          'Simulated Android icon generation failure.',
        );
      }
    }

    for (final MapEntry<String, List<int>> entry in binaryWrites.entries) {
      _writeBinaryFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
      writeCount += 1;
      if (simulateFailureAfterFirstWrite && writeCount == 1) {
        throw const NativeLensIconException(
          'Simulated Android icon generation failure.',
        );
      }
    }
  } catch (error) {
    restoreNativeLensBackup(
      projectRoot: projectRoot,
      backupDirectory: backupDirectory,
      entries: backupEntries,
    );
    throw NativeLensIconException(
      'Android icon generation failed and rollback was completed: $error',
    );
  }

  return NativeLensIconGenerationResult(
    backupDirectory: backupDirectory.path,
    manifestPath: manifestFile.path,
    generatedFiles: generatedFiles,
    restoredAfterFailure: false,
    warnings: plan.warnings,
  );
}

NativeLensIconGenerationResult generateIosIcons(
  NativeLensIconPlan plan, {
  String? timestamp,
  bool simulateFailureAfterFirstWrite = false,
}) {
  if (!plan.platforms.ios) {
    throw const NativeLensIconException('iOS icon is not selected.');
  }

  final Directory projectRoot = Directory(plan.projectRoot);
  final Directory iosRunnerDirectory = Directory(
    _join(projectRoot.path, 'ios', 'Runner'),
  );
  if (!iosRunnerDirectory.existsSync()) {
    throw const NativeLensIconException(
      'iOS Runner project was not found at ios/Runner.',
    );
  }

  final List<NativeLensIconFilePlan> iosFiles = plan.plannedFiles
      .where((NativeLensIconFilePlan file) => _isIosPath(file.relativePath))
      .toList(growable: false);

  final Directory backupDirectory = createNativeLensBackupDirectory(
    projectRoot: projectRoot,
    toolName: 'icon',
    timestamp: DateTime.now().toUtc(),
    timestampName: timestamp,
  );
  final List<NativeLensBackupEntry> backupEntries = backupNativeLensFiles(
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    relativePaths: iosFiles.map(
      (NativeLensIconFilePlan file) => file.relativePath,
    ),
  );

  final File manifestFile = File(
    _joinRelative(backupDirectory.path, 'manifest.json'),
  );
  writeNativeLensBackupManifest(
    manifestFile: manifestFile,
    tool: 'native_lens:icon',
    phase: 'ios',
    projectRoot: projectRoot,
    backupDirectory: backupDirectory,
    entries: backupEntries,
  );

  final Map<String, String> textWrites = <String, String>{
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json':
        buildIosAppIconContentsJson(),
  };
  final Map<String, List<int>> binaryWrites = _buildIosIconBinaryWrites(
    projectRoot: projectRoot,
    config: plan.config,
  );

  final List<String> generatedFiles = <String>[];
  try {
    var writeCount = 0;

    for (final MapEntry<String, String> entry in textWrites.entries) {
      _writeTextFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
      writeCount += 1;
      if (simulateFailureAfterFirstWrite && writeCount == 1) {
        throw const NativeLensIconException(
          'Simulated iOS icon generation failure.',
        );
      }
    }

    for (final MapEntry<String, List<int>> entry in binaryWrites.entries) {
      _writeBinaryFile(projectRoot, entry.key, entry.value);
      generatedFiles.add(entry.key);
      writeCount += 1;
      if (simulateFailureAfterFirstWrite && writeCount == 1) {
        throw const NativeLensIconException(
          'Simulated iOS icon generation failure.',
        );
      }
    }
  } catch (error) {
    restoreNativeLensBackup(
      projectRoot: projectRoot,
      backupDirectory: backupDirectory,
      entries: backupEntries,
    );
    throw NativeLensIconException(
      'iOS icon generation failed and rollback was completed: $error',
    );
  }

  return NativeLensIconGenerationResult(
    backupDirectory: backupDirectory.path,
    manifestPath: manifestFile.path,
    generatedFiles: generatedFiles,
    restoredAfterFailure: false,
    warnings: plan.warnings,
  );
}

String formatIconPlan(NativeLensIconPlan plan, {required bool dryRun}) {
  final List<String> lines = <String>[
    dryRun
        ? 'NativeLens native icon dry run'
        : 'NativeLens native icon setup preview',
    '',
    'Project root: ${plan.projectRoot}',
    'Pubspec: ${plan.pubspecPath}',
    '',
    'Config:',
    '  image: ${plan.config.imagePath}',
    '  adaptive_background: ${plan.config.adaptiveBackground ?? 'not set'}',
    '  adaptive_foreground: '
        '${plan.config.adaptiveForegroundPath ?? 'not set'}',
    '  monochrome: ${plan.config.monochromePath ?? 'not set'}',
    '  remove_alpha_ios: ${plan.config.removeAlphaIos}',
    '  android: ${plan.config.android}',
    '  ios: ${plan.config.ios}',
    '',
    'Image metadata:',
    '  source image: ${plan.sourceImage.dimensions} '
        '(${plan.sourceImage.relativePath})',
    if (plan.adaptiveForegroundImage != null)
      '  adaptive foreground: '
          '${plan.adaptiveForegroundImage!.dimensions} '
          '(${plan.adaptiveForegroundImage!.relativePath})',
    if (plan.adaptiveBackgroundImage != null)
      '  adaptive background image: '
          '${plan.adaptiveBackgroundImage!.dimensions} '
          '(${plan.adaptiveBackgroundImage!.relativePath})',
    if (plan.monochromeImage != null)
      '  monochrome: ${plan.monochromeImage!.dimensions} '
          '(${plan.monochromeImage!.relativePath})',
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

  for (final NativeLensIconFilePlan file in plan.plannedFiles) {
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
  } else if (plan.platforms.android || plan.platforms.ios) {
    lines.add(
      'Selected native icon files will be generated after this preview.',
    );
  }

  return lines.join('\n');
}

NativeLensIconFilePlan _buildIconFilePlan(
  Directory projectRoot,
  String relativePath,
) {
  return NativeLensIconFilePlan(
    relativePath: relativePath,
    action: File(_joinRelative(projectRoot.path, relativePath)).existsSync()
        ? 'modify'
        : 'create',
    willBackup: true,
  );
}

String? _readOptionalPath(YamlMap map, String key) {
  final Object? value = map[key];
  if (value == null) {
    return null;
  }

  if (value is! String || value.trim().isEmpty) {
    throw NativeLensIconException(
      'native_lens.icon.$key must be a non-empty file path.',
    );
  }
  return value;
}

NativeLensIconImageMetadata _decodeImageMetadata({
  required Directory projectRoot,
  required String relativePath,
  required String label,
}) {
  final File imageFile = File(_joinRelative(projectRoot.path, relativePath));
  if (!imageFile.existsSync()) {
    throw NativeLensIconException('$label does not exist: $relativePath');
  }

  final Uint8List bytes;
  try {
    bytes = imageFile.readAsBytesSync();
  } on FileSystemException catch (error) {
    throw NativeLensIconException(
      'Could not read $label: $relativePath (${error.message})',
    );
  }

  final image.Image? decodedImage;
  try {
    decodedImage = image.decodeImage(bytes);
  } catch (_) {
    throw NativeLensIconException(
      'Could not decode $label: $relativePath. Use a PNG source image when '
      'possible.',
    );
  }
  if (decodedImage == null) {
    throw NativeLensIconException(
      'Could not decode $label: $relativePath. Use a PNG source image when '
      'possible.',
    );
  }

  return NativeLensIconImageMetadata(
    relativePath: relativePath,
    width: decodedImage.width,
    height: decodedImage.height,
    hasTransparentPixels: _hasTransparentPixels(decodedImage),
  );
}

bool _hasTransparentPixels(image.Image decodedImage) {
  if (!decodedImage.hasAlpha) {
    return false;
  }

  for (final image.Pixel pixel in decodedImage) {
    if (pixel.a < pixel.maxChannelValue) {
      return true;
    }
  }
  return false;
}

Map<String, String> _buildAndroidIconTextWrites({
  required Directory projectRoot,
  required NativeLensIconConfig config,
}) {
  final Map<String, String> textWrites = <String, String>{
    'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml':
        buildAndroidAdaptiveIconXml(
          backgroundDrawable: _usesAdaptiveBackgroundImage(config)
              ? '@drawable/ic_launcher_background'
              : '@color/ic_launcher_background',
          includeMonochrome: config.monochromePath != null,
        ),
  };

  if (!_usesAdaptiveBackgroundImage(config)) {
    textWrites[androidColorsRelativePath] = buildAndroidIconColorsXml(
      existingXml: _readOptionalFile(projectRoot, androidColorsRelativePath),
      backgroundColor: config.adaptiveBackground!,
    );
  }

  return textWrites;
}

Map<String, List<int>> _buildAndroidIconBinaryWrites({
  required Directory projectRoot,
  required NativeLensIconConfig config,
}) {
  final image.Image sourceImage = _decodeProjectImage(
    projectRoot: projectRoot,
    relativePath: config.imagePath,
    label: 'Icon image',
  );
  final image.Image adaptiveForegroundImage = _decodeProjectImage(
    projectRoot: projectRoot,
    relativePath: config.adaptiveForegroundPath ?? config.imagePath,
    label: config.adaptiveForegroundPath == null
        ? 'Icon image'
        : 'Adaptive foreground image',
  );
  final Map<String, List<int>> binaryWrites = <String, List<int>>{};

  const Map<String, int> legacySizes = <String, int>{
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };
  for (final MapEntry<String, int> entry in legacySizes.entries) {
    binaryWrites[entry.key] = _encodeSquarePng(sourceImage, entry.value);
  }

  const Map<String, int> foregroundSizes = <String, int>{
    'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png': 108,
    'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png': 162,
    'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png': 216,
    'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png': 324,
    'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png': 432,
  };
  for (final MapEntry<String, int> entry in foregroundSizes.entries) {
    binaryWrites[entry.key] = _encodeSquarePng(
      adaptiveForegroundImage,
      entry.value,
    );
  }

  if (_usesAdaptiveBackgroundImage(config)) {
    final image.Image backgroundImage = _decodeProjectImage(
      projectRoot: projectRoot,
      relativePath: config.adaptiveBackground!,
      label: 'Adaptive background image',
    );
    binaryWrites[androidAdaptiveBackgroundImageRelativePath] = _encodeSquarePng(
      backgroundImage,
      432,
    );
  }

  if (config.monochromePath != null) {
    final image.Image monochromeImage = _decodeProjectImage(
      projectRoot: projectRoot,
      relativePath: config.monochromePath!,
      label: 'Monochrome icon image',
    );
    binaryWrites[androidMonochromeIconRelativePath] = _encodeSquarePng(
      monochromeImage,
      432,
    );
  }

  return binaryWrites;
}

Map<String, List<int>> _buildIosIconBinaryWrites({
  required Directory projectRoot,
  required NativeLensIconConfig config,
}) {
  final image.Image sourceImage = _decodeProjectImage(
    projectRoot: projectRoot,
    relativePath: config.imagePath,
    label: 'Icon image',
  );
  final Map<String, List<int>> binaryWrites = <String, List<int>>{};

  for (final _IosIconSpec spec in _iosIconSpecs) {
    binaryWrites['ios/Runner/Assets.xcassets/AppIcon.appiconset/${spec.filename}'] =
        _encodeSquarePng(
          sourceImage,
          spec.pixels,
          flattenAlpha: config.removeAlphaIos,
        );
  }

  return binaryWrites;
}

String buildAndroidAdaptiveIconXml({
  required String backgroundDrawable,
  required bool includeMonochrome,
}) {
  return '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="$backgroundDrawable"/>
    <foreground>
        <inset android:drawable="@drawable/ic_launcher_foreground" android:inset="16%"/>
    </foreground>
${includeMonochrome ? '    <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>\n' : ''}</adaptive-icon>
''';
}

String buildAndroidIconColorsXml({
  required String? existingXml,
  required String backgroundColor,
}) {
  const String colorName = 'ic_launcher_background';
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
    r'\s*<color\s+name="ic_launcher_background">[^<]*</color>',
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

String? _readOptionalFile(Directory projectRoot, String relativePath) {
  final File file = File(_joinRelative(projectRoot.path, relativePath));
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
  final File file = File(_joinRelative(projectRoot.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _writeBinaryFile(
  Directory projectRoot,
  String relativePath,
  List<int> bytes,
) {
  final File file = File(_joinRelative(projectRoot.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

List<int> _encodeSquarePng(
  image.Image sourceImage,
  int size, {
  bool flattenAlpha = false,
}) {
  final int cropSize = sourceImage.width < sourceImage.height
      ? sourceImage.width
      : sourceImage.height;
  final int cropX = ((sourceImage.width - cropSize) / 2).floor();
  final int cropY = ((sourceImage.height - cropSize) / 2).floor();
  final image.Image croppedImage = image.copyCrop(
    sourceImage,
    x: cropX,
    y: cropY,
    width: cropSize,
    height: cropSize,
  );
  final image.Image resizedImage = image.copyResize(
    croppedImage,
    width: size,
    height: size,
    interpolation: image.Interpolation.average,
  );
  return image.encodePng(
    flattenAlpha ? _flattenAlphaOnWhite(resizedImage) : resizedImage,
  );
}

image.Image _flattenAlphaOnWhite(image.Image sourceImage) {
  final image.Image flattenedImage = image.Image(
    width: sourceImage.width,
    height: sourceImage.height,
    numChannels: 3,
  );

  for (var y = 0; y < sourceImage.height; y += 1) {
    for (var x = 0; x < sourceImage.width; x += 1) {
      final image.Pixel pixel = sourceImage.getPixel(x, y);
      final double alpha = pixel.maxChannelValue == 0
          ? 1
          : (pixel.a / pixel.maxChannelValue).clamp(0, 1).toDouble();
      final int red = ((pixel.r * alpha) + (255 * (1 - alpha))).round();
      final int green = ((pixel.g * alpha) + (255 * (1 - alpha))).round();
      final int blue = ((pixel.b * alpha) + (255 * (1 - alpha))).round();
      flattenedImage.setPixelRgb(x, y, red, green, blue);
    }
  }

  return flattenedImage;
}

String buildIosAppIconContentsJson() {
  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'images': _iosIconSpecs
        .map(
          (_IosIconSpec spec) => <String, String>{
            'size': spec.size,
            'idiom': spec.idiom,
            'filename': spec.filename,
            'scale': spec.scale,
          },
        )
        .toList(growable: false),
    'info': <String, Object>{'author': 'native_lens', 'version': 1},
  });
}

image.Image _decodeProjectImage({
  required Directory projectRoot,
  required String relativePath,
  required String label,
}) {
  final File imageFile = File(_joinRelative(projectRoot.path, relativePath));
  if (!imageFile.existsSync()) {
    throw NativeLensIconException('$label does not exist: $relativePath');
  }

  final Uint8List bytes;
  try {
    bytes = imageFile.readAsBytesSync();
  } on FileSystemException catch (error) {
    throw NativeLensIconException(
      'Could not read $label: $relativePath (${error.message})',
    );
  }

  final image.Image? decodedImage;
  try {
    decodedImage = image.decodeImage(bytes);
  } catch (_) {
    throw NativeLensIconException(
      'Could not decode $label: $relativePath. Use a PNG source image when '
      'possible.',
    );
  }
  if (decodedImage == null) {
    throw NativeLensIconException(
      'Could not decode $label: $relativePath. Use a PNG source image when '
      'possible.',
    );
  }

  return decodedImage;
}

bool _usesAdaptiveBackgroundImage(NativeLensIconConfig config) {
  final String? adaptiveBackground = config.adaptiveBackground;
  return adaptiveBackground != null && !_isValidColor(adaptiveBackground);
}

bool _isAndroidPath(String relativePath) {
  return relativePath == androidColorsRelativePath ||
      relativePath.startsWith('android/');
}

bool _isIosPath(String relativePath) {
  return relativePath.startsWith('ios/');
}

class _IosIconSpec {
  const _IosIconSpec({
    required this.filename,
    required this.size,
    required this.scale,
    required this.idiom,
    required this.pixels,
  });

  final String filename;
  final String size;
  final String scale;
  final String idiom;
  final int pixels;
}

const List<_IosIconSpec> _iosIconSpecs = <_IosIconSpec>[
  _IosIconSpec(
    filename: 'Icon-App-20x20@1x.png',
    size: '20x20',
    scale: '1x',
    idiom: 'iphone',
    pixels: 20,
  ),
  _IosIconSpec(
    filename: 'Icon-App-20x20@2x.png',
    size: '20x20',
    scale: '2x',
    idiom: 'iphone',
    pixels: 40,
  ),
  _IosIconSpec(
    filename: 'Icon-App-20x20@3x.png',
    size: '20x20',
    scale: '3x',
    idiom: 'iphone',
    pixels: 60,
  ),
  _IosIconSpec(
    filename: 'Icon-App-29x29@1x.png',
    size: '29x29',
    scale: '1x',
    idiom: 'iphone',
    pixels: 29,
  ),
  _IosIconSpec(
    filename: 'Icon-App-29x29@2x.png',
    size: '29x29',
    scale: '2x',
    idiom: 'iphone',
    pixels: 58,
  ),
  _IosIconSpec(
    filename: 'Icon-App-29x29@3x.png',
    size: '29x29',
    scale: '3x',
    idiom: 'iphone',
    pixels: 87,
  ),
  _IosIconSpec(
    filename: 'Icon-App-40x40@1x.png',
    size: '40x40',
    scale: '1x',
    idiom: 'iphone',
    pixels: 40,
  ),
  _IosIconSpec(
    filename: 'Icon-App-40x40@2x.png',
    size: '40x40',
    scale: '2x',
    idiom: 'iphone',
    pixels: 80,
  ),
  _IosIconSpec(
    filename: 'Icon-App-40x40@3x.png',
    size: '40x40',
    scale: '3x',
    idiom: 'iphone',
    pixels: 120,
  ),
  _IosIconSpec(
    filename: 'Icon-App-60x60@2x.png',
    size: '60x60',
    scale: '2x',
    idiom: 'iphone',
    pixels: 120,
  ),
  _IosIconSpec(
    filename: 'Icon-App-60x60@3x.png',
    size: '60x60',
    scale: '3x',
    idiom: 'iphone',
    pixels: 180,
  ),
  _IosIconSpec(
    filename: 'Icon-App-76x76@1x.png',
    size: '76x76',
    scale: '1x',
    idiom: 'ipad',
    pixels: 76,
  ),
  _IosIconSpec(
    filename: 'Icon-App-76x76@2x.png',
    size: '76x76',
    scale: '2x',
    idiom: 'ipad',
    pixels: 152,
  ),
  _IosIconSpec(
    filename: 'Icon-App-83.5x83.5@2x.png',
    size: '83.5x83.5',
    scale: '2x',
    idiom: 'ipad',
    pixels: 167,
  ),
  _IosIconSpec(
    filename: 'Icon-App-1024x1024@1x.png',
    size: '1024x1024',
    scale: '1x',
    idiom: 'ios-marketing',
    pixels: 1024,
  ),
];

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

String _joinRelative(String root, String relativePath) {
  return [root, ...relativePath.split('/')].join(Platform.pathSeparator);
}

bool _isValidColor(String value) {
  return RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value);
}

bool _isLikelyImagePath(String value) {
  return value.contains('/') ||
      value.contains(r'\') ||
      RegExp(
        r'\.(?:png|jpe?g|webp|gif|bmp|tga|tiff?)$',
        caseSensitive: false,
      ).hasMatch(value);
}

bool _readOptionalBool(YamlMap map, String key, {required bool defaultValue}) {
  final Object? value = map[key];
  if (value == null) {
    return defaultValue;
  }

  if (value is bool) {
    return value;
  }

  throw NativeLensIconException('native_lens.icon.$key must be true or false.');
}
