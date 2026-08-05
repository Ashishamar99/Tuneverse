import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';

class WaveformVisualiser extends ConsumerStatefulWidget {
  final Color accentColor;
  final double height;

  const WaveformVisualiser({
    super.key,
    required this.accentColor,
    this.height = 80,
  });

  @override
  ConsumerState<WaveformVisualiser> createState() => _WaveformVisualiserState();
}

class _WaveformVisualiserState extends ConsumerState<WaveformVisualiser>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  double _smoothedAmplitude = 0.0;
  static const _smoothingFactor = 0.15;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    final player = ref.read(audioPlayerProvider);
    player.positionStream.listen((_) {
      if (!mounted) return;
      final level = player.playing ? 0.3 + (0.7 * _pseudoAmplitude()) : 0.0;
      _smoothedAmplitude += (_smoothingFactor * (level - _smoothedAmplitude));
    });
  }

  double _pseudoAmplitude() {
    final pos = ref.read(audioPlayerProvider).position;
    final ms = pos.inMilliseconds.toDouble();
    return (math.sin(ms * 0.003) * 0.3 +
            math.sin(ms * 0.007) * 0.3 +
            math.cos(ms * 0.005) * 0.4)
        .abs()
        .clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _SineWavePainter(
              amplitude: _smoothedAmplitude,
              phase: _animController.value * 2 * math.pi,
              accentColor: widget.accentColor,
            ),
          );
        },
      ),
    );
  }
}

class _SineWavePainter extends CustomPainter {
  final double amplitude;
  final double phase;
  final Color accentColor;

  _SineWavePainter({
    required this.amplitude,
    required this.phase,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final waves = [
      _WaveConfig(
        frequency: 1.0,
        phaseOffset: 0,
        opacity: 0.9,
        color: accentColor,
        amplitudeScale: 1.0,
      ),
      _WaveConfig(
        frequency: 1.3,
        phaseOffset: math.pi * 0.4,
        opacity: 0.4,
        color: Color.lerp(accentColor, Colors.white, 0.25)!,
        amplitudeScale: 0.7,
      ),
      _WaveConfig(
        frequency: 0.7,
        phaseOffset: math.pi * 0.8,
        opacity: 0.25,
        color: Color.lerp(accentColor, Colors.black, 0.2)!,
        amplitudeScale: 0.5,
      ),
    ];

    for (final wave in waves) {
      _drawWave(canvas, size, wave);
    }
  }

  void _drawWave(Canvas canvas, Size size, _WaveConfig wave) {
    final paint = Paint()
      ..color = wave.color.withValues(alpha: wave.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path();
    final midY = size.height / 2;
    final maxAmp = size.height * 0.35 * amplitude * wave.amplitudeScale;

    for (int x = 0; x <= size.width.toInt(); x++) {
      final ratio = x / size.width;
      final envelope = math.sin(ratio * math.pi);
      final y = midY +
          maxAmp *
              envelope *
              math.sin(
                ratio * 2 * math.pi * wave.frequency +
                    phase +
                    wave.phaseOffset,
              );

      if (x == 0) {
        path.moveTo(x.toDouble(), y);
      } else {
        path.lineTo(x.toDouble(), y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SineWavePainter oldDelegate) => true;
}

class _WaveConfig {
  final double frequency;
  final double phaseOffset;
  final double opacity;
  final Color color;
  final double amplitudeScale;

  const _WaveConfig({
    required this.frequency,
    required this.phaseOffset,
    required this.opacity,
    required this.color,
    required this.amplitudeScale,
  });
}
