import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/settings/domain/entities/app_preferences.dart';
import 'package:loqta/features/settings/domain/repositories/settings_repository.dart';

/// Owns the app-wide language and theme selection.
///
/// This is the single source of truth for both preferences: `MaterialApp` above
/// this bloc reads the state to pick the theme and locale, and the Settings
/// screen dispatches events to change them. Nothing else stores a copy, so a
/// selection cannot go out of sync between screens.
///
/// Writes are awaited before the new state is emitted so the UI never shows a
/// choice that failed to persist.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this._repository})
    : super(SettingsState.initial()) {
    on<SettingsRequested>(_onRequested);
    on<SettingsLocaleChanged>(_onLocaleChanged);
    on<SettingsThemeModeChanged>(_onThemeModeChanged);
  }

  final SettingsRepository _repository;

  Future<void> _onRequested(
    SettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final preferences = await _repository.load();
    emit(
      state.copyWith(status: SettingsStatus.ready, preferences: preferences),
    );
  }

  Future<void> _onLocaleChanged(
    SettingsLocaleChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.saveLocale(event.languageCode);
    emit(
      state.copyWith(
        status: SettingsStatus.ready,
        preferences: AppPreferences(
          localeCode: event.languageCode,
          themeMode: state.preferences.themeMode,
        ),
      ),
    );
  }

  Future<void> _onThemeModeChanged(
    SettingsThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.saveThemeMode(event.mode);
    emit(
      state.copyWith(
        status: SettingsStatus.ready,
        preferences: AppPreferences(
          localeCode: state.preferences.localeCode,
          themeMode: event.mode,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the persisted preferences. Dispatched once at startup.
class SettingsRequested extends SettingsEvent {
  const SettingsRequested();
}

/// Changes the app language. A null [languageCode] restores the device locale.
class SettingsLocaleChanged extends SettingsEvent {
  const SettingsLocaleChanged(this.languageCode);

  final String? languageCode;

  @override
  List<Object?> get props => [languageCode];
}

/// Changes the app brightness.
class SettingsThemeModeChanged extends SettingsEvent {
  const SettingsThemeModeChanged(this.mode);

  final AppThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum SettingsStatus {
  /// Preferences have not been read yet.
  loading,

  /// Preferences are loaded and any pending write has landed.
  ready,
}

class SettingsState extends Equatable {
  const SettingsState({required this.status, required this.preferences});

  const SettingsState.initial()
    : status = SettingsStatus.loading,
      preferences = const AppPreferences(themeMode: AppThemeMode.light);

  final SettingsStatus status;
  final AppPreferences preferences;

  SettingsState copyWith({
    SettingsStatus? status,
    AppPreferences? preferences,
  }) {
    return SettingsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [status, preferences];
}
