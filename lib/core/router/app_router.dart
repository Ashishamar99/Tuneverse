import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class ResolveRedirectScreen extends StatelessWidget {
  final String url;
  const ResolveRedirectScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // Placeholder — Phase 4 will implement the full resolver
    return const Scaffold(
      backgroundColor: Color(0xFF080808),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
