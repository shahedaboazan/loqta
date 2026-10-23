import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/auth/domain/errors/auth_failure.dart';
import 'package:loqta/features/auth/domain/usecases/sign_up_usecase.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc(this._signUpUseCase) : super(const SignUpInitial()) {
    on<SignUpSubmitted>(_onSignUpSubmitted);
  }

  final SignUpUseCase _signUpUseCase;

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<SignUpState> emit,
  ) async {
    emit(const SignUpInProgress());
    try {
      await _signUpUseCase(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
      );
      // Supabase accepted the registration and emailed the confirmation link.
      // The user is not signed in: the next step is confirming the link and
      // then signing in with their password.
      emit(SignUpSuccess(email: event.email));
    } on AuthFailure catch (e) {
      emit(SignUpFailure(e.message));
    } on Exception {
      emit(const SignUpFailure('Something went wrong. Please try again.'));
    }
  }
}

abstract class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object?> get props => [];
}

class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [firstName, lastName, email, password];
}

abstract class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

class SignUpInProgress extends SignUpState {
  const SignUpInProgress();
}

/// The account was created and Supabase sent the confirmation email.
///
/// [email] is shown on the confirmation-pending screen so the user knows which
/// inbox to look in.
class SignUpSuccess extends SignUpState {
  const SignUpSuccess({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class SignUpFailure extends SignUpState {
  const SignUpFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
