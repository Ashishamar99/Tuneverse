import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final (isar, handler) = await initServices();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const TuneVerseApp(),
    ),
  );
}

class TuneVerseApp extends ConsumerWidget {
  const TuneVerseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'TuneVerse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(AppTheme.fallbackAccent),
      routerConfig: appRouter,
    );
  }
}
