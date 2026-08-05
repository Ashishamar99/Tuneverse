import 'package:flutter/material.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Text('Settings', style: TextStyle(color: AppTheme.onDark)),
        ),
      ),
    );
  }
}
