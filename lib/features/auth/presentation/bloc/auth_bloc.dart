import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/usecases/sign_out_usecase.dart';

/// How long the bloc waits for the auth stream to report the restored
/// session before it falls back to the locally stored one.
///
/// The stream is the only trustworthy source: it carries the session the
/// repository confirmed with the backend. The fallback exists purely so the
/// app can never be stuck on the splash screen.
const Duration kSessionRestorationTimeout = Duration(seconds: 15);

/// Manages the authentication session lifecycle:
/// restoration on startup, session changes and sign out.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this._authUserStream,
    required this._currentUser,
    required this._signOutUseCase,
  }) : super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<SignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);

    // The repository stream emits the persisted session immediately,
    // which restores the session on app restart. The first value is the
    // restored session, already confirmed with the backend by the
    // repository, so the app only learns about it once it is known to be
    // valid.
    //
    // The stream now emits either AuthUser?, PasswordRecoverySession, or null.
    _subscription = _authUserStream.listen(
      (event) {
        _recordFirstSession(event);
        add(_AuthUserChanged(event));
      },
      // Network errors during token refresh are emitted as stream errors
      // by the underlying client; they must not crash the app.
      onError: (_, _) {
        _recordFirstSession(null, timedOut: true);
      },
    );
  }

  final Stream<Object?> _authUserStream;
  final AuthUser? Function() _currentUser;
  final SignOutUseCase _signOutUseCase;
  StreamSubscription<Object?>? _subscription;

  /// The first value of the auth stream, once it has arrived.
  _RestoredSession? _firstSession;

  /// Completes as soon as the first value of the auth stream arrives.
  Completer<_RestoredSession>? _firstSessionCompleter;

  /// Guards the splash screen from waiting forever for the stream.
  Timer? _restorationTimer;

  void _recordFirstSession(Object? event, {bool timedOut = false}) {
    if (_firstSession != null) return;
    AuthUser? user;
    if (event is PasswordRecoverySession) {
      user = event.user;
    } else if (event is AuthUser) {
      user = event;
    }
    final session = timedOut
        ? const _RestoredSession.timedOut()
        : _RestoredSession.value(user);
    _firstSession = session;
    _restorationTimer?.cancel();
    _restorationTimer = null;
    final completer = _firstSessionCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(session);
    }
  }

  /// Waits for the first value of the auth stream.
  ///
  /// Resolves with the restored session, or with a timeout when the stream
  /// produced nothing at all, so the caller can fall back to the locally
  /// stored session instead of leaving the app on the splash screen.
  Future<_RestoredSession> _awaitFirstSession() {
    final known = _firstSession;
    if (known != null) return Future<_RestoredSession>.value(known);

    final completer = Completer<_RestoredSession>();
    _firstSessionCompleter = completer;
    _restorationTimer?.cancel();
    _restorationTimer = Timer(kSessionRestorationTimeout, () {
      _recordFirstSession(null, timedOut: true);
    });
    return completer.future;
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    // The stream may already have delivered the persisted session
    // (it replays its last event to new subscribers) before this
    // event is processed; only show the splash state when nothing
    // has been resolved yet.
    if (state is AuthInitial) {
      emit(const AuthSessionRestoring());
    }
    // The restored session is confirmed with the backend before the app
    // treats it as a sign-in, so the splash stays on screen until the
    // session is known to be good.
    final restored = await _awaitFirstSession();
    if (isClosed) return;
    if (restored.timedOut) {
      // The stream never reported a session. Fall back to the locally stored
      // one rather than leaving the user on the splash screen.
      final cached = _currentUser();
      emit(cached == null ? const Unauthenticated() : Authenticated(cached));
      return;
    }
    final user = restored.user;
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _signOutUseCase();
    } on Exception {
      // The local session is cleared even if the remote sign-out request
      // fails; treat the user as signed out either way.
    }
    // No restoring state in between: the sign-out is quick and returning to
    // the splash screen here would only flash the splash at a user who is
    // already on their way out.
    add(const _AuthUserChanged(null));
  }

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final userOrRecovery = event.user;
    if (userOrRecovery == null) {
      emit(const Unauthenticated());
    } else if (userOrRecovery is PasswordRecoverySession) {
      emit(PasswordRecovery(userOrRecovery.user));
    } else if (userOrRecovery is AuthUser) {
      emit(Authenticated(userOrRecovery));
    }
  }

  @override
  Future<void> close() {
    _restorationTimer?.cancel();
    _restorationTimer = null;
    _subscription?.cancel();
    return super.close();
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Restores the persisted Supabase session on app startup.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Signs the current user out.
class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final Object? user;

  @override
  List<Object?> get props => [user];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthSessionRestoring extends AuthState {
  const AuthSessionRestoring();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// Emitted when a password-recovery session is active. The user has clicked
/// the recovery link in the email and the app should show the Reset Password
/// screen (without OTP).
class PasswordRecovery extends AuthState {
  const PasswordRecovery(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// The first value of the auth stream.
class _RestoredSession {
  const _RestoredSession.value(this.user) : timedOut = false;

  const _RestoredSession.timedOut() : user = null, timedOut = true;

  /// The restored user, or `null` when the stream reported no session.
  final AuthUser? user;

  /// Whether the stream failed to report anything at all.
  final bool timedOut;
}
