import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/usecases/get_featured_listings_usecase.dart';

/// Loads the Home screen's "Featured Finds" rows.
sealed class FeaturedListingsState extends Equatable {
  const FeaturedListingsState();

  @override
  List<Object?> get props => [];
}

class FeaturedListingsInProgress extends FeaturedListingsState {
  const FeaturedListingsInProgress();
}

class FeaturedListingsSuccess extends FeaturedListingsState {
  const FeaturedListingsSuccess(this.listings);

  final List<Listing> listings;

  @override
  List<Object?> get props => [listings];
}

class FeaturedListingsFailure extends FeaturedListingsState {
  const FeaturedListingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class FeaturedListingsEvent extends Equatable {
  const FeaturedListingsEvent();

  @override
  List<Object?> get props => [];
}

class FeaturedListingsRequested extends FeaturedListingsEvent {
  const FeaturedListingsRequested();
}

class FeaturedListingsBloc
    extends Bloc<FeaturedListingsEvent, FeaturedListingsState> {
  FeaturedListingsBloc(this._getFeatured)
    : super(const FeaturedListingsInProgress()) {
    on<FeaturedListingsRequested>(_onRequested);
  }

  final GetFeaturedListingsUseCase _getFeatured;

  Future<void> _onRequested(
    FeaturedListingsRequested event,
    Emitter<FeaturedListingsState> emit,
  ) async {
    emit(const FeaturedListingsInProgress());

    try {
      emit(FeaturedListingsSuccess(await _getFeatured()));
    } on ListingFailure catch (failure) {
      emit(FeaturedListingsFailure(failure.message));
    } catch (_) {
      emit(
        const FeaturedListingsFailure(
          'Featured items are unavailable right now.',
        ),
      );
    }
  }
}
