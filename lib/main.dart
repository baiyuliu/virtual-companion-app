// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/memory_manager.dart';
import 'core/services/notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 锁定竖屏（适老化）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 初始化本地存储（记忆系统）
  await MemoryManager.init();

  // 初始化通知服务
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: VirtualCompanionApp(),
    ),
  );
}
