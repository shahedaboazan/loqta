import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/features/listings/presentation/bloc/create_listing_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/publish_success_page.dart';

class ListingPreviewPage extends StatelessWidget {
  const ListingPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateListingBloc, CreateListingState>(
      listener: (context, state) {
        if (state.publishedListingId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PublishSuccessPage()),
          );
        }
      },
      builder: (context, state) {
        final strings = context.l10n;
        final draft = state.draft;
        return Scaffold(
          appBar: LoqtaAppBar(title: strings.listingPreview),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(LoqtaSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draft.photos.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: draft.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(draft.photos[index].bytes, width: 200, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(draft.title, style: LoqtaText.heading),
                const SizedBox(height: 8),
                Text(draft.isDonation ? strings.free : '${draft.priceText} ${draft.currency}', style: LoqtaText.body),
                const SizedBox(height: 8),
                Text('${draft.governorate} - ${draft.category}', style: LoqtaText.caption),
                const SizedBox(height: 16),
                Text(strings.description, style: LoqtaText.fieldLabel),
                Text(draft.description, style: LoqtaText.body),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LoqtaButton(
                label: strings.publish,
                onPressed: state.isPublishing 
                    ? () {} 
                    : () => context.read<CreateListingBloc>().add(const CreateListingPublishRequested()),
              ),
            ),
          ),
        );
      },
    );
  }
}
