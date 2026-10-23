import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthUser> call({required String email, required String password}) =>
      _repository.signInWithEmailAndPassword(email: email, password: password);
}
