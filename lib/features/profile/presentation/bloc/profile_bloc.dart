import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/profile/domain/entities/user_profile.dart';
import 'package:loqta/features/profile/domain/errors/profile_failure.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';

/// Loads and updates the signed-in user's profile.
///
/// `ProfilePage` and `EditProfilePage` share one bloc so a saved change appears
/// on the profile header immediately rather than after a manual refresh — the
/// two screens read the same state instead of each fetching their own copy.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileRepository repository})
    : _repository = repository,
      super(const ProfileState.initial()) {
    on<ProfileRequested>(_onRequested);
    on<ProfileSubmitted>(_onSubmitted);
    on<ProfilePhotoRemoved>(_onPhotoRemoved);
  }

  final ProfileRepository _repository;

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.fetchCurrentProfile();
      emit(
        state.copyWith(
          status: ProfileStatus.ready,
          profile: profile,
          clearError: true,
        ),
      );
    } on ProfileFailure catch (failure) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    ProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final saved = await _repository.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        avatarUrl: event.avatarUrl,
        governorate: event.governorate,
        area: event.area,
        phoneNumber: event.phoneNumber,
      );
      emit(
        state.copyWith(
          status: ProfileStatus.saved,
          profile: saved,
          clearError: true,
        ),
      );
    } on ProfileFailure catch (failure) {
      // The failure leaves `profile` untouched, so the form the user typed into
      // is still rendered from their own state and nothing is lost.
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> _onPhotoRemoved(
    ProfilePhotoRemoved event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state.profile;
    if (current == null || (current.avatarUrl ?? '').isEmpty) return;
    await _onSubmitted(
      ProfileSubmitted(
        firstName: current.firstName,
        lastName: current.lastName,
        avatarUrl: '',
        governorate: current.governorate,
        area: current.area,
        phoneNumber: current.phoneNumber,
      ),
      emit,
    );
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the profile. Dispatched when Profile or Edit Profile opens.
class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

/// Persists the editable profile fields.
class ProfileSubmitted extends ProfileEvent {
  const ProfileSubmitted({
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.governorate,
    this.area,
    this.phoneNumber,
  });

  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? governorate;
  final String? area;
  final String? phoneNumber;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    avatarUrl,
    governorate,
    area,
    phoneNumber,
  ];
}

/// Clears the profile photo.
class ProfilePhotoRemoved extends ProfileEvent {
  const ProfilePhotoRemoved();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum ProfileStatus {
  loading,
  ready,

  /// A write is in flight; the form shows a spinner and blocks re-submission.
  saving,

  /// The last write succeeded.
  saved,

  /// The last read or write failed; [ProfileState.errorMessage] explains why.
  failure,
}

class ProfileState extends Equatable {
  const ProfileState({required this.status, this.profile, this.errorMessage});

  const ProfileState.initial()
    : status = ProfileStatus.loading,
      profile = null,
      errorMessage = null;

  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
