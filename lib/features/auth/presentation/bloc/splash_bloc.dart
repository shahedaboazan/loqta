import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// How long the Flutter splash screen stays on screen at startup.
///
/// The splash is the first thing the user sees, so it has to be on screen
/// long enough to be read. This is a floor, not a delay: the splash is
/// replaced as soon as the app is ready *and* this minimum has passed.
const Duration kMinimumSplashDuration = Duration(seconds: 12);

/// Keeps the Flutter splash screen on screen for a minimum amount of time.
///
/// Without it the splash is skipped whenever the session and the onboarding
/// flag happen to resolve before the first frame is drawn, which is what
/// makes the app appear to start straight on the sign-in or home screen.
///
/// The clock starts when the bloc is created, which is when the app starts,
/// so the splash is on screen for the full minimum no matter how quickly the
/// session is restored.
///
/// The bloc only decides *when the splash may be replaced*; it never decides
/// where the app goes. That stays with the auth gate.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc({this.minimumDuration = kMinimumSplashDuration})
    : super(const SplashState.visible()) {
    on<SplashStarted>(_onStarted);

    if (minimumDuration > Duration.zero) {
      final waiter = Completer<void>();
      _waiter = waiter;
      _timer = Timer(minimumDuration, () {
        if (!waiter.isCompleted) waiter.complete();
      });
    }
  }

  /// The shortest time the splash is allowed to stay on screen.
  final Duration minimumDuration;

  Timer? _timer;
  Completer<void>? _waiter;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    if (state.isFinished) return;
    final waiter = _waiter;
    if (waiter != null) await waiter.future;
    if (!isClosed) emit(const SplashState.finished());
  }

  @override
  Future<void> close() {
    // Release the pending wait so the handler can finish, and drop the timer
    // so no timer is left behind when the app shuts down.
    _timer?.cancel();
    _timer = null;
    final waiter = _waiter;
    if (waiter != null && !waiter.isCompleted) waiter.complete();
    return super.close();
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => const [];
}

/// Starts the splash screen. Dispatched once at startup.
class SplashStarted extends SplashEvent {
  const SplashStarted();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SplashState extends Equatable {
  const SplashState.visible() : isFinished = false;

  const SplashState.finished() : isFinished = true;

  /// Whether the splash may be replaced by the app's first screen.
  final bool isFinished;

  @override
  List<Object?> get props => [isFinished];
}
