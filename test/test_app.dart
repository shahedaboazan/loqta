import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          // Pass mock services
          picker: _MockImagePickerService(),
          publish: _MockPublishListingUseCase(),
        ),
        child: const Center(child: Text("Test Page")),
      ),
    );
  }
}

class _MockImagePickerService implements ImagePickerService {
  @override
  Future<PickedImage?> pickImage() async => null;
  @override
  Future<List<PickedImage>> pickImages() async => [];
}

class _MockPublishListingUseCase implements PublishListingUseCase {
  @override
  Future<String> call(dynamic draft, {String? publishId}) async => 'id';
}
