import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/search_history_provider.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _repoUrl = 'https://github.com/Ashishamar99/Tuneverse';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.onDark,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Storage'),
          ListTile(
            leading:
                const Icon(Icons.history_rounded, color: AppTheme.onDarkSecondary),
            title: const Text('Clear search history',
                style: TextStyle(color: AppTheme.onDark)),
            subtitle: const Text('Remove all recent searches',
                style:
                    TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
            onTap: () {
              ref.read(searchHistoryProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search history cleared')),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceElevated),
          const _SectionHeader('Links'),
          ListTile(
            leading: const Icon(Icons.code_rounded,
                color: AppTheme.onDarkSecondary),
            title: const Text('Source code',
                style: TextStyle(color: AppTheme.onDark)),
            subtitle: const Text('View on GitHub',
                style:
                    TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
            trailing: const Icon(Icons.open_in_new_rounded,
                color: AppTheme.onDarkSecondary, size: 18),
            onTap: () => launchUrl(Uri.parse(_repoUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined,
                color: AppTheme.onDarkSecondary),
            title: const Text('Report an issue',
                style: TextStyle(color: AppTheme.onDark)),
            subtitle: const Text('Found a bug? Let us know',
                style:
                    TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
            trailing: const Icon(Icons.open_in_new_rounded,
                color: AppTheme.onDarkSecondary, size: 18),
            onTap: () => launchUrl(Uri.parse('$_repoUrl/issues/new')),
          ),
          const Divider(height: 1, color: AppTheme.surfaceElevated),
          const _SectionHeader('About'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Text('TuneVerse',
                    style: TextStyle(
                        color: AppTheme.onDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('v0.1.0',
                    style: TextStyle(
                        color: AppTheme.onDarkSecondary, fontSize: 13)),
                SizedBox(height: 16),
                Text('Play any link, any file, one player.',
                    style: TextStyle(
                        color: AppTheme.onDarkSecondary, fontSize: 14)),
                SizedBox(height: 24),
                Text('Built with ❤️ by Ashish',
                    style: TextStyle(
                        color: AppTheme.onDarkSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.onDarkSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
