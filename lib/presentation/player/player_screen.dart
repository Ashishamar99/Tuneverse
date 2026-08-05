import 'package:flutter/material.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Text('Player', style: TextStyle(color: AppTheme.onDark)),
        ),
      ),
    );
  }
}
