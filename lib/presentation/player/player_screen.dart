import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:tuneverse/core/di/favorites_provider.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/sleep_timer_provider.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/router/app_router.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
import 'package:tuneverse/domain/entities/track.dart';
import 'package:tuneverse/presentation/player/waveform_visualiser.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(nowPlayingProvider);
    if (track == null) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    final handler = ref.watch(audioHandlerProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient glow background
          if (track.artworkUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Opacity(
                  opacity: 0.25,
                  child: CachedNetworkImage(
                    imageUrl: track.artworkUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                        color: AppTheme.onDark,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          color: AppTheme.onDarkSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _SleepTimerButton(),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded),
                        color: AppTheme.onDarkSecondary,
                        onPressed: () => context.push(AppRoutes.queue),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Album art
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Hero(
                    tag: 'album-art-${track.sourceId}',
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusArt),
                        child: track.artworkUrl != null
                            ? CachedNetworkImage(
                                imageUrl: track.artworkUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppTheme.surfaceElevated,
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: AppTheme.onDarkSecondary,
                                  size: 64,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Fluid sine wave visualiser
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: WaveformVisualiser(
                    accentColor: accentColor,
                    height: 60,
                  ),
                ),

                const SizedBox(height: 16),

                // Track info + favorite
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.onDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.onDarkSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _FavoriteButton(track: track),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Seek bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: StreamBuilder<Duration>(
                    stream: handler.positionStream,
                    builder: (context, posSnap) {
                      return StreamBuilder<Duration?>(
                        stream: handler.durationStream,
                        builder: (context, durSnap) {
                          final position = posSnap.data ?? Duration.zero;
                          final duration = durSnap.data ?? Duration.zero;
                          final maxVal = duration.inMilliseconds.toDouble();

                          return Column(
                            children: [
                              SliderTheme(
                                data: Theme.of(context).sliderTheme,
                                child: Slider(
                                  value: maxVal > 0
                                      ? position.inMilliseconds
                                          .toDouble()
                                          .clamp(0, maxVal)
                                      : 0,
                                  max: maxVal > 0 ? maxVal : 1,
                                  onChanged: (value) {
                                    handler.seek(
                                      Duration(milliseconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(
                                        color: AppTheme.onDarkSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(
                                        color: AppTheme.onDarkSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle
                      StreamBuilder<bool>(
                        stream: handler.player.shuffleModeEnabledStream,
                        builder: (context, snap) {
                          final on = snap.data ?? false;
                          return IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: on ? accentColor : AppTheme.onDarkSecondary,
                            ),
                            onPressed: () {
                              handler.player.setShuffleModeEnabled(!on);
                            },
                          );
                        },
                      ),

                      // Previous
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: AppTheme.onDark,
                          size: 36,
                        ),
                        onPressed: handler.skipToPrevious,
                      ),

                      // Play / Pause
                      StreamBuilder<PlaybackState>(
                        stream: handler.playbackState,
                        builder: (context, snap) {
                          final playing = snap.data?.playing ?? false;
                          return _AnimatedPlayButton(
                            playing: playing,
                            accentColor: accentColor,
                            onPressed: () {
                              if (playing) {
                                handler.pause();
                              } else {
                                handler.play();
                              }
                            },
                          );
                        },
                      ),

                      // Next
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: AppTheme.onDark,
                          size: 36,
                        ),
                        onPressed: handler.skipToNext,
                      ),

                      // Loop mode
                      StreamBuilder<LoopMode>(
                        stream: handler.player.loopModeStream,
                        builder: (context, snap) {
                          final mode = snap.data ?? LoopMode.off;
                          IconData icon;
                          Color color;
                          switch (mode) {
                            case LoopMode.off:
                              icon = Icons.repeat_rounded;
                              color = AppTheme.onDarkSecondary;
                            case LoopMode.all:
                              icon = Icons.repeat_rounded;
                              color = accentColor;
                            case LoopMode.one:
                              icon = Icons.repeat_one_rounded;
                              color = accentColor;
                          }
                          return IconButton(
                            icon: Icon(icon, color: color),
                            onPressed: () {
                              final next = LoopMode.values[
                                  (mode.index + 1) % LoopMode.values.length];
                              handler.player.setLoopMode(next);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AnimatedPlayButton extends StatefulWidget {
  final bool playing;
  final Color accentColor;
  final VoidCallback onPressed;

  const _AnimatedPlayButton({
    required this.playing,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<_AnimatedPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.accentColor,
          ),
          child: Icon(
            widget.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppTheme.contrastColor(widget.accentColor),
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final Track track;
  const _FavoriteButton({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(track.sourceId));

    return IconButton(
      icon: Icon(
        isFav.valueOrNull == true
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        color: isFav.valueOrNull == true
            ? Colors.redAccent
            : AppTheme.onDarkSecondary,
      ),
      onPressed: () => ref.read(toggleFavoriteProvider)(track),
    );
  }
}

class _SleepTimerButton extends ConsumerWidget {
  static const _options = [
    (label: '15 min', duration: Duration(minutes: 15)),
    (label: '30 min', duration: Duration(minutes: 30)),
    (label: '45 min', duration: Duration(minutes: 45)),
    (label: '1 hour', duration: Duration(hours: 1)),
    (label: '2 hours', duration: Duration(hours: 2)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);

    return GestureDetector(
      onTap: () => _showDialog(context, ref, timer.active),
      child: timer.active
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timer.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.bedtime_outlined),
              color: AppTheme.onDarkSecondary,
              onPressed: () => _showDialog(context, ref, false),
            ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref, bool isActive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep Timer',
              style: TextStyle(
                color: AppTheme.onDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._options.map((opt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt.label,
                    style: const TextStyle(color: AppTheme.onDark),
                  ),
                  onTap: () {
                    ref.read(sleepTimerProvider.notifier).start(opt.duration);
                    Navigator.pop(ctx);
                  },
                )),
            if (isActive)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Cancel timer',
                  style: TextStyle(color: Colors.redAccent),
                ),
                leading: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                onTap: () {
                  ref.read(sleepTimerProvider.notifier).cancel();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}
