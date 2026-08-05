import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/di/youtube_providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';
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
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        color: AppTheme.onDark,
                        onPressed: () {},
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

                // Track info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
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
