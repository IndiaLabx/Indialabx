
import 'package:flutter_test/flutter_test.dart';
import 'package:docsathi/core/utils/file_security.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String baseDir;

  MockPathProviderPlatform(this.baseDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return p.join(baseDir, 'docs');
  }

  @override
  Future<String?> getTemporaryPath() async {
    return p.join(baseDir, 'temp');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory baseDir;

  setUp(() async {
    baseDir = await Directory.systemTemp.createTemp('file_security_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(baseDir.path);
  });

  tearDown(() async {
    if (await baseDir.exists()) {
      await baseDir.delete(recursive: true);
    }
  });

  test('isPathSafe allows files in docs directory', () async {
    final docsDir = Directory(p.join(baseDir.path, 'docs'));
    await docsDir.create();
    final file = File(p.join(docsDir.path, 'safe.pdf'));
    await file.writeAsString('test');

    final result = await FileSecurity.isPathSafe(file.path);
    expect(result, true);
  });

  test('isPathSafe allows files in temp directory', () async {
    final tempDir = Directory(p.join(baseDir.path, 'temp'));
    await tempDir.create();
    final file = File(p.join(tempDir.path, 'safe.pdf'));
    await file.writeAsString('test');

    final result = await FileSecurity.isPathSafe(file.path);
    expect(result, true);
  });

  test('isPathSafe rejects files outside allowed directories', () async {
    final otherDir = Directory(p.join(baseDir.path, 'other'));
    await otherDir.create();
    final file = File(p.join(otherDir.path, 'unsafe.pdf'));
    await file.writeAsString('test');

    final result = await FileSecurity.isPathSafe(file.path);
    expect(result, false);
  });

  test('isPathSafe rejects non-existent files', () async {
    final docsDir = Directory(p.join(baseDir.path, 'docs'));
    await docsDir.create();
    final result = await FileSecurity.isPathSafe(p.join(docsDir.path, 'missing.pdf'));
    expect(result, false);
  });

  test('isPathSafe rejects directory traversal attacks', () async {
    final otherDir = Directory(p.join(baseDir.path, 'other'));
    await otherDir.create();
    final file = File(p.join(otherDir.path, 'unsafe.pdf'));
    await file.writeAsString('test');

    // docs/../other/unsafe.pdf
    final traversalPath = p.join(baseDir.path, 'docs', '..', 'other', 'unsafe.pdf');

    final result = await FileSecurity.isPathSafe(traversalPath);
    expect(result, false);
  });
}
