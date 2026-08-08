import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuneverse/core/di/appwrite_providers.dart';
import 'package:tuneverse/core/di/backup_providers.dart';
import 'package:tuneverse/core/di/profile_providers.dart';
import 'package:tuneverse/core/di/search_history_provider.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const _repoUrl = 'https://github.com/Ashishamar99/Tuneverse';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _backingUp = false;
  bool _restoring = false;
  bool _signingIn = false;

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    try {
      await ref.read(signInWithGoogleProvider)();
      ref.invalidate(appwriteUserProvider);
      if (!mounted) return;
      setState(() => _signingIn = false);

      // Check for existing backup after sign-in
      await _handlePostSignIn();
    } catch (e) {
      if (mounted) {
        setState(() => _signingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
      }
    }
  }

  Future<void> _handlePostSignIn() async {
    try {
      final hasBackup = await ref.refresh(checkBackupExistsProvider.future);
      if (!mounted) return;

      if (hasBackup) {
        final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('We found your data!'),
            content: const Text(
                'Would you like to restore your playlists and favorites?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Start Fresh'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (shouldRestore == true && mounted) {
          await _restore();
        }
      }
    } catch (_) {
      // Not critical
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(signOutProvider)();
      ref.invalidate(appwriteUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-out failed: $e')),
        );
      }
    }
  }

  Future<void> _backup() async {
    setState(() => _backingUp = true);
    try {
      await ref.read(backupProvider)();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      await ref.read(restoreProvider)();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data restored successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final userAsync = ref.watch(appwriteUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.onDark,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
        children: [
          const _SectionHeader('Profiles & Theme'),
          ListTile(
            leading: profile != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Color(profile.accentColorValue).withValues(alpha: 0.2),
                    child: Text(profile.avatarEmoji,
                        style: const TextStyle(fontSize: 18)),
                  )
                : const Icon(Icons.person_rounded,
                    color: AppTheme.onDarkSecondary),
            title: Text(profile?.name ?? 'Profile',
                style: const TextStyle(color: AppTheme.onDark)),
            subtitle: const Text('Switch profile, change theme color',
                style:
                    TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.onDarkSecondary),
            onTap: () => context.push(AppRoutes.profiles),
          ),
          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // ---------------------------------------------------------------
          // Account & Sync
          // ---------------------------------------------------------------
          const _SectionHeader('Account & Sync'),
          userAsync.when(
            loading: () => const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Checking account...',
                  style: TextStyle(color: AppTheme.onDark)),
            ),
            error: (_, __) => _buildSignInTile(),
            data: (user) {
              if (user == null) return _buildSignInTile();
              return _buildSignedInSection(user.name, user.email);
            },
          ),
          const Divider(height: 1, color: AppTheme.surfaceElevated),

          // ---------------------------------------------------------------
          // Import
          // ---------------------------------------------------------------
          const _SectionHeader('Import'),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded,
                color: AppTheme.onDarkSecondary),
            title: const Text('Import Playlist',
                style: TextStyle(color: AppTheme.onDark)),
            subtitle: const Text(
                'Convert playlists from Amazon Music, Spotify & more',
                style:
                    TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.onDarkSecondary),
            onTap: () => context.push(AppRoutes.importPlaylist),
          ),
          const Divider(height: 1, color: AppTheme.surfaceElevated),

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
            onTap: () => launchUrl(Uri.parse(SettingsScreen._repoUrl)),
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
            onTap: () => launchUrl(
                Uri.parse('${SettingsScreen._repoUrl}/issues/new')),
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
      ),
    );
  }

  Widget _buildSignInTile() {
    return ListTile(
      leading: const Icon(Icons.cloud_sync_rounded,
          color: AppTheme.onDarkSecondary),
      title: const Text('Sign in with Google',
          style: TextStyle(color: AppTheme.onDark)),
      subtitle: const Text('Sync playlists & favorites across devices',
          style: TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
      trailing: _signingIn
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _signIn,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.fallbackAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor:
                    AppTheme.fallbackAccent.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sign in'),
            ),
    );
  }

  Widget _buildSignedInSection(String name, String email) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.fallbackAccent.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.fallbackAccent, size: 18),
          ),
          title: Text(name.isNotEmpty ? name : email,
              style: const TextStyle(color: AppTheme.onDark)),
          subtitle: name.isNotEmpty
              ? Text(email,
                  style: const TextStyle(
                      color: AppTheme.onDarkSecondary, fontSize: 12))
              : null,
          trailing: TextButton(
            onPressed: _signOut,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.onDarkSecondary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Sign out'),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.cloud_upload_rounded,
              color: AppTheme.onDarkSecondary),
          title: const Text('Backup now',
              style: TextStyle(color: AppTheme.onDark)),
          subtitle: const Text('Save data to cloud',
              style:
                  TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
          trailing: _backingUp
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.onDarkSecondary),
          onTap: _backingUp ? null : _backup,
        ),
        ListTile(
          leading: const Icon(Icons.cloud_download_rounded,
              color: AppTheme.onDarkSecondary),
          title: const Text('Restore from cloud',
              style: TextStyle(color: AppTheme.onDark)),
          subtitle: const Text('Restore playlists & favorites',
              style:
                  TextStyle(color: AppTheme.onDarkSecondary, fontSize: 12)),
          trailing: _restoring
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.onDarkSecondary),
          onTap: _restoring ? null : _restore,
        ),
      ],
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
