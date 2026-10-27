import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/usecases/search_listings_usecase.dart';
import 'package:loqta/features/listings/domain/usecases/toggle_favorite_usecase.dart';

/// Keyword search with server-side pagination.
///
/// State shape follows the auth blocs: an abstract base class with one concrete
/// class per outcome, so the UI switches on `is` instead of reading flags.
sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// No keyword entered yet — the screen shows its hint copy.
class SearchIdle extends SearchState {
  const SearchIdle();
}

class SearchInProgress extends SearchState {
  const SearchInProgress(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Results for [query], with [total] matching listings reported by the server.
class SearchSuccess extends SearchState {
  const SearchSuccess({
    required this.query,
    required this.listings,
    required this.total,
    this.listingType,
    this.governorate,
    this.category,
    this.isLoadingMore = false,
    this.actionError,
  });

  final String query;
  final String? listingType;
  final String? governorate;
  final String? category;
  final List<Listing> listings;
  final int total;
  final bool isLoadingMore;

  /// A non-fatal failure from loading the next batch or from toggling a
  /// favourite. The results already on screen are kept, so a transient failure
  /// never empties the list, and the screen shows this as a snackbar.
  final String? actionError;

  /// How many of the matches are on screen, e.g. "Viewing 4 of 24 listings".
  int get loadedCount => listings.length;

  /// True once every match has been displayed, which hides the
  /// "Show more items" button.
  bool get hasReachedEnd => loadedCount >= total;

  SearchSuccess copyWith({
    List<Listing>? listings,
    bool? isLoadingMore,
    String? actionError,
    bool clearActionError = false,
  }) {
    return SearchSuccess(
      query: query,
      listingType: listingType,
      governorate: governorate,
      category: category,
      listings: listings ?? this.listings,
      total: total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    query,
    listingType,
    governorate,
    category,
    listings,
    total,
    isLoadingMore,
    actionError,
  ];
}

/// The keyword matched nothing.
class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchFailureState extends SearchState {
  const SearchFailureState(this.query, this.message);

  final String query;
  final String message;

  @override
  List<Object?> get props => [query, message];
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Runs [query] as a fresh search, discarding any previous results.
class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.query, {this.listingType, this.governorate, this.category});

  final String query;
  final String? listingType;
  final String? governorate;
  final String? category;

  @override
  List<Object?> get props => [query, listingType, governorate, category];
}

/// Clears the keyword and the results.
class SearchCleared extends SearchEvent {
  const SearchCleared();
}

/// Loads the next batch. Driven by the "Show more items" button.
class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}

/// Flips the heart on a result card.
class SearchFavoriteToggled extends SearchEvent {
  const SearchFavoriteToggled(this.listingId);

  final String listingId;

  @override
  List<Object?> get props => [listingId];
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._searchListings, this._toggleFavorite)
    : super(const SearchIdle()) {
    on<SearchSubmitted>(_onSubmitted);
    on<SearchCleared>(_onCleared);
    on<SearchNextPageRequested>(_onNextPageRequested);
    on<SearchFavoriteToggled>(_onFavoriteToggled);
  }

  final SearchListingsUseCase _searchListings;
  final ToggleFavoriteUseCase _toggleFavorite;

  /// The keyword the currently displayed results belong to. A batch request is
  /// only honoured while it still matches, so results can never be appended to
  /// the wrong query.
  String _activeQuery = '';

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    final listingType = event.listingType;
    final governorate = event.governorate;
    final category = event.category;

    if (query.isEmpty && (listingType == null || listingType == 'all') && (governorate == null || governorate == 'all') && (category == null || category == 'all')) {
      emit(const SearchIdle());
      return;
    }

    // Any keyword change starts a new result set from offset 0.
    _activeQuery = query;

    emit(SearchInProgress(query));

    try {
      final page = await _searchListings(
        query: query,
        offset: 0,
        listingType: listingType,
        governorate: governorate,
        category: category,
      );

      if (page.isEmpty) {
        emit(SearchEmpty(query));
        return;
      }

      emit(
        SearchSuccess(
          query: query,
          listingType: listingType,
          governorate: governorate,
          category: category,
          listings: page.items,
          total: page.total,
        ),
      );
    } on ListingFailure catch (failure) {
      emit(SearchFailureState(query, failure.message));
    } catch (_) {
      emit(
        SearchFailureState(query, 'Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) async {
    _activeQuery = '';
    emit(const SearchIdle());
  }

  Future<void> _onNextPageRequested(
    SearchNextPageRequested event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;

    // Ignore taps while a batch is already in flight, at the end of the list, or
    // when the keyword changed since these results were produced. Together these
    // are what prevent duplicate requests and duplicate rows.
    if (current is! SearchSuccess) return;
    if (current.isLoadingMore) return;
    if (current.hasReachedEnd) return;
    if (current.query != _activeQuery) return;

    emit(current.copyWith(isLoadingMore: true, clearActionError: true));

    try {
      final page = await _searchListings(
        query: current.query,
        offset: current.loadedCount,
        listingType: current.listingType,
        governorate: current.governorate,
        category: current.category,
      );

      // The keyword may have changed while the request was in flight; drop the
      // stale batch instead of appending it to the new results.
      if (_activeQuery != current.query) return;

      if (page.isEmpty) {
        emit(current.copyWith(isLoadingMore: false));
        return;
      }

      emit(
        SearchSuccess(
          query: current.query,
          listingType: current.listingType,
          governorate: current.governorate,
          category: current.category,
          listings: [...current.listings, ...page.items],
          total: page.total,
        ),
      );
    } on ListingFailure catch (failure) {
      emit(
        current.copyWith(isLoadingMore: false, actionError: failure.message),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isLoadingMore: false,
          actionError: 'Could not load more items. Try again.',
        ),
      );
    }
  }

  /// Flips the heart on one result card.
  ///
  /// The state is patched with the state the database reports, so the heart can
  /// never drift from what is actually saved. A failure leaves the row as it
  /// was and surfaces a message instead.
  Future<void> _onFavoriteToggled(
    SearchFavoriteToggled event,
    Emitter<SearchState> emit,
  ) async {
    final current = state;
    if (current is! SearchSuccess) return;

    final index = current.listings.indexWhere(
      (listing) => listing.id == event.listingId,
    );
    if (index < 0) return;

    try {
      final isFavorite = await _toggleFavorite(event.listingId);
      if (isFavorite == current.listings[index].isFavorite) return;

      final updated = [...current.listings];
      updated[index] = updated[index].copyWith(isFavorite: isFavorite);
      emit(current.copyWith(listings: updated));
    } on ListingFailure catch (failure) {
      emit(current.copyWith(actionError: failure.message));
    } catch (_) {
      emit(current.copyWith(actionError: 'Could not update your favourites.'));
    }
  }
}
