import 'package:flutter/material.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Text('Profiles', style: TextStyle(color: AppTheme.onDark)),
        ),
      ),
    );
  }
}
