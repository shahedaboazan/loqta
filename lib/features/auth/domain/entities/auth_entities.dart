import 'package:equatable/equatable.dart';

/// Authentication user exposed to the presentation layer.
///
/// This entity is intentionally free of any Supabase or Flutter SDK types.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? email : full;
  }

  String get firstNameOrEmail =>
      (firstName != null && firstName!.trim().isNotEmpty)
      ? firstName!.trim()
      : email;

  @override
  List<Object?> get props => [id, email, firstName, lastName];
}
