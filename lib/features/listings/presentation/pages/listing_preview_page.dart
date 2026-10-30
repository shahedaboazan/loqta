import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/features/listings/presentation/bloc/create_listing_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/publish_success_page.dart';
import 'package:loqta/features/profile/presentation/bloc/profile_bloc.dart';

class ListingPreviewPage extends StatefulWidget {
  const ListingPreviewPage({super.key});

  @override
  State<ListingPreviewPage> createState() => _ListingPreviewPageState();
}

class _ListingPreviewPageState extends State<ListingPreviewPage> {
  int _currentPhotoIndex = 0;

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
                // Photo Carousel with Badge & Page Indicator
                if (draft.photos.isNotEmpty) ...[
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          itemCount: draft.photos.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPhotoIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                draft.photos[index].bytes,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                      // Status Badge (Top Left)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: LoqtaColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            draft.isDonation
                                ? strings.listingTypeDonation.toUpperCase()
                                : 'FOR SALE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // Page Indicator Dots (Bottom Center)
                      if (draft.photos.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              draft.photos.length,
                              (index) => Container(
                                width: _currentPhotoIndex == index ? 18 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentPhotoIndex == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(draft.title, style: LoqtaText.heading),
                const SizedBox(height: 8),

                // Price
                Text(
                  draft.isDonation
                      ? strings.free
                      : '${draft.priceText} ${draft.currency}',
                  style: LoqtaText.heading.copyWith(
                    color: LoqtaColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Details Grid Container (Category, Condition, Delivery, Public Area)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.loqtaColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.loqtaColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Category',
                              value: draft.category,
                              icon: Icons.category_outlined,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Condition',
                              value: 'Good Condition', // Fallback / draft.condition
                              icon: Icons.thumb_up_outlined,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: LoqtaColors.border),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Delivery Option',
                              value: 'Pickup Only', // Fallback / draft.deliveryOption
                              icon: Icons.local_shipping_outlined,
                            ),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              label: 'Area / Quarter',
                              value: draft.area,
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Meeting Point Location Section
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: LoqtaColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text('Meeting Point Location', style: LoqtaText.fieldLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.loqtaColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.loqtaColors.border),
                  ),
                  child: Text(
                    '${draft.governorate} · ${draft.area}',
                    style: LoqtaText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),

                // Description Section
                Text(strings.description, style: LoqtaText.fieldLabel),
                const SizedBox(height: 8),
                Text(draft.description, style: LoqtaText.body),
                const SizedBox(height: 20),
                BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, profileState) {
                    final profile = profileState.profile;
                    final displayName =
                        profile?.displayNameOrPlaceholder ?? '?';
                    final avatarUrl = profile?.avatarUrl;

                    final initials =
                        profile == null || profile.displayName.isEmpty
                        ? '?'
                        : profile.displayName
                              .trim()
                              .split(RegExp(r'\s+'))
                              .take(2)
                              .map((part) => part[0].toUpperCase())
                              .join();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.loqtaColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.loqtaColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LISTING PUBLISHED BY (YOU)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: LoqtaColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: LoqtaColors.primary,
                                backgroundImage:
                                    avatarUrl != null &&
                                        avatarUrl.trim().isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child:
                                    avatarUrl == null ||
                                        avatarUrl.trim().isEmpty
                                    ? Text(
                                        initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: LoqtaColors.headingPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Community member in ${profile?.governorate ?? draft.governorate}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: LoqtaColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Two Bottom Action Buttons (Edit & Publish Listing)
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Edit Button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: state.isPublishing
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LoqtaColors.headingPrimary,
                          side: const BorderSide(color: LoqtaColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              LoqtaSpacing.radiusButton,
                            ),
                          ),
                          textStyle: LoqtaText.button,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Publish Listing Button
                  Expanded(
                    flex: 3,
                    child: LoqtaButton(
                      label: state.isPublishing
                          ? strings.publishing
                          : 'Publish Listing',
                      isLoading: state.isPublishing,
                      onPressed: state.isPublishing
                          ? null
                          : () => context.read<CreateListingBloc>().add(
                              const CreateListingPublishRequested(),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: LoqtaColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 15, color: LoqtaColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LoqtaColors.headingPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
