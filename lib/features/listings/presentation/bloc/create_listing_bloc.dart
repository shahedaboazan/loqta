import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/utils/uuid.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/entities/listing_draft.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/usecases/publish_listing_usecase.dart';

class CreateListingBloc extends Bloc<CreateListingEvent, CreateListingState> {
  CreateListingBloc({
    required this._picker,
    required this._publish,
  }) : super(const CreateListingState()) {
    on<ListingTypeChanged>(_onListingTypeChanged);
    on<CreateListingPhotosRequested>(_onCreateListingPhotosRequested);
    on<PhotoRemoved>(_onPhotoRemoved);
    on<CreateListingTitleChanged>(_onCreateListingTitleChanged);
    on<CreateListingCategoryChanged>(_onCreateListingCategoryChanged);
    on<CreateListingConditionChanged>(_onCreateListingConditionChanged);
    on<CreateListingPriceChanged>(_onCreateListingPriceChanged);
    on<CreateListingCurrencyChanged>(_onCreateListingCurrencyChanged);
    on<CreateListingGovernorateChanged>(_onCreateListingGovernorateChanged);
    on<CreateListingPickupAddressChanged>(_onCreateListingPickupAddressChanged);
    on<CreateListingDeliveryChanged>(_onCreateListingDeliveryChanged);
    on<CreateListingDescriptionChanged>(_onCreateListingDescriptionChanged);
    on<CreateListingContinueRequested>(_onCreateListingContinueRequested);
    on<CreateListingPublishRequested>(_onCreateListingPublishRequested);
    on<CreateListingNoticeHandled>(_onCreateListingNoticeHandled);
  }

  final ImagePickerService _picker;
  final PublishListingUseCase _publish;

  Future<void> _onListingTypeChanged(ListingTypeChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(
      draft: state.draft.copyWith(type: event.type, priceText: event.type.isDonation ? '' : state.draft.priceText),
      errors: _withoutError(ListingField.price, state.errors),
    ));
  }

  Future<void> _onCreateListingPhotosRequested(CreateListingPhotosRequested event, Emitter<CreateListingState> emit) async {
    if (state.isPickingPhotos) return;
    emit(state.copyWith(isPickingPhotos: true));
    try {
      final picked = await _picker.pickImages();
      if (picked.isEmpty) { emit(state.copyWith(isPickingPhotos: false)); return; }
      final photos = List<ListingDraftPhoto>.from(state.draft.photos);
      var truncated = false;
      for (final photo in picked) {
        if (photos.length >= ListingDraft.maxPhotos) { truncated = true; break; }
        photos.add(ListingDraftPhoto(bytes: photo.bytes, fileName: photo.fileName));
      }
      emit(state.copyWith(draft: state.draft.copyWith(photos: photos), isPickingPhotos: false, errors: _withoutError(ListingField.photos, state.errors), notice: truncated ? const CreateListingNoticePhotoLimit() : null));
    } on ImagePickException catch (e) {
      emit(state.copyWith(isPickingPhotos: false, notice: CreateListingNoticePhotoPickFailed(e.message)));
    } catch (_) {
      emit(state.copyWith(isPickingPhotos: false, notice: const CreateListingNoticePhotoPickFailed('Library unavailable.')));
    }
  }

  Future<void> _onPhotoRemoved(PhotoRemoved event, Emitter<CreateListingState> emit) async {
    final photos = List<ListingDraftPhoto>.from(state.draft.photos)..removeAt(event.index);
    emit(state.copyWith(draft: state.draft.copyWith(photos: photos)));
  }

  Future<void> _onCreateListingTitleChanged(CreateListingTitleChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(title: event.title), errors: _withoutError(ListingField.title, state.errors)));
  }

  Future<void> _onCreateListingCategoryChanged(CreateListingCategoryChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(category: event.category), errors: _withoutError(ListingField.category, state.errors)));
  }

  Future<void> _onCreateListingConditionChanged(CreateListingConditionChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(condition: event.condition), errors: _withoutError(ListingField.condition, state.errors)));
  }

  Future<void> _onCreateListingPriceChanged(CreateListingPriceChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(priceText: event.price), errors: _withoutError(ListingField.price, state.errors)));
  }

  Future<void> _onCreateListingCurrencyChanged(CreateListingCurrencyChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(currency: event.currency), errors: _withoutError(ListingField.currency, state.errors)));
  }

  Future<void> _onCreateListingGovernorateChanged(CreateListingGovernorateChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(governorate: event.governorate), errors: _withoutError(ListingField.governorate, state.errors)));
  }

  Future<void> _onCreateListingPickupAddressChanged(CreateListingPickupAddressChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(pickupAddress: event.pickupAddress), errors: _withoutError(ListingField.pickupAddress, state.errors)));
  }

  Future<void> _onCreateListingDeliveryChanged(CreateListingDeliveryChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(deliveryAvailable: event.deliveryAvailable), errors: _withoutError(ListingField.delivery, state.errors)));
  }

  Future<void> _onCreateListingDescriptionChanged(CreateListingDescriptionChanged event, Emitter<CreateListingState> emit) async {
    emit(state.copyWith(draft: state.draft.copyWith(description: event.description), errors: _withoutError(ListingField.description, state.errors)));
  }

  Future<void> _onCreateListingContinueRequested(CreateListingContinueRequested event, Emitter<CreateListingState> emit) async {
    final errors = state.draft.validate();
    emit(state.copyWith(errors: errors, previewNonce: errors.isEmpty ? state.previewNonce + 1 : state.previewNonce));
  }

  Future<void> _onCreateListingPublishRequested(CreateListingPublishRequested event, Emitter<CreateListingState> emit) async {
    if (state.publishedListingId != null || state.isPublishing) return;
    final errors = state.draft.validate();
    if (errors.isNotEmpty) { emit(state.copyWith(errors: errors)); return; }
    final publishId = state.publishId ?? generateUuidV4();
    emit(state.copyWith(isPublishing: true, publishId: publishId, publishFailure: null, errors: const <ListingField, ListingFieldError>{}));
    try {
      final listingId = await _publish(state.draft, publishId: publishId);
      emit(state.copyWith(isPublishing: false, publishedListingId: listingId));
    } on ListingFailure catch (e) {
      emit(state.copyWith(isPublishing: false, publishFailure: e.message));
    } catch (_) {
      emit(state.copyWith(isPublishing: false, publishFailure: 'Could not publish.'));
    }
  }

  Future<void> _onCreateListingNoticeHandled(CreateListingNoticeHandled event, Emitter<CreateListingState> emit) async {
    emit(state.clearNotice());
  }

  Map<ListingField, ListingFieldError> _withoutError(ListingField field, Map<ListingField, ListingFieldError> errors) => Map<ListingField, ListingFieldError>.from(errors)..remove(field);
}

class CreateListingState extends Equatable {
  const CreateListingState({this.draft = const ListingDraft(), this.errors = const {}, this.isPublishing = false, this.publishedListingId, this.publishFailure, this.isPickingPhotos = false, this.notice, this.previewNonce = 0, this.publishId});
  final ListingDraft draft;
  final Map<ListingField, ListingFieldError> errors;
  final bool isPublishing;
  final String? publishedListingId;
  final String? publishFailure;
  final bool isPickingPhotos;
  final CreateListingNotice? notice;
  final int previewNonce;
  final String? publishId;
  @override
  List<Object?> get props => [draft, errors, isPublishing, publishedListingId, publishFailure, isPickingPhotos, notice, previewNonce, publishId];
  CreateListingState copyWith({ListingDraft? draft, Map<ListingField, ListingFieldError>? errors, bool? isPublishing, String? publishedListingId, String? publishFailure, bool? isPickingPhotos, CreateListingNotice? notice, int? previewNonce, String? publishId}) => CreateListingState(draft: draft ?? this.draft, errors: errors ?? this.errors, isPublishing: isPublishing ?? this.isPublishing, publishedListingId: publishedListingId ?? this.publishedListingId, publishFailure: publishFailure ?? this.publishFailure, isPickingPhotos: isPickingPhotos ?? this.isPickingPhotos, notice: notice ?? this.notice, previewNonce: previewNonce ?? this.previewNonce, publishId: publishId ?? this.publishId);
  CreateListingState clearNotice() => copyWith(notice: null);
}

sealed class CreateListingEvent extends Equatable { const CreateListingEvent(); @override List<Object?> get props => []; }
class ListingTypeChanged extends CreateListingEvent { const ListingTypeChanged(this.type); final ListingType type; @override List<Object?> get props => [type]; }
class CreateListingPhotosRequested extends CreateListingEvent { const CreateListingPhotosRequested(); }
class PhotoRemoved extends CreateListingEvent { const PhotoRemoved(this.index); final int index; @override List<Object?> get props => [index]; }
class CreateListingTitleChanged extends CreateListingEvent { const CreateListingTitleChanged(this.title); final String title; @override List<Object?> get props => [title]; }
class CreateListingCategoryChanged extends CreateListingEvent { const CreateListingCategoryChanged(this.category); final String category; @override List<Object?> get props => [category]; }
class CreateListingConditionChanged extends CreateListingEvent { const CreateListingConditionChanged(this.condition); final String condition; @override List<Object?> get props => [condition]; }
class CreateListingPriceChanged extends CreateListingEvent { const CreateListingPriceChanged(this.price); final String price; @override List<Object?> get props => [price]; }
class CreateListingCurrencyChanged extends CreateListingEvent { const CreateListingCurrencyChanged(this.currency); final String currency; @override List<Object?> get props => [currency]; }
class CreateListingGovernorateChanged extends CreateListingEvent { const CreateListingGovernorateChanged(this.governorate); final String governorate; @override List<Object?> get props => [governorate]; }
class CreateListingPickupAddressChanged extends CreateListingEvent { const CreateListingPickupAddressChanged(this.pickupAddress); final String pickupAddress; @override List<Object?> get props => [pickupAddress]; }
class CreateListingDeliveryChanged extends CreateListingEvent { const CreateListingDeliveryChanged(this.deliveryAvailable); final bool deliveryAvailable; @override List<Object?> get props => [deliveryAvailable]; }
class CreateListingDescriptionChanged extends CreateListingEvent { const CreateListingDescriptionChanged(this.description); final String description; @override List<Object?> get props => [description]; }
class CreateListingContinueRequested extends CreateListingEvent { const CreateListingContinueRequested(); }
class CreateListingPublishRequested extends CreateListingEvent { const CreateListingPublishRequested(); }
class CreateListingNoticeHandled extends CreateListingEvent { const CreateListingNoticeHandled(); }
sealed class CreateListingNotice extends Equatable { const CreateListingNotice(); @override List<Object?> get props => []; }
class CreateListingNoticePhotoLimit extends CreateListingNotice { const CreateListingNoticePhotoLimit(); }
class CreateListingNoticePhotoPickFailed extends CreateListingNotice { const CreateListingNoticePhotoPickFailed(this.message); final String message; @override List<Object?> get props => [message]; }
