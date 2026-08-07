import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/repositories/profile_repository.dart';
import 'package:tuneverse/presentation/onboarding/permission_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final dir = await getApplicationDocumentsDirectory();
  final setupDone = File('${dir.path}/.setup_done').existsSync();

  final (isar, handler) = await initServices();

  // Resolve active profile and migrate playlists from 'default' to real ID
  final profileRepo = ProfileRepository(isar);
  final activeProfile = await profileRepo.ensureDefault();
  final activeProfileId = activeProfile.id.toString();

  final stalePlayists = await isar.playlistEntitys
      .filter()
      .profileIdEqualTo('default')
      .findAll();
  if (stalePlayists.isNotEmpty) {
    await isar.writeTxn(() async {
      for (final pl in stalePlayists) {
        pl.profileId = activeProfileId;
      }
      await isar.playlistEntitys.putAll(stalePlayists);
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: TuneVerseApp(
        setupDone: setupDone,
        initialProfileId: activeProfileId,
      ),
    ),
  );
}

class TuneVerseApp extends ConsumerStatefulWidget {
  final bool setupDone;
  final String initialProfileId;
  const TuneVerseApp({
    super.key,
    required this.setupDone,
    required this.initialProfileId,
  });

  @override
  ConsumerState<TuneVerseApp> createState() => _TuneVerseAppState();
}

class _TuneVerseAppState extends ConsumerState<TuneVerseApp> {
  late bool _setupComplete;

  @override
  void initState() {
    super.initState();
    _setupComplete = widget.setupDone;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeProfileIdProvider.notifier).state =
          widget.initialProfileId;
    });
  }

  void _onSetupDone() {
    setState(() => _setupComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.dark(AppTheme.fallbackAccent);

    if (!_setupComplete) {
      return MaterialApp(
        title: 'TuneVerse',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: PermissionScreen(onComplete: _onSetupDone),
      );
    }

    return MaterialApp.router(
      title: 'TuneVerse',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: appRouter,
    );
  }
}
