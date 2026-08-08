import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tuneverse/core/di/providers.dart';
import 'package:tuneverse/core/theme/app_theme.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  AndroidEqualizerParameters? _params;

  static const _presets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass Boost': [5.0, 3.5, 0.0, 0.0, 0.0],
    'Treble Boost': [0.0, 0.0, 0.0, 3.5, 5.0],
    'Vocal': [-1.0, 2.0, 4.0, 2.0, -1.0],
    'Rock': [4.0, 2.0, -1.0, 2.0, 4.0],
    'Pop': [-1.0, 1.0, 3.0, 1.0, -1.0],
  };

  @override
  void initState() {
    super.initState();
    _loadParams();
  }

  Future<void> _loadParams() async {
    final handler = ref.read(audioHandlerProvider);
    final params = await handler.equalizer.parameters;
    if (mounted) setState(() => _params = params);
  }

  void _applyPreset(List<double> gains) {
    if (_params == null) return;
    for (var i = 0; i < _params!.bands.length && i < gains.length; i++) {
      final clamped = gains[i].clamp(_params!.minDecibels, _params!.maxDecibels);
      _params!.bands[i].setGain(clamped);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final enabled = handler.equalizer.enabled;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.onDark,
        title: const Text('Equalizer'),
        actions: [
          Switch(
            value: enabled,
            onChanged: (v) {
              handler.equalizer.setEnabled(v);
              setState(() {});
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _params == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _presets.entries
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(e.key),
                                  selected: false,
                                  onSelected: enabled
                                      ? (_) => _applyPreset(e.value)
                                      : null,
                                  labelStyle: TextStyle(
                                    color: enabled
                                        ? AppTheme.onDark
                                        : AppTheme.onDarkSecondary,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: AppTheme.surfaceElevated,
                                  selectedColor: AppTheme.surfaceElevated,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _params!.bands.map((band) {
                        return _BandSlider(
                          band: band,
                          min: _params!.minDecibels,
                          max: _params!.maxDecibels,
                          enabled: enabled,
                          onChanged: (v) => setState(() {}),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  final AndroidEqualizerBand band;
  final double min;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.band,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  String _formatFreq(double hz) {
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)}k';
    return '${hz.round()}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${band.gain.toStringAsFixed(1)} dB',
          style: TextStyle(
            color: enabled ? AppTheme.onDark : AppTheme.onDarkSecondary,
            fontSize: 11,
          ),
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: enabled
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.onDarkSecondary,
                inactiveTrackColor: AppTheme.surfaceElevated,
                thumbColor: enabled
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.onDarkSecondary,
              ),
              child: Slider(
                value: band.gain,
                min: min,
                max: max,
                onChanged: enabled
                    ? (v) {
                        band.setGain(v);
                        onChanged(v);
                      }
                    : null,
              ),
            ),
          ),
        ),
        Text(
          _formatFreq(band.centerFrequency),
          style: const TextStyle(
            color: AppTheme.onDarkSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
