import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tuneverse/core/di/profile_providers.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/presentation/shared/widgets/mini_player.dart';

class ScaffoldWithNav extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithNav({super.key, required this.child});

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.library)) return 2;
    if (location.startsWith(AppRoutes.profiles)) return 3;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.search);
      case 2:
        context.go(AppRoutes.library);
      case 3:
        context.go(AppRoutes.profiles);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _locationToIndex(context);
    final profile = ref.watch(activeProfileProvider).valueOrNull;
    final emoji = profile?.avatarEmoji;
    final color = profile != null ? Color(profile.accentColorValue) : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => _onDestinationSelected(context, i),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              const NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'Library',
              ),
              NavigationDestination(
                icon: emoji != null
                    ? _AvatarIcon(emoji: emoji, color: color, selected: false)
                    : const Icon(Icons.person_outline_rounded),
                selectedIcon: emoji != null
                    ? _AvatarIcon(emoji: emoji, color: color, selected: true)
                    : const Icon(Icons.person_rounded),
                label: profile?.name ?? 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final String emoji;
  final Color? color;
  final bool selected;

  const _AvatarIcon({
    required this.emoji,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? (color ?? AppTheme.onDark).withValues(alpha: 0.2)
            : Colors.transparent,
        border: selected && color != null
            ? Border.all(color: color!, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
