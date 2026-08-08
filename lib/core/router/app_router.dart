import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuneverse/core/di/playlist_providers.dart';
import 'package:tuneverse/core/di/resolver_providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/data/sources/resolver/link_parser.dart';
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/presentation/home/home_screen.dart';
import 'package:tuneverse/presentation/library/library_screen.dart';
import 'package:tuneverse/presentation/player/player_screen.dart';
import 'package:tuneverse/presentation/profiles/profiles_screen.dart';
import 'package:tuneverse/presentation/equalizer/equalizer_screen.dart';
import 'package:tuneverse/presentation/playlist/playlist_detail_screen.dart';
import 'package:tuneverse/presentation/playlist/playlist_edit_screen.dart';
import 'package:tuneverse/presentation/queue/queue_screen.dart';
import 'package:tuneverse/presentation/search/search_screen.dart';
import 'package:tuneverse/presentation/settings/settings_screen.dart';
import 'package:tuneverse/presentation/import/import_playlist_screen.dart';
import 'package:tuneverse/presentation/shared/widgets/scaffold_with_nav.dart';

class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const library = '/library';
  static const profiles = '/profiles';
  static const player = '/player';
  static const queue = '/queue';
  static const equalizer = '/equalizer';
  static const settings = '/settings';
  static const resolve = '/resolve';
  static const importPlaylist = '/import';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: AppRoutes.library,
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/playlist/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return PlaylistDetailScreen(playlistId: id);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.player,
      pageBuilder: (context, state) => CustomTransitionPage(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        child: const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation);
          final fade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.queue,
      builder: (context, state) => const QueueScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.equalizer,
      builder: (context, state) => const EqualizerScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.profiles,
      builder: (context, state) => const ProfilesScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.importPlaylist,
      builder: (context, state) => const ImportPlaylistScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/playlist/:id/edit',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return PlaylistEditScreen(playlistId: id);
      },
    ),
    // Deep link handler for universal link resolver
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.resolve,
      builder: (context, state) {
        final url = state.uri.queryParameters['url'] ?? '';
        // ResolveScreen handles the link and navigates to player
        return ResolveRedirectScreen(url: url);
      },
    ),
  ],
);

class ResolveRedirectScreen extends ConsumerStatefulWidget {
  final String url;
  const ResolveRedirectScreen({super.key, required this.url});

  @override
  ConsumerState<ResolveRedirectScreen> createState() =>
      _ResolveRedirectScreenState();
}

class _ResolveRedirectScreenState extends ConsumerState<ResolveRedirectScreen> {
  String? _error;
  String? _status;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final parsed = LinkParser.parse(widget.url);
      final isPlaylist = parsed?.type == LinkType.playlist;

      if (isPlaylist) {
        setState(() => _status = 'Importing playlist...');
      }

      final resolver = ref.read(universalResolverProvider);
      final tracks = await resolver.resolve(widget.url);

      if (!mounted) return;

      if (tracks.isEmpty) {
        setState(() => _error = 'Could not resolve this link');
        return;
      }

      if (isPlaylist && tracks.length > 1) {
        await _importAsPlaylist(tracks, parsed);
      } else {
        ref.read(playTrackProvider)(tracks.first);
        context.go(AppRoutes.home);
        context.push(AppRoutes.player);
      }
    } on UnsupportedError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _importAsPlaylist(List<Track> tracks, ParsedLink? parsed) async {
    final playlistName = parsed?.platform.name ?? 'Imported';
    final label = 'Imported ($playlistName) — ${tracks.length} tracks';

    final createPlaylist = ref.read(createPlaylistProvider);
    final addToPlaylist = ref.read(addToPlaylistProvider);

    final playlist = await createPlaylist(label);
    for (final track in tracks) {
      await addToPlaylist(playlist.id, track);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${tracks.length} tracks as "$label"')),
    );
    context.go(AppRoutes.library);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Go Home'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Text(_status!,
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ],
              ),
      ),
    );
  }
}
