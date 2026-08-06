import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneverse/core/di/providers.dart';

class SleepTimerState {
  final Duration remaining;
  final Duration total;
  final bool active;

  const SleepTimerState({
    this.remaining = Duration.zero,
    this.total = Duration.zero,
    this.active = false,
  });

  double get progress =>
      total.inSeconds > 0 ? remaining.inSeconds / total.inSeconds : 0;

  String get label {
    if (!active) return '';
    final m = remaining.inMinutes;
    final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref _ref;
  Timer? _timer;

  SleepTimerNotifier(this._ref) : super(const SleepTimerState());

  void start(Duration duration) {
    cancel();
    state = SleepTimerState(
      remaining: duration,
      total: duration,
      active: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remaining - const Duration(seconds: 1);
      if (next.inSeconds <= 0) {
        _ref.read(audioHandlerProvider).pause();
        cancel();
      } else {
        state = SleepTimerState(
          remaining: next,
          total: state.total,
          active: true,
        );
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = const SleepTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>(
  (ref) => SleepTimerNotifier(ref),
);
