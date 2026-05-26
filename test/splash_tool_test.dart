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
      plan.plannedFiles,
      contains('android/app/src/main/res/values/styles.xml'),
    );
    expect(
      plan.plannedFiles,
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
