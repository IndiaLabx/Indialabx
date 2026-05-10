import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docsathi/core/services/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  void mockPermissionResponse(int permission, int status) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        final List<dynamic> permissions = methodCall.arguments;
        if (permissions.contains(permission)) {
          return {
            permission: status,
          };
        }
      }
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PermissionService', () {
    test('requestStoragePermission returns true when granted', () async {
      // PermissionGroup.storage is 15 on Android for modern versions of permission_handler
      // We will mock 15 as storage
      mockPermissionResponse(15, 1);
      final result = await PermissionService.requestStoragePermission();
      expect(result, true);
    });

    test('requestStoragePermission returns false when denied', () async {
      mockPermissionResponse(15, 0);
      final result = await PermissionService.requestStoragePermission();
      expect(result, false);
    });

    test('requestCameraPermission returns true when granted', () async {
      // PermissionGroup.camera is 1
      mockPermissionResponse(1, 1);
      final result = await PermissionService.requestCameraPermission();
      expect(result, true);
    });

    test('requestCameraPermission returns false when denied', () async {
      mockPermissionResponse(1, 0);
      final result = await PermissionService.requestCameraPermission();
      expect(result, false);
    });

    test('requestPhotosPermission returns true when granted', () async {
      // PermissionGroup.photos is 9
      mockPermissionResponse(9, 1);
      final result = await PermissionService.requestPhotosPermission();
      expect(result, true);
    });

    test('requestPhotosPermission returns false when denied', () async {
      mockPermissionResponse(9, 0);
      final result = await PermissionService.requestPhotosPermission();
      expect(result, false);
    });

    group('Other Statuses', () {
      test('requestStoragePermission returns false when permanentlyDenied', () async {
        // PermissionStatus.permanentlyDenied is 2
        mockPermissionResponse(15, 2);
        final result = await PermissionService.requestStoragePermission();
        expect(result, false);
      });

      test('requestStoragePermission returns false when restricted', () async {
        // PermissionStatus.restricted is 3
        mockPermissionResponse(15, 3);
        final result = await PermissionService.requestStoragePermission();
        expect(result, false);
      });
    });
  });
}
