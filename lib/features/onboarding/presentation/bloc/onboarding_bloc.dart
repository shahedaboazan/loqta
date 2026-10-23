import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Number of onboarding pages in the approved design.
const int kOnboardingPageCount = 3;

/// Drives the onboarding flow and owns the persisted "onboarding completed"
/// flag.
///
/// The bloc only reports intent; deciding which screen to show is the job of
/// the auth gate, which keeps a single source of truth for routing and avoids
/// the duplicate-navigation race that occurs when pages push each other.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required this.repository})
    : super(OnboardingState.initial()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingNextRequested>(_onNext);
    on<OnboardingBackRequested>(_onBack);
    on<OnboardingSkipRequested>(_onSkip);
  }

  /// Exposed for tests; the flow itself only uses it internally.
  final OnboardingRepository repository;

  Future<void> _onStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) async {
    final completed = await repository.isOnboardingCompleted();
    emit(
      state.copyWith(
        status: completed
            ? OnboardingStatus.completed
            : OnboardingStatus.inProgress,
        pageIndex: 0,
      ),
    );
  }

  Future<void> _onNext(
    OnboardingNextRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    // Ignore presses while the flag is still being read, or after the flow
    // has already been completed, so the flow cannot advance twice.
    if (state.status != OnboardingStatus.inProgress) return;

    final nextIndex = state.pageIndex + 1;
    if (nextIndex < kOnboardingPageCount) {
      emit(state.copyWith(pageIndex: nextIndex));
      return;
    }
    await _finish(emit);
  }

  void _onBack(OnboardingBackRequested event, Emitter<OnboardingState> emit) {
    if (state.status != OnboardingStatus.inProgress) return;
    if (state.pageIndex == 0) return;
    emit(state.copyWith(pageIndex: state.pageIndex - 1));
  }

  Future<void> _onSkip(
    OnboardingSkipRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state.status != OnboardingStatus.inProgress) return;
    await _finish(emit);
  }

  /// Persists the flag first, then flips the state. Persisting first means the
  /// state never claims "completed" for a write that did not land, so a crash
  /// mid-transition replays onboarding instead of dropping the user into
  /// sign-in with no memory of it.
  Future<void> _finish(Emitter<OnboardingState> emit) async {
    await repository.completeOnboarding();
    emit(state.copyWith(status: OnboardingStatus.completed, pageIndex: 0));
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => const [];
}

/// Reads the persisted onboarding flag. Dispatched once at startup.
class OnboardingStarted extends OnboardingEvent {
  const OnboardingStarted();
}

/// Moves to the next page, or completes onboarding on the last page.
class OnboardingNextRequested extends OnboardingEvent {
  const OnboardingNextRequested();
}

/// Moves to the previous page. Ignored on the first page, where the reference
/// design offers no back affordance.
class OnboardingBackRequested extends OnboardingEvent {
  const OnboardingBackRequested();
}

/// Skips onboarding, marking it completed.
class OnboardingSkipRequested extends OnboardingEvent {
  const OnboardingSkipRequested();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum OnboardingStatus {
  /// The flag has not been read yet. The gate must keep showing splash.
  loading,

  /// Onboarding has not been completed; show the onboarding flow.
  inProgress,

  /// Onboarding is done; show sign-in.
  completed,
}

class OnboardingState extends Equatable {
  const OnboardingState({required this.status, required this.pageIndex});

  const OnboardingState.initial()
    : status = OnboardingStatus.loading,
      pageIndex = 0;

  final OnboardingStatus status;

  /// Zero-based index of the visible onboarding page.
  final int pageIndex;

  bool get isShowingOnboarding => status == OnboardingStatus.inProgress;

  OnboardingState copyWith({OnboardingStatus? status, int? pageIndex}) {
    return OnboardingState(
      status: status ?? this.status,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }

  @override
  List<Object?> get props => [status, pageIndex];
}
