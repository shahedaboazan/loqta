import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';
import 'package:loqta/features/auth/domain/usecases/sign_in_usecase.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this._signInUseCase) : super(const SignInInitial()) {
    on<SignInSubmitted>(_onSignInSubmitted);
  }

  final SignInUseCase _signInUseCase;

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInProgress());
    try {
      await _signInUseCase(email: event.email, password: event.password);
      emit(const SignInSuccess());
    } on AuthFailure catch (e) {
      emit(SignInFailure(e.message));
    } on Exception {
      emit(const SignInFailure('Something went wrong. Please try again.'));
    }
  }
}

abstract class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => [];
}

class SignInSubmitted extends SignInEvent {
  const SignInSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

abstract class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => [];
}

class SignInInitial extends SignInState {
  const SignInInitial();
}

class SignInProgress extends SignInState {
  const SignInProgress();
}

class SignInSuccess extends SignInState {
  const SignInSuccess();
}

class SignInFailure extends SignInState {
  const SignInFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
