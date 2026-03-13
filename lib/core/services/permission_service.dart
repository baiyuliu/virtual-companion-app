// lib/core/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<Map<String, bool>> requestAll() async {
    final statuses = await [
      Permission.microphone,
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();

    return {
      'microphone':    statuses[Permission.microphone]?.isGranted ?? false,
      'camera':        statuses[Permission.camera]?.isGranted ?? false,
      'photos':        statuses[Permission.photos]?.isGranted ?? false,
      'notifications': statuses[Permission.notification]?.isGranted ?? false,
    };
  }

  static Future<void> openAppSettings() => openAppSettings();
}
