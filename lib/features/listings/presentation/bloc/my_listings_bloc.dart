import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/usecases/get_my_listings_usecase.dart';

sealed class MyListingsState extends Equatable {
  const MyListingsState();

  @override
  List<Object?> get props => [];
}

class MyListingsInProgress extends MyListingsState {
  const MyListingsInProgress();
}

class MyListingsSuccess extends MyListingsState {
  const MyListingsSuccess(this.listings);

  final List<Listing> listings;

  @override
  List<Object?> get props => [listings];
}

class MyListingsFailure extends MyListingsState {
  const MyListingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class MyListingsEvent extends Equatable {
  const MyListingsEvent();

  @override
  List<Object?> get props => [];
}

class MyListingsRequested extends MyListingsEvent {
  const MyListingsRequested(this.sellerId);

  final String sellerId;

  @override
  List<Object?> get props => [sellerId];
}

class MyListingsBloc
    extends Bloc<MyListingsEvent, MyListingsState> {
  MyListingsBloc(this._getMyListings)
    : super(const MyListingsInProgress()) {
    on<MyListingsRequested>(_onRequested);
  }

  final GetMyListingsUseCase _getMyListings;

  Future<void> _onRequested(
    MyListingsRequested event,
    Emitter<MyListingsState> emit,
  ) async {
    emit(const MyListingsInProgress());

    try {
      final listings = await _getMyListings(event.sellerId);
      emit(MyListingsSuccess(listings));
    } on ListingFailure catch (failure) {
      emit(MyListingsFailure(failure.message));
    } catch (_) {
      emit(
        const MyListingsFailure(
          'Your listings are unavailable right now.',
        ),
      );
    }
  }
}
