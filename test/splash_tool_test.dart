import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/src/splash_tool.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('native_lens_splash_');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('parses a valid native_lens splash config', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: true
''',
    );

    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
    );

    expect(plan.config.backgroundColor, '#0B1020');
    expect(plan.config.imagePath, 'assets/splash/logo.png');
    expect(plan.config.android, isTrue);
    expect(plan.config.ios, isTrue);
    expect(plan.platforms.android, isTrue);
    expect(plan.platforms.ios, isTrue);
  });

  test('throws a clear error when native_lens.splash is missing', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
''',
    );

    expect(
      () => buildSplashPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensSplashException>().having(
          (NativeLensSplashException error) => error.message,
          'message',
          contains('Missing native_lens config'),
        ),
      ),
    );
  });

  test('throws a clear error for an invalid background color', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "0B1020"
    image: assets/splash/logo.png
''',
    );

    expect(
      () => buildSplashPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensSplashException>().having(
          (NativeLensSplashException error) => error.message,
          'message',
          contains('#RRGGBB or #AARRGGBB'),
        ),
      ),
    );
  });

  test('throws a clear error when the image is missing', () {
    _writeProject(
      tempDirectory,
      createImage: false,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#FF0B1020"
    image: assets/splash/logo.png
''',
    );

    expect(
      () => buildSplashPlan(workingDirectory: tempDirectory),
      throwsA(
        isA<NativeLensSplashException>().having(
          (NativeLensSplashException error) => error.message,
          'message',
          contains('Splash image does not exist'),
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
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: true
''',
    );

    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
      androidOnly: true,
    );

    expect(plan.platforms.android, isTrue);
    expect(plan.platforms.ios, isFalse);
    expect(
      plan.plannedFiles.map(
        (NativeLensSplashFilePlan file) => file.relativePath,
      ),
      contains('android/app/src/main/res/values/styles.xml'),
    );
    expect(
      plan.plannedFiles.map(
        (NativeLensSplashFilePlan file) => file.relativePath,
      ),
      isNot(contains('ios/Runner/Base.lproj/LaunchScreen.storyboard')),
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
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
''',
      );

      final List<String> output = <String>[];
      final int exitCode = await runNativeLensSplash(
        <String>['--dry-run'],
        workingDirectory: tempDirectory,
        stdoutWriter: output.add,
        stderrWriter: output.add,
      );

      expect(exitCode, 0);
      expect(output.join('\n'), contains('NativeLens native splash dry run'));
      expect(output.join('\n'), contains('background_color: #0B1020'));
      expect(
        output.join('\n'),
        contains('android/app/src/main/res/values/styles.xml'),
      );
      expect(
        output.join('\n'),
        contains('ios/Runner/Base.lproj/LaunchScreen.storyboard'),
      );
      expect(
        output.join('\n'),
        contains('No Android or iOS files were modified.'),
      );
    },
  );

  test('Android file plan includes generated files and backup intent', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
    );

    final List<String> paths = plan.plannedFiles
        .map((NativeLensSplashFilePlan file) => file.relativePath)
        .toList();

    expect(paths, contains('android/app/src/main/res/values/colors.xml'));
    expect(paths, contains('android/app/src/main/res/values-v31/styles.xml'));
    expect(
      paths,
      contains('android/app/src/main/res/drawable/native_lens_splash.png'),
    );
    expect(
      plan.plannedFiles.every(
        (NativeLensSplashFilePlan file) => file.willBackup,
      ),
      isTrue,
    );
  });

  test('dry-run does not write Android files or backup folders', () async {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final int exitCode = await runNativeLensSplash(
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
          'values-v31',
          'styles.xml',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
    expect(
      Directory(
        [
          tempDirectory.path,
          '.native_lens_backup',
          'splash',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
  });

  test('Android generation creates backup manifest and XML files', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
    );
    final NativeLensSplashGenerationResult result = generateAndroidSplash(
      plan,
      timestamp: '20260526_120000_000',
    );

    expect(File(result.manifestPath).existsSync(), isTrue);
    final Map<String, Object?> manifest =
        jsonDecode(File(result.manifestPath).readAsStringSync())
            as Map<String, Object?>;
    expect(manifest['tool'], 'native_lens:splash');
    expect(
      result.generatedFiles,
      contains('android/app/src/main/res/values/colors.xml'),
    );

    final String colorsXml = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/values/colors.xml',
    );
    expect(colorsXml, contains('native_lens_splash_background'));
    expect(colorsXml, contains('#0B1020'));

    final String launchBackground = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/drawable/launch_background.xml',
    );
    expect(launchBackground, contains('@drawable/native_lens_splash'));

    final String stylesXml = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/values/styles.xml',
    );
    expect(stylesXml, contains('name="NormalTheme"'));
    expect(stylesXml, contains('@drawable/launch_background'));

    final String v31Styles = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/values-v31/styles.xml',
    );
    expect(v31Styles, contains('windowSplashScreenBackground'));
    expect(v31Styles, contains('windowSplashScreenAnimatedIcon'));
    expect(v31Styles, isNot(contains('android:postSplashScreenTheme')));
  });

  test('Android generation rolls back when a write fails', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: true
    ios: false
''',
    );
    _writeAndroidProject(tempDirectory);

    final String originalColorsXml = _readProjectFile(
      tempDirectory,
      'android/app/src/main/res/values/colors.xml',
    );
    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      () => generateAndroidSplash(
        plan,
        timestamp: '20260526_120000_001',
        simulateFailureAfterFirstWrite: true,
      ),
      throwsA(isA<NativeLensSplashException>()),
    );

    expect(
      _readProjectFile(
        tempDirectory,
        'android/app/src/main/res/values/colors.xml',
      ),
      originalColorsXml,
    );
    expect(
      File(
        [
          tempDirectory.path,
          'android',
          'app',
          'src',
          'main',
          'res',
          'values-v31',
          'styles.xml',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
  });

  test('iOS file plan includes generated files and backup intent', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
    );

    final List<String> paths = plan.plannedFiles
        .map((NativeLensSplashFilePlan file) => file.relativePath)
        .toList();

    expect(paths, contains('ios/Runner/Base.lproj/LaunchScreen.storyboard'));
    expect(
      paths,
      contains(
        'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/Contents.json',
      ),
    );
    expect(
      paths,
      contains(
        'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/native_lens_splash.png',
      ),
    );
    expect(
      plan.plannedFiles.every(
        (NativeLensSplashFilePlan file) => file.willBackup,
      ),
      isTrue,
    );
  });

  test('dry-run does not write iOS files or backup folders', () async {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final String originalStoryboard = _readProjectFile(
      tempDirectory,
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    );
    final int exitCode = await runNativeLensSplash(
      <String>['--dry-run'],
      workingDirectory: tempDirectory,
      stdoutWriter: (_) {},
      stderrWriter: (_) {},
    );

    expect(exitCode, 0);
    expect(
      _readProjectFile(
        tempDirectory,
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ),
      originalStoryboard,
    );
    expect(
      Directory(
        [
          tempDirectory.path,
          'ios',
          'Runner',
          'Assets.xcassets',
          'NativeLensSplash.imageset',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
    expect(
      Directory(
        [
          tempDirectory.path,
          '.native_lens_backup',
          'splash',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
  });

  test(
    'iOS generation creates storyboard, asset catalog, and backup manifest',
    () {
      _writeProject(
        tempDirectory,
        pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: false
    ios: true
''',
      );
      _writeIosProject(tempDirectory);

      final NativeLensSplashPlan plan = buildSplashPlan(
        workingDirectory: tempDirectory,
      );
      final NativeLensSplashGenerationResult result = generateIosSplash(
        plan,
        timestamp: '20260526_120000_002',
      );

      expect(File(result.manifestPath).existsSync(), isTrue);
      final Map<String, Object?> manifest =
          jsonDecode(File(result.manifestPath).readAsStringSync())
              as Map<String, Object?>;
      expect(manifest['tool'], 'native_lens:splash');
      expect(manifest['phase'], 'ios');
      expect(
        result.generatedFiles,
        contains('ios/Runner/Base.lproj/LaunchScreen.storyboard'),
      );

      final String storyboard = _readProjectFile(
        tempDirectory,
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      );
      expect(storyboard, contains('red="0.043137"'));
      expect(storyboard, contains('green="0.062745"'));
      expect(storyboard, contains('blue="0.125490"'));
      expect(storyboard, contains('image="NativeLensSplash"'));
      expect(storyboard, contains('launchScreen="YES"'));

      final String contentsJson = _readProjectFile(
        tempDirectory,
        'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/Contents.json',
      );
      final Map<String, Object?> contents =
          jsonDecode(contentsJson) as Map<String, Object?>;
      expect(contents['info'], isA<Map<String, Object?>>());
      expect(contentsJson, contains('native_lens_splash.png'));
      expect(contentsJson, contains('"idiom": "universal"'));

      expect(
        File(
          [
            tempDirectory.path,
            'ios',
            'Runner',
            'Assets.xcassets',
            'NativeLensSplash.imageset',
            'native_lens_splash.png',
          ].join(Platform.pathSeparator),
        ).readAsBytesSync(),
        <int>[0, 1, 2, 3],
      );

      final List<Object?> files = manifest['files'] as List<Object?>;
      expect(
        files.whereType<Map<String, Object?>>().map(
          (Map<String, Object?> file) => file['relativePath'],
        ),
        contains(
          'ios/Runner/Assets.xcassets/NativeLensSplash.imageset/native_lens_splash.png',
        ),
      );
    },
  );

  test('iOS generation rolls back when a write fails', () {
    _writeProject(
      tempDirectory,
      pubspec: '''
name: demo_app
native_lens:
  splash:
    background_color: "#0B1020"
    image: assets/splash/logo.png
    android: false
    ios: true
''',
    );
    _writeIosProject(tempDirectory);

    final String originalStoryboard = _readProjectFile(
      tempDirectory,
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    );
    final NativeLensSplashPlan plan = buildSplashPlan(
      workingDirectory: tempDirectory,
    );

    expect(
      () => generateIosSplash(
        plan,
        timestamp: '20260526_120000_003',
        simulateFailureAfterFirstWrite: true,
      ),
      throwsA(isA<NativeLensSplashException>()),
    );

    expect(
      _readProjectFile(
        tempDirectory,
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ),
      originalStoryboard,
    );
    expect(
      Directory(
        [
          tempDirectory.path,
          'ios',
          'Runner',
          'Assets.xcassets',
          'NativeLensSplash.imageset',
        ].join(Platform.pathSeparator),
      ).existsSync(),
      isFalse,
    );
  });
}

void _writeProject(
  Directory directory, {
  required String pubspec,
  bool createImage = true,
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

  if (createImage) {
    File(
        [
          directory.path,
          'assets',
          'splash',
          'logo.png',
        ].join(Platform.pathSeparator),
      )
      ..createSync(recursive: true)
      ..writeAsBytesSync(<int>[0, 1, 2, 3]);
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
    <application>
        <activity android:name=".MainActivity" android:theme="@style/LaunchTheme" />
    </application>
</manifest>
''');

  File(
      [
        directory.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'values',
        'colors.xml',
      ].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="existing_color">#FFFFFF</color>
</resources>
''');

  File(
      [
        directory.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'values',
        'styles.xml',
      ].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/old_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''');

  File(
      [
        directory.path,
        'android',
        'app',
        'src',
        'main',
        'res',
        'drawable',
        'launch_background.xml',
      ].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('<layer-list />');
}

void _writeIosProject(Directory directory) {
  File(
      [
        directory.path,
        'ios',
        'Runner',
        'Base.lproj',
        'LaunchScreen.storyboard',
      ].join(Platform.pathSeparator),
    )
    ..createSync(recursive: true)
    ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" launchScreen="YES">
    <scenes />
</document>
''');

  Directory(
    [
      directory.path,
      'ios',
      'Runner',
      'Assets.xcassets',
    ].join(Platform.pathSeparator),
  ).createSync(recursive: true);
}

String _readProjectFile(Directory directory, String relativePath) {
  return File(
    [directory.path, ...relativePath.split('/')].join(Platform.pathSeparator),
  ).readAsStringSync();
}
