import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/usecases/get_listing_usecase.dart';
import 'package:loqta/features/listings/domain/usecases/toggle_favorite_usecase.dart';

/// Drives the Listing Details screen (12).
///
/// Owns the listing itself plus the two actions it can trigger: toggling the
/// favourite and starting a conversation with the seller.
sealed class ListingDetailsState extends Equatable {
  const ListingDetailsState();

  @override
  List<Object?> get props => [];
}

class ListingDetailsInProgress extends ListingDetailsState {
  const ListingDetailsInProgress();
}

class ListingDetailsSuccess extends ListingDetailsState {
  const ListingDetailsSuccess(this.listing, {this.actionError});

  final Listing listing;

  /// A non-fatal failure from the favourite toggle. The listing stays on screen
  /// and the UI shows this as a snackbar.
  final String? actionError;

  @override
  List<Object?> get props => [listing, actionError];
}

class ListingDetailsFailure extends ListingDetailsState {
  const ListingDetailsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class ListingDetailsEvent extends Equatable {
  const ListingDetailsEvent();

  @override
  List<Object?> get props => [];
}

class ListingDetailsRequested extends ListingDetailsEvent {
  const ListingDetailsRequested(this.listingId);

  final String listingId;

  @override
  List<Object?> get props => [listingId];
}

/// Re-reads the listing without flashing the loading state, used when the user
/// returns from another screen.
class ListingDetailsRefreshed extends ListingDetailsEvent {
  const ListingDetailsRefreshed();
}

class ListingFavoriteToggled extends ListingDetailsEvent {
  const ListingFavoriteToggled();
}

class ListingDetailsBloc
    extends Bloc<ListingDetailsEvent, ListingDetailsState> {
  ListingDetailsBloc({
    required this._getListing,
    required this._toggleFavorite,
  }) : super(const ListingDetailsInProgress()) {
    on<ListingDetailsRequested>(_onRequested);
    on<ListingDetailsRefreshed>(_onRefreshed);
    on<ListingFavoriteToggled>(_onFavoriteToggled);
    on<_FavoriteFailed>(_onFavoriteFailed);
  }

  final GetListingUseCase _getListing;
  final ToggleFavoriteUseCase _toggleFavorite;

  String _listingId = '';

  Future<void> _onRequested(
    ListingDetailsRequested event,
    Emitter<ListingDetailsState> emit,
  ) async {
    _listingId = event.listingId;
    emit(const ListingDetailsInProgress());

    try {
      final listing = await _getListing(event.listingId);
      emit(ListingDetailsSuccess(listing));
    } on ListingFailure catch (failure) {
      emit(ListingDetailsFailure(failure.message));
    } catch (_) {
      emit(
        const ListingDetailsFailure('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> _onRefreshed(
    ListingDetailsRefreshed event,
    Emitter<ListingDetailsState> emit,
  ) async {
    if (_listingId.isEmpty) return;
    try {
      final listing = await _getListing(_listingId);
      emit(ListingDetailsSuccess(listing));
    } on ListingFailure catch (failure) {
      emit(ListingDetailsFailure(failure.message));
    } catch (_) {
      // A failed refresh must not wipe a listing the user is already reading.
    }
  }

  Future<void> _onFavoriteToggled(
    ListingFavoriteToggled event,
    Emitter<ListingDetailsState> emit,
  ) async {
    final current = state;
    if (current is! ListingDetailsSuccess) return;

    try {
      final isFavorite = await _toggleFavorite(current.listing.id);
      // Replaces the row, so the heart flips immediately rather than after a
      // refetch.
      emit(
        ListingDetailsSuccess(current.listing.copyWith(isFavorite: isFavorite)),
      );
    } on ListingFailure catch (failure) {
      // Keep the listing visible and surface the failure as a transient state.
      add(_FavoriteFailed(failure.message));
    } catch (_) {
      add(const _FavoriteFailed('Could not update your favourites.'));
    }
  }

  /// Reports a failed favourite toggle on the current listing.
  ///
  /// The listing is deliberately not cleared: losing the screen the user is
  /// reading because a heart tap failed would be worse than the failure.
  void _onFavoriteFailed(
    _FavoriteFailed event,
    Emitter<ListingDetailsState> emit,
  ) {
    final current = state;
    if (current is ListingDetailsSuccess) {
      emit(ListingDetailsSuccess(current.listing, actionError: event.message));
    }
  }
}

/// Internal event used to report a failed favourite toggle without hiding the
/// listing the user is on.
class _FavoriteFailed extends ListingDetailsEvent {
  const _FavoriteFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
