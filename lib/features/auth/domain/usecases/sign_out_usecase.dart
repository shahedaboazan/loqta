import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  Future call() => _repository.signOut();
}
