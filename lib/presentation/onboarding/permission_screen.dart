import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PermissionScreen({super.key, required this.onComplete});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final Map<Permission, PermissionStatus> _statuses = {};
  bool _loading = true;

  static const _items = [
    _PermissionItem(
      permission: Permission.notification,
      title: 'Notifications',
      subtitle: 'Show playback controls & track info',
      icon: Icons.notifications_active_rounded,
    ),
    _PermissionItem(
      permission: Permission.audio,
      title: 'Music Library',
      subtitle: 'Scan local music files on your device',
      icon: Icons.library_music_rounded,
    ),
    _PermissionItem(
      permission: Permission.ignoreBatteryOptimizations,
      title: 'Battery',
      subtitle: 'Keep music playing with screen off',
      icon: Icons.battery_saver_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _checkStatuses();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkStatuses() async {
    for (final item in _items) {
      _statuses[item.permission] = await item.permission.status;
    }
    if (mounted) {
      setState(() => _loading = false);
      _fadeController.forward();
    }
  }

  Future<void> _request(Permission permission) async {
    final status = await permission.request();
    if (mounted) {
      setState(() => _statuses[permission] = status);
    }
  }

  Future<void> _continue() async {
    final dir = await getApplicationDocumentsDirectory();
    await File('${dir.path}/.setup_done').create();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 2),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      ..._items.map(_buildPermissionTile),
                      const Spacer(flex: 3),
                      _buildContinueButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.fallbackAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: AppTheme.fallbackAccent,
            size: 28,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to\nTuneVerse',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.onDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Grant a few permissions for the best experience.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppTheme.onDarkSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile(_PermissionItem item) {
    final status = _statuses[item.permission];
    final granted = status?.isGranted ?? false;
    final permanent = status?.isPermanentlyDenied ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: granted
              ? Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: granted
                    ? Colors.green.withValues(alpha: 0.15)
                    : AppTheme.fallbackAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                granted ? Icons.check_rounded : item.icon,
                color: granted ? Colors.green : AppTheme.fallbackAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.onDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (granted)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24)
            else if (permanent)
              TextButton(
                onPressed: openAppSettings,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.onDarkSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Settings'),
              )
            else
              TextButton(
                onPressed: () => _request(item.permission),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.fallbackAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: AppTheme.fallbackAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Allow'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _continue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.fallbackAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          'Continue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PermissionItem {
  final Permission permission;
  final String title;
  final String subtitle;
  final IconData icon;

  const _PermissionItem({
    required this.permission,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
