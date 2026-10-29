import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/usecases/get_favorite_listings_usecase.dart';
import 'package:loqta/features/listings/domain/usecases/toggle_favorite_usecase.dart';

/// Drives the Favorites screen (13).
sealed class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInProgress extends FavoritesState {
  const FavoritesInProgress();
}

class FavoritesSuccess extends FavoritesState {
  const FavoritesSuccess(this.listings, {this.actionError});

  final List<Listing> listings;

  /// A non-fatal failure from un-favouriting; the list is left untouched.
  final String? actionError;

  @override
  List<Object?> get props => [listings, actionError];
}

class FavoritesFailure extends FavoritesState {
  const FavoritesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class FavoritesRequested extends FavoritesEvent {
  const FavoritesRequested();
}

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required this._getFavorites,
    required this._toggleFavorite,
  }) : super(const FavoritesInProgress()) {
    on<FavoritesRequested>(_onRequested);
    on<FavoriteRemoved>(_onRemoved);
  }

  final GetFavoriteListingsUseCase _getFavorites;
  final ToggleFavoriteUseCase _toggleFavorite;

  Future<void> _onRequested(
    FavoritesRequested event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesInProgress());

    try {
      emit(FavoritesSuccess(await _getFavorites()));
    } on ListingFailure catch (failure) {
      emit(FavoritesFailure(failure.message));
    } catch (_) {
      emit(const FavoritesFailure('Something went wrong. Please try again.'));
    }
  }

  /// Un-favourites a listing.
  ///
  /// The row is dropped only after the database confirms it is gone, so a
  /// failure — or a toggle that the database resolved the other way round —
  /// leaves the list matching what is actually saved.
  Future<void> _onRemoved(
    FavoriteRemoved event,
    Emitter<FavoritesState> emit,
  ) async {
    final current = state;
    if (current is! FavoritesSuccess) return;

    try {
      final isFavorite = await _toggleFavorite(event.listingId);

      // The toggle resolved the other way: the row is still saved, so removing
      // it from the list would be a lie.
      if (isFavorite) {
        emit(
          FavoritesSuccess(
            current.listings,
            actionError: 'That item could not be removed from your favorites.',
          ),
        );
        return;
      }

      final remaining = current.listings
          .where((listing) => listing.id != event.listingId)
          .toList();
      emit(FavoritesSuccess(remaining));
    } on ListingFailure catch (failure) {
      emit(FavoritesSuccess(current.listings, actionError: failure.message));
    } catch (_) {
      emit(
        FavoritesSuccess(
          current.listings,
          actionError: 'Could not remove that item.',
        ),
      );
    }
  }
}

/// Removes one listing from the signed-in user's favourites.
class FavoriteRemoved extends FavoritesEvent {
  const FavoriteRemoved(this.listingId);

  final String listingId;

  @override
  List<Object?> get props => [listingId];
}
