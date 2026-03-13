// lib/app.dart

import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'shared/theme/app_theme.dart';

class VirtualCompanionApp extends StatelessWidget {
  const VirtualCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '陪伴助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const OnboardingScreen(),
    );
  }
}
