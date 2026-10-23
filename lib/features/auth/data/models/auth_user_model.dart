import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';

/// Maps Supabase `User` responses to the domain [AuthUser] entity.
class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
  });

  factory AuthUserModel.fromUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      firstName: metadata['first_name'] as String?,
      lastName: metadata['last_name'] as String?,
    );
  }
}
