import 'dart:convert';
import 'dart:io';

class NativeLensBackupEntry {
  const NativeLensBackupEntry({
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

Directory createNativeLensBackupDirectory({
  required Directory projectRoot,
  required String toolName,
  required DateTime timestamp,
  String? timestampName,
}) {
  final String baseTimestamp = timestampName ?? _formatTimestamp(timestamp);
  final Directory backupRoot = Directory(
    _join(projectRoot.path, '.native_lens_backup', toolName),
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

List<NativeLensBackupEntry> backupNativeLensFiles({
  required Directory projectRoot,
  required Directory backupDirectory,
  required Iterable<String> relativePaths,
}) {
  final List<NativeLensBackupEntry> entries = <NativeLensBackupEntry>[];

  for (final String relativePath in relativePaths) {
    final File source = File(_join(projectRoot.path, relativePath));
    if (source.existsSync()) {
      final File backupFile = File(_join(backupDirectory.path, relativePath));
      backupFile.parent.createSync(recursive: true);
      source.copySync(backupFile.path);
      entries.add(
        NativeLensBackupEntry(
          relativePath: relativePath,
          existed: true,
          backupRelativePath: relativePath,
        ),
      );
    } else {
      entries.add(
        NativeLensBackupEntry(
          relativePath: relativePath,
          existed: false,
          backupRelativePath: null,
        ),
      );
    }
  }

  return entries;
}

void writeNativeLensBackupManifest({
  required File manifestFile,
  required String tool,
  required String phase,
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensBackupEntry> entries,
}) {
  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'tool': tool,
      'phase': phase,
      'projectRoot': projectRoot.path,
      'backupDirectory': backupDirectory.path,
      'files': entries
          .map((NativeLensBackupEntry entry) => entry.toJson())
          .toList(growable: false),
    }),
  );
}

void restoreNativeLensBackup({
  required Directory projectRoot,
  required Directory backupDirectory,
  required List<NativeLensBackupEntry> entries,
}) {
  for (final NativeLensBackupEntry entry in entries) {
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

String _formatTimestamp(DateTime timestamp) {
  final DateTime utcTimestamp = timestamp.toUtc();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  String threeDigits(int value) => value.toString().padLeft(3, '0');

  return '${utcTimestamp.year}'
      '${twoDigits(utcTimestamp.month)}'
      '${twoDigits(utcTimestamp.day)}_'
      '${twoDigits(utcTimestamp.hour)}'
      '${twoDigits(utcTimestamp.minute)}'
      '${twoDigits(utcTimestamp.second)}_'
      '${threeDigits(utcTimestamp.millisecond)}';
}

String _join(String first, String second, [String? third]) {
  return <String>[
    first,
    ...second.split('/'),
    if (third != null) ...third.split('/'),
  ].join(Platform.pathSeparator);
}
