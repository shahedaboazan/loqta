import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/core/widgets/loqta_button.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/chat/domain/errors/chat_failure.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/usecases/get_or_create_conversation_usecase.dart';
import 'package:loqta/features/chat/presentation/pages/chat_page.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/domain/usecases/get_listing_usecase.dart';
import 'package:loqta/features/listings/domain/usecases/toggle_favorite_usecase.dart';
import 'package:loqta/features/listings/presentation/bloc/listing_details_bloc.dart';

/// Screen 12 — Listing Details.
///
/// Shows everything the listing record supports: photography, title, price or
/// "Free", condition, category, public location, description and the seller.
/// The exact pickup address is never shown — only governorate and area.
///
/// The primary action is "Contact Seller", which opens (or reuses) a chat.
class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ListingDetailsBloc>(
      create: (context) => ListingDetailsBloc(
        getListing: GetListingUseCase(context.read<ListingRepository>()),
        toggleFavorite: ToggleFavoriteUseCase(
          context.read<FavoritesRepository>(),
        ),
      )..add(ListingDetailsRequested(listingId)),
      child: const ListingDetailsView(),
    );
  }
}

class ListingDetailsView extends StatelessWidget {
  const ListingDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<ListingDetailsBloc, ListingDetailsState>(
          listenWhen: (previous, current) =>
              current is ListingDetailsSuccess &&
              current.actionError != null &&
              (previous is! ListingDetailsSuccess ||
                  previous.actionError != current.actionError),
          listener: (context, state) {
            if (state is ListingDetailsSuccess && state.actionError != null) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(content: Text(state.actionError!)));
            }
          },
          builder: (context, state) => switch (state) {
            ListingDetailsInProgress() => const _DetailsLoading(),
            ListingDetailsFailure(:final message) => _DetailsError(
              message: message,
              onRetry: () => context.read<ListingDetailsBloc>().add(
                const ListingDetailsRefreshed(),
              ),
            ),
            ListingDetailsSuccess(:final listing) => _DetailsBody(listing),
          },
        ),
      ),
    );
  }
}

class _DetailsBody extends StatefulWidget {
  const _DetailsBody(this.listing);

  final Listing listing;

  @override
  State<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends State<_DetailsBody> {
  final _pageController = PageController();

  /// Guards the "Contact Seller" button so a double tap cannot start two
  /// navigations, even though the underlying RPC is idempotent.
  bool _isContacting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _contactSeller() async {
    if (_isContacting) return;

    final listing = widget.listing;
    final currentUser = context.read<AuthRepository>().currentUser;

    if (currentUser == null) {
      _notify('Sign in to contact the seller.');
      return;
    }

    // Nobody can message themselves; the database refuses it too, but stopping
    // here avoids a pointless round trip.
    if (currentUser.id == listing.sellerId) {
      _notify('This is your own listing.');
      return;
    }

    setState(() => _isContacting = true);

    try {
      // Idempotent: returns the existing conversation for this listing and
      // participant pair, creating one only when none exists.
      final conversation =
          await GetOrCreateConversationUseCase(context.read<ChatRepository>())(
            listingId: listing.id,
            listingTitle: listing.title,
            listingImageUrl: listing.imageUrls.isEmpty
                ? null
                : listing.imageUrls.first,
            listingPrice: listing.price,
            isDonation: listing.isDonation,
          );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            conversationId: conversation.id,
            otherParticipantName: conversation.otherParticipantName ?? 'Seller',
            otherParticipantAvatarUrl: conversation.otherParticipantAvatarUrl,
            listingTitle: conversation.listing?.title ?? listing.title,
          ),
        ),
      );

      // The seller may have replied while the chat was open.
      if (mounted) {
        context.read<ListingDetailsBloc>().add(const ListingDetailsRefreshed());
      }
    } on ChatFailure catch (failure) {
      // mapChatError already produced copy that is safe to show, so it is used
      // as-is rather than re-parsed out of the exception's toString().
      if (!mounted) return;
      _notify(failure.message);
    } catch (_) {
      if (!mounted) return;
      _notify('Could not open the chat.');
    } finally {
      if (mounted) setState(() => _isContacting = false);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    return Column(
      children: [
        LoqtaAppBar(
          title: 'Listing Details',
          trailing: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: _HeaderHeart(
              isFavorite: listing.isFavorite,
              onTap: () => context.read<ListingDetailsBloc>().add(
                const ListingFavoriteToggled(),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImageGallery(listing: listing, controller: _pageController),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LoqtaSpacing.gutter,
                    18,
                    LoqtaSpacing.gutter,
                    12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          color: LoqtaColors.headingPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          fontFamily: LoqtaText.family,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PriceRow(listing: listing),
                      const SizedBox(height: 20),
                      Text(
                        'Item Details',
                        style: const TextStyle(
                          color: LoqtaColors.headingPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailGrid(listing: listing),
                      const SizedBox(height: 10),
                      _LocationNotice(listing),
                      const SizedBox(height: 22),
                      if (listing.description.trim().isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: LoqtaColors.headingPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(listing.description, style: LoqtaText.body),
                        const SizedBox(height: 22),
                      ],
                      const Text(
                        'Seller',
                        style: TextStyle(
                          color: LoqtaColors.headingPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SellerCard(listing: listing),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _ContactBar(
          listing: listing,
          isContacting: _isContacting,
          onContact: _contactSeller,
        ),
      ],
    );
  }
}

/// The swipeable photo strip with the sale/donation badge, the page dots and
/// the "3/4" counter pill.
class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.listing, required this.controller});

  final Listing listing;
  final PageController controller;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _index = 0;

  @override
  void didUpdateWidget(_ImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A different listing starts back at the first photo.
    if (oldWidget.listing.id != widget.listing.id) _index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final images = listing.imageUrls;
    final accent = listing.isDonation
        ? LoqtaColors.accentCyan
        : LoqtaColors.primary;

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (images.isEmpty)
                _FallbackPhoto(listing: listing, accent: accent)
              else
                PageView.builder(
                  controller: widget.controller,
                  itemCount: images.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _FallbackPhoto(listing: listing, accent: accent),
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : Container(color: LoqtaColors.fieldFill),
                  ),
                ),
              Positioned(
                top: 12,
                left: LoqtaSpacing.gutter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        listing.isDonation ? 'Donation' : 'For Sale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ),
                    // The approved design shows the condition beside the
                    // badge, so it is readable without scrolling.
                    if (listing.condition.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          listing.condition,
                          style: const TextStyle(
                            color: LoqtaColors.headingPrimary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 12,
                  right: LoqtaSpacing.gutter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: LoqtaText.family,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? LoqtaColors.primary
                        : LoqtaColors.progressInactive,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FallbackPhoto extends StatelessWidget {
  const _FallbackPhoto({required this.listing, required this.accent});

  final Listing listing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.10),
            accent.withValues(alpha: 0.22),
          ],
        ),
      ),
      child: Icon(
        listing.isDonation ? Icons.redeem_outlined : Icons.chair_outlined,
        size: 54,
        color: accent.withValues(alpha: 0.5),
      ),
    );
  }
}

class _HeaderHeart extends StatelessWidget {
  const _HeaderHeart({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: isFavorite
                ? const Color(0xFFE5484D)
                : LoqtaColors.headingPrimary,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final accent = listing.isDonation
        ? LoqtaColors.accentCyan
        : LoqtaColors.primary;
    final price = listing.formattedPrice;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            price ?? 'Free',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: LoqtaText.family,
            ),
          ),
        ),
        if (price != null) ...[
          const SizedBox(width: 6),
          Text(
            'SYP',
            style: TextStyle(
              color: accent.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: LoqtaText.family,
            ),
          ),
        ],
      ],
    );
  }
}

/// The Category / Condition / Listing Type / Delivery Option grid.
class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final typeLabel = listing.isDonation ? 'Donation' : 'For Sale';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DetailCell(
                label: 'Category',
                value: listing.category.isEmpty ? '-' : listing.category,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailCell(
                label: 'Condition',
                value: listing.condition.isEmpty ? '-' : listing.condition,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DetailCell(label: 'Listing Type', value: typeLabel),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _DetailCell(
                label: 'Delivery Option',
                value: 'Pickup Only',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LoqtaColors.fieldFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: LoqtaColors.textSecondary,
              fontSize: 10,
              fontFamily: LoqtaText.family,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LoqtaColors.headingPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontFamily: LoqtaText.family,
            ),
          ),
        ],
      ),
    );
  }
}

/// Replaces the exact address in the reference with the privacy notice the
/// product rules require: public listings show governorate and area only.
class _LocationNotice extends StatelessWidget {
  const _LocationNotice(this.listing);

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LoqtaColors.surfaceMint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD3EEDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.place_outlined,
            size: 15,
            color: LoqtaColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only the public area is shown; the street address never
                // reaches the client at all.
                if (listing.locationLabel.isNotEmpty)
                  Text(
                    listing.locationLabel,
                    style: const TextStyle(
                      color: LoqtaColors.headingPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                const SizedBox(height: 2),
                const Text(
                  'Exact pickup details are shared privately upon confirmation.',
                  style: TextStyle(
                    color: LoqtaColors.primary,
                    fontSize: 10.5,
                    height: 1.35,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final name = listing.sellerName ?? 'Loqta member';
    final avatarUrl = listing.sellerAvatarUrl;
    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LoqtaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoqtaColors.border),
      ),
      child: Row(
        children: [
          if (avatarUrl != null && avatarUrl.isNotEmpty)
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl))
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: LoqtaColors.primary,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LoqtaColors.headingPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: LoqtaText.family,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  listing.locationLabel.isEmpty
                      ? 'Community member'
                      : 'Community member in ${listing.locationLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LoqtaText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'L';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// The pinned bottom bar: a report link on the left, "Contact Seller" filling
/// the rest.
class _ContactBar extends StatelessWidget {
  const _ContactBar({
    required this.listing,
    required this.isContacting,
    required this.onContact,
  });

  final Listing listing;
  final bool isContacting;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LoqtaColors.surface,
        border: Border(top: BorderSide(color: LoqtaColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LoqtaSpacing.gutter,
            12,
            LoqtaSpacing.gutter,
            12,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: LoqtaColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Report this listing',
                style: const TextStyle(
                  color: LoqtaColors.textSecondary,
                  fontSize: 10.5,
                  fontFamily: LoqtaText.family,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LoqtaButton(
                  label: listing.isDonation ? 'Request Item' : 'Contact Seller',
                  onPressed: onContact,
                  isLoading: isContacting,
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsLoading extends StatelessWidget {
  const _DetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        valueColor: AlwaysStoppedAnimation<Color>(LoqtaColors.primary),
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: LoqtaColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LoqtaColors.primary,
                  side: const BorderSide(color: LoqtaColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      LoqtaSpacing.radiusButton,
                    ),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    color: LoqtaColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: LoqtaText.family,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
