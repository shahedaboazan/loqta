import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future call({required String newPassword}) =>
      _repository.resetPassword(newPassword: newPassword);
}
