import 'package:flutter/material.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Text('Library', style: TextStyle(color: AppTheme.onDark)),
        ),
      ),
    );
  }
}
