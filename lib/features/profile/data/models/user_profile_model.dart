import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:loqta/features/profile/domain/entities/user_profile.dart';

import 'dart:typed_data';

/// Maps a `profiles` row to the domain entity.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    super.firstName,
    super.lastName,
    super.avatarUrl,
    super.governorate,
    super.area,
    super.phoneNumber,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String? ?? '',
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      governorate: map['governorate'] as String?,
      area: map['area'] as String?,
      // `phone_number` is added by the profile migration. Reading it
      // defensively means an account created before that migration still
      // resolves rather than throwing.
      phoneNumber: map['phone_number'] as String?,
    );
  }

  /// The column set written by [ProfileRemoteDataSource.updateProfile].
  ///
  /// `email` is not present: it belongs to Supabase auth, not this table.
  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'governorate': governorate,
      'area': area,
      'phone_number': phoneNumber,
    };
  }

  /// Upserts a profile for a user whose row does not exist yet.
  static UserProfileModel empty(String id) => UserProfileModel(id: id);
}

/// Supabase access for the `profiles` table.
///
/// This is the only place in the app that touches `public.profiles` directly;
/// widgets go through [ProfileRepository] so the RLS boundary stays in the data
/// layer.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'profiles';

  /// The signed-in user's id, or null when there is no session.
  ///
  /// Every read and write is implicitly scoped to this by RLS; the id is needed
  /// only for the insert-if-missing fallback.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Reads the signed-in user's own row.
  ///
  /// Returns null when the account has no profile row yet, which is a valid
  /// state rather than an error.
  Future<UserProfileModel?> fetchCurrentProfile() async {
    final userId = currentUserId;

    if (userId == null || userId.isEmpty) {
      return null;
    }

    final response = await _client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response == null ? null : UserProfileModel.fromMap(response);
  }

  /// Writes the editable profile fields for the signed-in user.
  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    final response = await _client
        .from(_table)
        .update(profile.toUpdateMap())
        .eq('id', profile.id)
        .select()
        .maybeSingle();

    // A null response means no row was matched. The `profiles_update_self` RLS
    // policy means that can only happen when the profile row does not exist, so
    // insert it rather than reporting a phantom success.
    if (response != null) return UserProfileModel.fromMap(response);

    final inserted = await _client
        .from(_table)
        .insert(<String, dynamic>{'id': profile.id, ...profile.toUpdateMap()})
        .select()
        .single();
    return UserProfileModel.fromMap(inserted);
  }

  Future<UserProfileModel> updateAvatar(String? avatarUrl) async {
    final userId = currentUserId;

    if (userId == null || userId.isEmpty) {
      throw Exception('User is not authenticated.');
    }

    final response = await _client
        .from(_table)
        .update({'avatar_url': avatarUrl})
        .eq('id', userId)
        .select()
        .maybeSingle();

    if (response != null) {
      return UserProfileModel.fromMap(response);
    }

    final inserted = await _client
        .from(_table)
        .insert({'id': userId, 'avatar_url': avatarUrl})
        .select()
        .single();

    return UserProfileModel.fromMap(inserted);
  }

  Future<String> uploadAvatarImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = currentUserId;

    if (userId == null || userId.isEmpty) {
      throw Exception('User is not authenticated.');
    }

    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';

    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    final safeExtension = allowedExtensions.contains(extension)
        ? extension
        : 'jpg';

    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final path =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
