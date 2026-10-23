import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';
import 'package:loqta/features/auth/domain/usecases/send_password_reset_email_usecase.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._sendResetEmailUseCase)
    : super(const ForgotPasswordInitial()) {
    on<ResetEmailSubmitted>(_onResetEmailSubmitted);
  }

  final SendPasswordResetEmailUseCase _sendResetEmailUseCase;

  Future<void> _onResetEmailSubmitted(
    ResetEmailSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordInProgress());
    try {
      await _sendResetEmailUseCase(event.email);
      emit(ForgotPasswordEmailSent(email: event.email));
    } on AuthFailure catch (e) {
      emit(ForgotPasswordFailure(e.message));
    } on Exception {
      emit(
        const ForgotPasswordFailure('Something went wrong. Please try again.'),
      );
    }
  }
}

abstract class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => [];
}

class ResetEmailSubmitted extends ForgotPasswordEvent {
  const ResetEmailSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordInProgress extends ForgotPasswordState {
  const ForgotPasswordInProgress();
}

class ForgotPasswordEmailSent extends ForgotPasswordState {
  const ForgotPasswordEmailSent({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class ForgotPasswordFailure extends ForgotPasswordState {
  const ForgotPasswordFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
