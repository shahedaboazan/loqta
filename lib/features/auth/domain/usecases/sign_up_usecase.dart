import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _repository.signUpWithEmailAndPassword(
    firstName: firstName,
    lastName: lastName,
    email: email,
    password: password,
  );
}
