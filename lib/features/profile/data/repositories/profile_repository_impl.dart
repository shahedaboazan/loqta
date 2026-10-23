import 'package:flutter/foundation.dart';

import 'package:loqta/features/profile/data/models/user_profile_model.dart';
import 'package:loqta/features/profile/domain/entities/user_profile.dart';
import 'package:loqta/features/profile/domain/errors/profile_failure.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';

/// [ProfileRepository] over [ProfileRemoteDataSource].
///
/// Maps transport and RLS errors onto [ProfileFailure] so the presentation layer
/// never has to inspect a Supabase exception.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  /// Resolves the id every write is scoped to.
  ///
  /// Taken from the live Supabase session rather than passed in, so no caller
  /// can attempt to edit a profile other than the signed-in user's.
  String? get _currentUserId {
    final id = _remote.currentUserId;
    return (id == null || id.isEmpty) ? null : id;
  }

  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    try {
      return await _remote.fetchCurrentProfile();
    } catch (error, stackTrace) {
      debugPrint('Profile fetch failed: $error\n$stackTrace');
      throw const ProfileUnavailableFailure();
    }
  }

  @override
  Future<UserProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? governorate,
    String? area,
    String? phoneNumber,
  }) async {
    final id = _currentUserId;
    if (id == null) {
      throw const ProfileUpdateFailure(
        'You must be signed in to edit your profile.',
      );
    }
    try {
      return await _remote.updateProfile(
        UserProfileModel(
          id: id,
          firstName: firstName,
          lastName: lastName,
          avatarUrl: avatarUrl,
          governorate: governorate,
          area: area,
          phoneNumber: phoneNumber,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Profile update failed: $error\n$stackTrace');
      throw const ProfileUpdateFailure();
    }
  }
}
