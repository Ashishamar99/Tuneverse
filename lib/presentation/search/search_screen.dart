import 'package:flutter/material.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Text('Search', style: TextStyle(color: AppTheme.onDark)),
        ),
      ),
    );
  }
}
