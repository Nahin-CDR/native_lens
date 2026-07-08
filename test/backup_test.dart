import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_lens/src/backup.dart';

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('native_lens_backup_');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('backs up existing files and records missing files', () {
    _writeProjectFile(tempDirectory, 'android/app/src/main/res/values.xml', '''
<resources />
''');

    final Directory backupDirectory = createNativeLensBackupDirectory(
      projectRoot: tempDirectory,
      toolName: 'splash',
      timestamp: DateTime.utc(2026, 5, 26, 12),
    );
    final List<NativeLensBackupEntry> entries = backupNativeLensFiles(
      projectRoot: tempDirectory,
      backupDirectory: backupDirectory,
      relativePaths: <String>[
        'android/app/src/main/res/values.xml',
        'android/app/src/main/res/missing.xml',
      ],
    );

    expect(
      File(
        [
          backupDirectory.path,
          'android',
          'app',
          'src',
          'main',
          'res',
          'values.xml',
        ].join(Platform.pathSeparator),
      ).readAsStringSync(),
      contains('<resources />'),
    );
    expect(entries.first.existed, isTrue);
    expect(
      entries.first.backupRelativePath,
      'android/app/src/main/res/values.xml',
    );
    expect(entries.last.existed, isFalse);
    expect(entries.last.backupRelativePath, isNull);
  });

  test('writes a manifest with tool, phase, and backup entries', () {
    final Directory backupDirectory = createNativeLensBackupDirectory(
      projectRoot: tempDirectory,
      toolName: 'splash',
      timestamp: DateTime.utc(2026, 5, 26, 12),
    );
    final List<NativeLensBackupEntry> entries = <NativeLensBackupEntry>[
      const NativeLensBackupEntry(
        relativePath: 'existing.txt',
        existed: true,
        backupRelativePath: 'existing.txt',
      ),
      const NativeLensBackupEntry(
        relativePath: 'missing.txt',
        existed: false,
        backupRelativePath: null,
      ),
    ];
    final File manifestFile = File(
      [backupDirectory.path, 'manifest.json'].join(Platform.pathSeparator),
    );

    writeNativeLensBackupManifest(
      manifestFile: manifestFile,
      tool: 'native_lens:splash',
      phase: 'android',
      projectRoot: tempDirectory,
      backupDirectory: backupDirectory,
      entries: entries,
    );

    final Map<String, Object?> manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
    final List<Object?> files = manifest['files'] as List<Object?>;

    expect(manifest['tool'], 'native_lens:splash');
    expect(manifest['phase'], 'android');
    expect(files, hasLength(2));
    expect(files.last, containsPair('relativePath', 'missing.txt'));
    expect(files.last, containsPair('existed', false));
    expect(files.last, containsPair('backupRelativePath', null));
  });

  test('restore replaces modified files with their backed up content', () {
    _writeProjectFile(tempDirectory, 'ios/Runner/file.txt', 'original');
    final Directory backupDirectory = createNativeLensBackupDirectory(
      projectRoot: tempDirectory,
      toolName: 'splash',
      timestamp: DateTime.utc(2026, 5, 26, 12),
    );
    final List<NativeLensBackupEntry> entries = backupNativeLensFiles(
      projectRoot: tempDirectory,
      backupDirectory: backupDirectory,
      relativePaths: <String>['ios/Runner/file.txt'],
    );

    _writeProjectFile(tempDirectory, 'ios/Runner/file.txt', 'modified');

    restoreNativeLensBackup(
      projectRoot: tempDirectory,
      backupDirectory: backupDirectory,
      entries: entries,
    );

    expect(_readProjectFile(tempDirectory, 'ios/Runner/file.txt'), 'original');
  });

  test('restore deletes files that did not exist before backup', () {
    final Directory backupDirectory = createNativeLensBackupDirectory(
      projectRoot: tempDirectory,
      toolName: 'splash',
      timestamp: DateTime.utc(2026, 5, 26, 12),
    );
    final List<NativeLensBackupEntry> entries = backupNativeLensFiles(
      projectRoot: tempDirectory,
      backupDirectory: backupDirectory,
      relativePaths: <String>['android/app/src/main/res/new.xml'],
    );

    _writeProjectFile(tempDirectory, 'android/app/src/main/res/new.xml', 'new');

    restoreNativeLensBackup(
      projectRoot: tempDirectory,
      backupDirectory: backupDirectory,
      entries: entries,
    );

    expect(
      _projectFile(
        tempDirectory,
        'android/app/src/main/res/new.xml',
      ).existsSync(),
      isFalse,
    );
  });
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
