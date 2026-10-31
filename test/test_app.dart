import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/listings/domain/entities/listing_draft.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/domain/usecases/publish_listing_usecase.dart';
import 'package:loqta/features/listings/presentation/bloc/create_listing_bloc.dart';

void main() {
  runApp(const MaterialApp(home: CreateListingTestPage()));
}

class CreateListingTestPage extends StatelessWidget {
  const CreateListingTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider<CreateListingBloc>(
        create: (_) => CreateListingBloc(
          picker: _MockImagePickerService(),
          publish: PublishListingUseCase(_MockListingRepository()),
        ),
        child: const Center(child: Text('Test Page')),
      ),
    );
  }
}

class _MockImagePickerService implements ImagePickerService {
  @override
  Future<PickedImage?> pickImage() async => null;
  @override
  Future<PickedImage?> takePhoto() async => null;
  @override
  Future<List<PickedImage>> pickImages() async => [];
}

class _MockListingRepository implements ListingRepository {
  @override
  Future<String> publish(
    ListingDraft draft, {
    required String publishId,
  }) async => 'test-listing-id';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
