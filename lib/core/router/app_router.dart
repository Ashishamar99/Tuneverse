import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuneverse/core/di/resolver_providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/presentation/home/home_screen.dart';
import 'package:tuneverse/presentation/library/library_screen.dart';
import 'package:tuneverse/presentation/player/player_screen.dart';
import 'package:tuneverse/presentation/profiles/profiles_screen.dart';
import 'package:tuneverse/presentation/search/search_screen.dart';
import 'package:tuneverse/presentation/shared/widgets/scaffold_with_nav.dart';

class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const library = '/library';
  static const profiles = '/profiles';
  static const player = '/player';
  static const resolve = '/resolve';
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
          path: AppRoutes.profiles,
          builder: (context, state) => const ProfilesScreen(),
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.player,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
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

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final resolver = ref.read(universalResolverProvider);
      final tracks = await resolver.resolve(widget.url);

      if (!mounted) return;

      if (tracks.isNotEmpty) {
        ref.read(playTrackProvider)(tracks.first);
        context.go(AppRoutes.home);
        context.push(AppRoutes.player);
      } else {
        setState(() => _error = 'Could not resolve this link');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
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
            : const CircularProgressIndicator(),
      ),
    );
  }
}
