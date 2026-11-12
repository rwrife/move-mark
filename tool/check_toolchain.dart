import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final pin = jsonDecode(
    File('docs/toolchain.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final result = await Process.run(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    ['--version', '--machine'],
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    throw StateError('flutter --version failed: ${result.stderr}');
  }
  final sdk = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  for (final entry in <String, String>{
    'frameworkVersion': pin['flutter_version'] as String,
    'channel': pin['flutter_channel'] as String,
    'dartSdkVersion': pin['dart_version'] as String,
  }.entries) {
    // dartSdkVersion may contain a build suffix on stable releases.
    final key = entry.key;
    final expected = entry.value;
    final actual = sdk[key].toString();
    // The pinned Docker image checks out the stable release tag, not its branch.
    final matches = switch (key) {
      'dartSdkVersion' => RegExp(
        '^${RegExp.escape(expected)}(?: |\$)',
      ).hasMatch(actual),
      'channel' =>
        actual == expected ||
            (actual == '[user-branch]' &&
                sdk['frameworkRevision'] == pin['flutter_revision']),
      _ => actual == expected,
    };
    if (!matches) {
      throw StateError('$key: expected $expected, got $actual');
    }
  }
  stdout.writeln(
    'Flutter ${sdk['frameworkVersion']} (${sdk['channel']}), Dart ${sdk['dartSdkVersion']} verified',
  );
}
