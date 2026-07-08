import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:native_lens/src/icon_tool.dart';

late Directory tempDirectory;

void main() {
  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('native_lens_icon_');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('parses a valid native_lens icon config', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    monochrome: assets/icon/icon_monochrome.png
    remove_alpha_ios: true
    android: true
    ios: true
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.config.imagePath, 'assets/icon/icon.png');
    expect(plan.sourceImage.dimensions, '128x128');
    expect(plan.config.adaptiveBackground, '#4F8F83');
    expect(
      plan.config.adaptiveForegroundPath,
      'assets/icon/icon_foreground.png',
    );
    expect(plan.adaptiveForegroundImage?.dimensions, '128x128');
    expect(plan.config.monochromePath, 'assets/icon/icon_monochrome.png');
    expect(plan.monochromeImage?.dimensions, '128x128');
    expect(plan.config.removeAlphaIos, isTrue);
    expect(plan.config.android, isTrue);
    expect(plan.config.ios, isTrue);
    expect(plan.platforms.android, isTrue);
    expect(plan.platforms.ios, isTrue);
  });

  test('throws a clear error when native_lens.icon is missing', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
''',
    );

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('Missing native_lens config'),
        ),
      ),
    );
  });

  test('throws a clear error when the icon image is missing', () {
    _writeProject(
      tempDirectory,
      createBaseIcon: false,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
''',
    );

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('Icon image does not exist'),
        ),
      ),
    );
  });

  test('throws a clear error when the icon image is corrupt', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
''',
    );
    _writeCorruptFile(tempDirectory, 'assets/icon/icon.png');

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          allOf(contains('Could not decode Icon image'), contains('PNG')),
        ),
      ),
    );
  });

  test('throws a clear error for an invalid adaptive background color', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "4F8F83"
''',
    );

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('#RRGGBB or #AARRGGBB'),
        ),
      ),
    );
  });

  test('Android selected requires adaptive_background', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: true
    ios: false
''',
    );

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains(
            'native_lens.icon.adaptive_background is required when Android '
            'icon generation is enabled.',
          ),
        ),
      ),
    );
  });

  test('iOS-only selection does not require adaptive_background', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: true
    ios: true
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
      iosOnly: true,
    );

    expect(plan.platforms.android, isFalse);
    expect(plan.platforms.ios, isTrue);
    expect(plan.config.adaptiveBackground, isNull);
  });

  test('non-square source icon adds a warning but does not fail', () {
    _writeProject(
      tempDirectory,
      baseWidth: 128,
      baseHeight: 96,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.sourceImage.dimensions, '128x96');
    expect(
      plan.warnings,
      contains(contains('Source icon is not square (128x96)')),
    );
  });

  test('fully opaque adaptive foreground adds a warning but does not fail', () {
    _writeProject(
      tempDirectory,
      foregroundTransparent: false,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    android: true
    ios: false
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.adaptiveForegroundImage?.dimensions, '128x128');
    expect(
      plan.warnings,
      contains(
        'adaptive_foreground appears fully opaque. Adaptive foregrounds should '
        'be transparent PNG glyph layers; otherwise Android adaptive icons may '
        'look wrong.',
      ),
    );
  });

  test('transparent adaptive foreground does not add opacity warning', () {
    _writeProject(
      tempDirectory,
      foregroundTransparent: true,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    android: true
    ios: false
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.adaptiveForegroundImage?.hasTransparentPixels, isTrue);
    expect(
      plan.warnings,
      isNot(contains(startsWith('adaptive_foreground appears fully opaque.'))),
    );
  });

  test('path-based adaptive background decodes and appears in metadata', () {
    _writeProject(
      tempDirectory,
      createAdaptiveBackgroundImage: true,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: assets/icon/background.png
    android: true
    ios: false
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.adaptiveBackgroundImage?.dimensions, '64x64');
    expect(
      formatIconPlan(plan, dryRun: true),
      contains('adaptive background image: 64x64 (assets/icon/background.png)'),
    );
  });

  test('corrupt path-based adaptive background fails clearly', () {
    _writeProject(
      tempDirectory,
      createAdaptiveBackgroundImage: true,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: assets/icon/background.png
''',
    );
    _writeCorruptFile(tempDirectory, 'assets/icon/background.png');

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('Could not decode Adaptive background image'),
        ),
      ),
    );
  });

  test('monochrome path decodes when configured', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    monochrome: assets/icon/icon_monochrome.png
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.monochromeImage?.dimensions, '128x128');
    expect(
      formatIconPlan(plan, dryRun: true),
      contains('monochrome: 128x128 (assets/icon/icon_monochrome.png)'),
    );
  });

  test('corrupt monochrome path fails clearly', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    monochrome: assets/icon/icon_monochrome.png
''',
    );
    _writeCorruptFile(tempDirectory, 'assets/icon/icon_monochrome.png');

    expect(
      () => buildIconPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('Could not decode Monochrome icon image'),
        ),
      ),
    );
  });

  test('platform flags narrow the selected platform plan', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    android: true
    ios: true
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
      androidOnly: true,
    );

    expect(plan.platforms.android, isTrue);
    expect(plan.platforms.ios, isFalse);
    expect(
      plan.plannedFiles.map((NativeLensIconFilePlan file) => file.relativePath),
      contains('android/app/src/main/res/mipmap-mdpi/ic_launcher.png'),
    );
    expect(
      plan.plannedFiles.map((NativeLensIconFilePlan file) => file.relativePath),
      isNot(
        contains('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'),
      ),
    );
  });

  test(
    'dry-run command prints config, project paths, and planned files',
    () async {
      _writeProject(
        tempDirectory,
        pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    monochrome: assets/icon/icon_monochrome.png
''',
      );

      final List<String> output = <String>[];
      final int exitCode = await runNativeLensIcon(
        <String>['--dry-run'],
        workingDirectory: tempDirectory,
        stdoutWriter: output.add,
        stderrWriter: output.add,
      );

      expect(exitCode, 0);
      expect(output.join('\n'), contains('NativeLens native icon dry run'));
      expect(output.join('\n'), contains('image: assets/icon/icon.png'));
      expect(output.join('\n'), contains('source image: 128x128'));
      expect(output.join('\n'), contains('adaptive_background: #4F8F83'));
      expect(
        output.join('\n'),
        contains('android/app/src/main/res/mipmap-mdpi/ic_launcher.png'),
      );
      expect(
        output.join('\n'),
        contains('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'),
      );
      expect(
        output.join('\n'),
        contains('No Android or iOS files were modified.'),
      );
    },
  );

  test('dry-run does not write icon files or backup folders', () async {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final int exitCode = await runNativeLensIcon(
      <String>['--dry-run'],
      workingDirectory: tempDirectory,
      stdoutWriter: (_) {},
      stderrWriter: (_) {},
    );

    expect(exitCode, 0);
    expect(
      File(
        [
          tempDirectory.path,
          'android',
          'app',
          'src',
          'main',
          'res',
          'mipmap-mdpi',
          'ic_launcher.png',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
    expect(
      _projectFile(
        tempDirectory,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ).existsSync(),
      isFalse,
    );
    expect(
      Directory(
        [
          tempDirectory.path,
          '.native_lens_backup',
          'icon',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
  });

  test('iOS generation creates AppIcon PNGs and Contents.json', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );
    final NativeLensIconGenerationResult result = generateIosIcons(
      plan,
      timestamp: '20260708_130000_000',
    );

    expect(File(result.manifestPath).existsSync(), isTrue);
    expect(
      result.backupDirectory,
      contains('.native_lens_backup${Platform.pathSeparator}icon'),
    );
    final Map<String, Object?> manifest =
        jsonDecode(File(result.manifestPath).readAsStringSync())
            as Map<String, Object?>;
    expect(manifest['tool'], 'native_lens:icon');
    expect(manifest['phase'], 'ios');

    _expectPngDimensions(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-20x20@1x.png',
      20,
      20,
    );
    _expectPngDimensions(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-20x20@3x.png',
      60,
      60,
    );
    _expectPngDimensions(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-60x60@3x.png',
      180,
      180,
    );
    _expectPngDimensions(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-1024x1024@1x.png',
      1024,
      1024,
    );

    final Map<String, Object?> contents =
        jsonDecode(
              _readProjectFile(
                tempDirectory,
                'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
              ),
            )
            as Map<String, Object?>;
    final Map<String, Object?> info = contents['info'] as Map<String, Object?>;
    expect(info['author'], 'native_lens');
    expect(info['version'], 1);
    final List<Object?> images = contents['images'] as List<Object?>;
    expect(images, hasLength(15));
    expect(
      images,
      contains(
        allOf(
          isA<Map<String, Object?>>(),
          containsPair('filename', 'Icon-App-1024x1024@1x.png'),
          containsPair('idiom', 'ios-marketing'),
          containsPair('size', '1024x1024'),
          containsPair('scale', '1x'),
        ),
      ),
    );
  });

  test('iOS generation removes alpha by default', () {
    _writeProject(
      tempDirectory,
      baseTransparent: true,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );
    generateIosIcons(plan, timestamp: '20260708_130000_001');

    _expectPngHasNoTransparentPixels(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-20x20@1x.png',
    );
  });

  test('iOS generation can preserve alpha and warns', () {
    _writeProject(
      tempDirectory,
      baseTransparent: true,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    remove_alpha_ios: false
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      plan.warnings,
      contains(
        'remove_alpha_ios is false and the source icon has transparent pixels. '
        'iOS App Store icons may be rejected if alpha remains.',
      ),
    );

    generateIosIcons(plan, timestamp: '20260708_130000_002');

    _expectPngHasTransparentPixels(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-20x20@1x.png',
    );
  });

  test('iOS generation backs up existing files before overwrite', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);
    _writeProjectFile(
      tempDirectory,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
          'Icon-App-20x20@1x.png',
      'old ios icon bytes',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );
    final NativeLensIconGenerationResult result = generateIosIcons(
      plan,
      timestamp: '20260708_130000_003',
    );

    final File backupFile = File(
      [
        result.backupDirectory,
        'ios',
        'Runner',
        'Assets.xcassets',
        'AppIcon.appiconset',
        'Icon-App-20x20@1x.png',
      ].join(Platform.pathSeparator),
    );
    expect(backupFile.readAsStringSync(), 'old ios icon bytes');
  });

  test('iOS generation rolls back modified files when a write fails', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);
    _writeProjectFile(
      tempDirectory,
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      '{"old":true}',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      () => generateIosIcons(
        plan,
        timestamp: '20260708_130000_004',
        simulateFailureAfterFirstWrite: true,
      ),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('rollback was completed'),
        ),
      ),
    );

    expect(
      _readProjectFile(
        tempDirectory,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ),
      '{"old":true}',
    );
  });

  test('iOS generation rollback deletes newly-created files', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      () => generateIosIcons(
        plan,
        timestamp: '20260708_130000_005',
        simulateFailureAfterFirstWrite: true,
      ),
      throwsA(isA<NativeLensIconException>()),
    );

    expect(
      _projectFile(
        tempDirectory,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
      ).existsSync(),
      isFalse,
    );
  });

  test('iOS-only generation works without Android adaptive config', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    android: true
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
      iosOnly: true,
    );
    final NativeLensIconGenerationResult result = generateIosIcons(
      plan,
      timestamp: '20260708_130000_006',
    );

    expect(result.generatedFiles, contains(iosIconRelativePaths.first));
    _expectPngDimensions(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
      'Icon-App-1024x1024@1x.png',
      1024,
      1024,
    );
  });

  test('Android generation creates legacy and adaptive launcher files', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);
    _writeProjectFile(
      tempDirectory,
      'android/app/src/main/res/values/colors.xml',
      '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="native_lens_splash_background">#0B1020</color>
</resources>
''',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );
    final NativeLensIconGenerationResult result = generateAndroidIcons(
      plan,
      timestamp: '20260708_120000_000',
    );

    expect(File(result.manifestPath).existsSync(), isTrue);
    final Map<String, Object?> manifest =
        jsonDecode(File(result.manifestPath).readAsStringSync())
            as Map<String, Object?>;
    expect(manifest['tool'], 'native_lens:icon');
    expect(manifest['phase'], 'android');

    _expectPngDimensions(
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      48,
      48,
    );
    _expectPngDimensions(
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
      72,
      72,
    );
    _expectPngDimensions(
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
      96,
      96,
    );
    _expectPngDimensions(
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
      144,
      144,
    );
    _expectPngDimensions(
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      192,
      192,
    );

    _expectPngDimensions(
      'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png',
      108,
      108,
    );
    _expectPngDimensions(
      'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png',
      162,
      162,
    );
    _expectPngDimensions(
      'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png',
      216,
      216,
    );
    _expectPngDimensions(
      'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png',
      324,
      324,
    );
    _expectPngDimensions(
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
      432,
      432,
    );

    final String adaptiveXml = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    );
    expect(adaptiveXml, contains('@color/ic_launcher_background'));
    expect(adaptiveXml, contains('@drawable/ic_launcher_foreground'));
    expect(adaptiveXml, isNot(contains('monochrome')));

    final String colorsXml = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/values/colors.xml',
    );
    expect(colorsXml, contains('name="ic_launcher_background">#4F8F83'));
    expect(colorsXml, contains('name="native_lens_splash_background"'));
    expect(
      result.generatedFiles,
      contains('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml'),
    );
  });

  test(
    'Android generation writes image adaptive background and XML reference',
    () {
      _writeProject(
        tempDirectory,
        createAdaptiveBackgroundImage: true,
        pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: assets/icon/background.png
    adaptive_foreground: assets/icon/icon_foreground.png
    android: true
    ios: false
''',
      );
      _writeAndroidProject(tempDirectory);

      final NativeLensIconPlan plan = buildIconPlan(
        workingDirectory: tempDirectory,
      );
      generateAndroidIcons(plan, timestamp: '20260708_120000_001');

      _expectPngDimensions(
        'android/app/src/main/res/drawable/ic_launcher_background.png',
        432,
        432,
      );
      final String adaptiveXml = _readProjectFile(
        tempDirectory,
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      );
      expect(adaptiveXml, contains('@drawable/ic_launcher_background'));
      expect(
        File(
          [
            tempDirectory.path,
            'android',
            'app',
            'src',
            'main',
            'res',
            'values',
            'colors.xml',
          ].join(Platform.pathSeparator),
        ).existsSync(),
        isFalse,
      );
    },
  );

  test('Android generation writes monochrome PNG and XML element', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    monochrome: assets/icon/icon_monochrome.png
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );
    generateAndroidIcons(plan, timestamp: '20260708_120000_002');

    _expectPngDimensions(
      'android/app/src/main/res/drawable/ic_launcher_monochrome.png',
      432,
      432,
    );
    final String adaptiveXml = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    );
    expect(
      adaptiveXml,
      contains(
        '<monochrome android:drawable="@drawable/ic_launcher_monochrome"/>',
      ),
    );
  });

  test('Android generation backs up existing files before overwrite', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);
    _writeProjectFile(
      tempDirectory,
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
      'old icon bytes',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );
    final NativeLensIconGenerationResult result = generateAndroidIcons(
      plan,
      timestamp: '20260708_120000_003',
    );

    final File backupFile = File(
      [
        result.backupDirectory,
        'android',
        'app',
        'src',
        'main',
        'res',
        'mipmap-mdpi',
        'ic_launcher.png',
      ].join(Platform.pathSeparator),
    );
    expect(backupFile.readAsStringSync(), 'old icon bytes');
  });

  test('Android generation rolls back modified files when a write fails', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);
    _writeProjectFile(
      tempDirectory,
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      '<old-adaptive-icon />',
    );

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      () => generateAndroidIcons(
        plan,
        timestamp: '20260708_120000_004',
        simulateFailureAfterFirstWrite: true,
      ),
      throwsA(
        isA<NativeLensIconException>().having(
          (NativeLensIconException error) => error.message,
          'message',
          contains('rollback was completed'),
        ),
      ),
    );

    expect(
      _readProjectFile(
        tempDirectory,
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ),
      '<old-adaptive-icon />',
    );
  });

  test('Android generation rollback deletes newly-created files', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final NativeLensIconPlan plan = buildIconPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      () => generateAndroidIcons(
        plan,
        timestamp: '20260708_120000_005',
        simulateFailureAfterFirstWrite: true,
      ),
      throwsA(isA<NativeLensIconException>()),
    );

    expect(
      _projectFile(
        tempDirectory,
        'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'non-dry command generates Android and iOS when both are selected',
    () async {
      _writeProject(
        tempDirectory,
        pubspec: '''
name: demo_app
native_lens:
  icon:
    image: assets/icon/icon.png
    adaptive_background: "#4F8F83"
    adaptive_foreground: assets/icon/icon_foreground.png
    android: true
    ios: true
''',
      );
      _writeAndroidProject(tempDirectory);
      _writeIosProject(tempDirectory);

      final List<String> output = <String>[];
      final int exitCode = await runNativeLensIcon(
        <String>[],
        workingDirectory: tempDirectory,
        stdoutWriter: output.add,
        stderrWriter: output.add,
      );

      expect(exitCode, 0);
      expect(
        output.join('\n'),
        contains('Android native icon files generated.'),
      );
      expect(output.join('\n'), contains('Manifest:'));
      expect(output.join('\n'), contains('iOS native icon files generated.'));
      expect(
        output.join('\n'),
        isNot(contains('iOS native icon generation is not implemented yet.')),
      );
      expect(
        _projectFile(
          tempDirectory,
          'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
        ).existsSync(),
        isTrue,
      );
      expect(
        _projectFile(
          tempDirectory,
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
          'Icon-App-1024x1024@1x.png',
        ).existsSync(),
        isTrue,
      );
    },
  );
}

void _writeProject(
  Directory directory, {
  required String pubspec,
  bool createBaseIcon = true,
  int baseWidth = 128,
  int baseHeight = 128,
  bool baseTransparent = false,
  bool foregroundTransparent = true,
  bool createAdaptiveBackgroundImage = false,
}) {
  File('${directory.path}${Platform.pathSeparator}pubspec.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync(pubspec);

  Directory(
    '${directory.path}${Platform.pathSeparator}android',
  ).createSync(recursive: true);
  Directory(
    '${directory.path}${Platform.pathSeparator}ios',
  ).createSync(recursive: true);

  if (createBaseIcon) {
    _writePng(
      directory,
      'assets/icon/icon.png',
      width: baseWidth,
      height: baseHeight,
      transparent: baseTransparent,
    );
  }
  _writePng(
    directory,
    'assets/icon/icon_foreground.png',
    width: 128,
    height: 128,
    transparent: foregroundTransparent,
  );
  _writePng(
    directory,
    'assets/icon/icon_monochrome.png',
    width: 128,
    height: 128,
    transparent: true,
  );
  if (createAdaptiveBackgroundImage) {
    _writePng(
      directory,
      'assets/icon/background.png',
      width: 64,
      height: 64,
      transparent: false,
    );
  }
}

void _writeAndroidProject(Directory directory) {
  File(
      [
        directory.path,
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      ].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:icon="@mipmap/ic_launcher" />
</manifest>
''');
}

void _writeIosProject(Directory directory) {
  Directory(
    [
      directory.path,
      'ios',
      'Runner',
      'Assets.xcassets',
      'AppIcon.appiconset',
    ].join(Platform.pathSeparator),
  ).createSync(recursive: true);
}

void _writeProjectFile(
  Directory directory,
  String relativePath,
  String content,
) {
  final File file = _projectFile(directory, relativePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _readProjectFile(Directory directory, String relativePath) {
  return _projectFile(directory, relativePath).readAsStringSync();
}

File _projectFile(Directory directory, String relativePath) {
  return File(
    [directory.path, ...relativePath.split('/')].join(Platform.pathSeparator),
  );
}

void _expectPngDimensions(String relativePath, int width, int height) {
  final image.Image? decodedImage = image.decodePng(
    _projectFile(tempDirectory, relativePath).readAsBytesSync(),
  );
  expect(decodedImage, isNotNull);
  expect(decodedImage!.width, width);
  expect(decodedImage.height, height);
}

void _expectPngHasTransparentPixels(String relativePath) {
  expect(_pngHasTransparentPixels(relativePath), isTrue);
}

void _expectPngHasNoTransparentPixels(String relativePath) {
  expect(_pngHasTransparentPixels(relativePath), isFalse);
}

bool _pngHasTransparentPixels(String relativePath) {
  final image.Image? decodedImage = image.decodePng(
    _projectFile(tempDirectory, relativePath).readAsBytesSync(),
  );
  expect(decodedImage, isNotNull);
  if (!decodedImage!.hasAlpha) {
    return false;
  }

  for (final image.Pixel pixel in decodedImage) {
    if (pixel.a < pixel.maxChannelValue) {
      return true;
    }
  }
  return false;
}

void _writePng(
  Directory directory,
  String relativePath, {
  required int width,
  required int height,
  required bool transparent,
}) {
  final image.Image png = image.Image(
    width: width,
    height: height,
    numChannels: 4,
  );
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final int alpha = transparent && x == 0 && y == 0 ? 0 : 255;
      png.setPixelRgba(x, y, 79, 143, 131, alpha);
    }
  }
  File(
      [directory.path, ...relativePath.split('/')].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsBytesSync(image.encodePng(png));
}

void _writeCorruptFile(Directory directory, String relativePath) {
  File(
      [directory.path, ...relativePath.split('/')].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsBytesSync(<int>[0, 1, 2, 3]);
}
