import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneverse/core/di/cast_providers.dart';
import 'package:tuneverse/core/di/favorites_provider.dart';
import 'package:tuneverse/core/di/profile_providers.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/data/models/playlist_entity.dart';
import 'package:tuneverse/data/models/profile_entity.dart';
import 'package:tuneverse/data/models/track_entity.dart';
import 'package:tuneverse/data/repositories/profile_repository.dart';
import 'package:tuneverse/domain/entities/track.dart';
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

  // Migrate legacy isFavorite flags to the active profile's favoriteSourceIds
  if (activeProfile.favoriteSourceIds.isEmpty) {
    final legacyFavs = await isar.trackEntitys
        .filter()
        .isFavoriteEqualTo(true)
        .findAll();
    if (legacyFavs.isNotEmpty) {
      activeProfile.favoriteSourceIds =
          legacyFavs.map((e) => e.sourceId).toList();
      await isar.writeTxn(() async {
        await isar.profileEntitys.put(activeProfile);
      });
    }
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

      final handler = ref.read(audioHandlerProvider);

      // Sync nowPlayingProvider with handler's current track on queue advance
      handler.mediaItem.listen((item) {
        if (item == null) return;
        final current = ref.read(nowPlayingProvider);
        if (current?.sourceId == item.id) return;
        ref.read(nowPlayingProvider.notifier).state = Track(
          id: '',
          title: item.title,
          artist: item.artist ?? '',
          durationMs: item.duration?.inMilliseconds,
          artworkUrl: item.artUri?.toString(),
          sourceType: TrackSourceType.youtube,
          sourceId: item.id,
        );
      });

      // Wire cast mode to notification controls
      final castService = ref.read(castServiceProvider);
      Duration lastCastPos = Duration.zero;
      castService.castPositionStream.listen((pos) => lastCastPos = pos);
      castService.isCastingStream.listen((casting) {
        handler.setCasting(
          casting,
          onSeek: casting
              ? (delta) {
                  final target = lastCastPos + delta;
                  castService.seek(
                      target < Duration.zero ? Duration.zero : target);
                }
              : null,
        );
      });

      // Wire favorite toggle for Android Auto
      handler.setFavoriteCallback(() {
        final track = ref.read(nowPlayingProvider);
        if (track != null) {
          ref.read(toggleFavoriteProvider)(track);
        }
      });
    });
  }

  void _onSetupDone() {
    setState(() => _setupComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final accent = profile != null
        ? Color(profile.accentColorValue)
        : AppTheme.fallbackAccent;
    final theme = AppTheme.dark(accent);

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
