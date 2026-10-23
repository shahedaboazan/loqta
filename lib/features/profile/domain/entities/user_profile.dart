import 'package:equatable/equatable.dart';

/// A public user profile.
///
/// Mirrors the `profiles` table. Like [Listing], it carries only public
/// location ([governorate]/[area]) — a profile never exposes a pickup address.
///
/// [phoneNumber] is optional profile information used to coordinate a handoff.
/// It is never an authentication factor and the app has no phone verification.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.governorate,
    this.area,
    this.phoneNumber,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? governorate;
  final String? area;
  final String? phoneNumber;

  /// "Shahed Aboazan", or the local-part of the email when no name is set.
  ///
  /// Returns an empty string when both are missing so callers can decide
  /// between a placeholder and a glyph.
  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full;
  }

  /// The name to render, never blank — falls back to a neutral marker the UI
  /// turns into a generic avatar.
  String get displayNameOrPlaceholder {
    final name = displayName;
    return name.isEmpty ? '?' : name;
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? governorate,
    String? area,
    String? phoneNumber,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    avatarUrl,
    governorate,
    area,
    phoneNumber,
  ];
}
