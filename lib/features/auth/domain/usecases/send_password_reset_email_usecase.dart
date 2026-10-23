import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future call(String email) => _repository.sendPasswordResetEmail(email);
}
