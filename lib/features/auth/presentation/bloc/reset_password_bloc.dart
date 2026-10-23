import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';
import 'package:loqta/features/auth/domain/usecases/reset_password_usecase.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc(this._resetPasswordUseCase)
    : super(const ResetPasswordInitial()) {
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
  }

  final ResetPasswordUseCase _resetPasswordUseCase;

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(const ResetPasswordInProgress());
    try {
      await _resetPasswordUseCase(newPassword: event.newPassword);
      emit(const ResetPasswordSuccess());
    } on AuthFailure catch (e) {
      emit(ResetPasswordFailure(e.message));
    } on Exception {
      emit(
        const ResetPasswordFailure('Something went wrong. Please try again.'),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted({required this.newPassword});

  final String newPassword;

  @override
  List<Object?> get props => [newPassword];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

abstract class ResetPasswordState extends Equatable {
  const ResetPasswordState();

  @override
  List<Object?> get props => [];
}

class ResetPasswordInitial extends ResetPasswordState {
  const ResetPasswordInitial();
}

class ResetPasswordInProgress extends ResetPasswordState {
  const ResetPasswordInProgress();
}

class ResetPasswordSuccess extends ResetPasswordState {
  const ResetPasswordSuccess();
}

class ResetPasswordFailure extends ResetPasswordState {
  const ResetPasswordFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
