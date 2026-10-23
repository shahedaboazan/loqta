import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';
import 'package:loqta/features/listings/domain/usecases/get_favorite_listings_usecase.dart';
import 'package:loqta/features/listings/domain/usecases/toggle_favorite_usecase.dart';
import 'package:loqta/features/listings/presentation/bloc/favorites_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/listing_details_page.dart';
import 'package:loqta/features/listings/presentation/pages/search_page.dart';

/// Screen 13 — Favorites.
///
/// Lists the signed-in user's saved listings. Each row opens Listing Details.
///
/// Favourites are private: the repository only reads rows the database has
/// already scoped to `auth.uid()`.
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoritesBloc>(
      create: (context) => FavoritesBloc(
        getFavorites: GetFavoriteListingsUseCase(
          context.read<FavoritesRepository>(),
        ),
        toggleFavorite: ToggleFavoriteUseCase(
          context.read<FavoritesRepository>(),
        ),
      )..add(const FavoritesRequested()),
      child: const FavoritesView(),
    );
  }
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            LoqtaAppBar(
              title: 'Favorites',
              // On the shell's tab there is no route to pop; hide the chevron
              // so it cannot exit the app. It returns when pushed as a route.
              showBack: Navigator.of(context).canPop(),
            ),
            // Favourites are private to the signed-in user, and the heart on each
            // row is the way back out of the screen.
            const Padding(
              padding: EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                0,
                LoqtaSpacing.gutter,
                10,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Private to you. Tap heart to remove.',
                  style: LoqtaText.caption,
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<FavoritesBloc, FavoritesState>(
                listenWhen: (previous, current) =>
                    current is FavoritesSuccess &&
                    current.actionError != null &&
                    (previous is! FavoritesSuccess ||
                        previous.actionError != current.actionError),
                listener: (context, state) {
                  if (state is FavoritesSuccess && state.actionError != null) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(content: Text(state.actionError!)),
                      );
                  }
                },
                builder: (context, state) => switch (state) {
                  FavoritesInProgress() => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        LoqtaColors.primary,
                      ),
                    ),
                  ),
                  FavoritesFailure(:final message) => _FavoritesError(
                    message: message,
                    onRetry: () => context.read<FavoritesBloc>().add(
                      const FavoritesRequested(),
                    ),
                  ),
                  FavoritesSuccess(:final listings) =>
                    listings.isEmpty
                        ? const _FavoritesEmpty()
                        : _FavoritesList(listings: listings),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  const _FavoritesList({required this.listings});

  final List<Listing> listings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        8,
        LoqtaSpacing.gutter,
        24,
      ),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final listing = listings[index];
        return _FavoriteRow(
          listing: listing,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ListingDetailsPage(listingId: listing.id),
            ),
          ),
          onRemove: () =>
              context.read<FavoritesBloc>().add(FavoriteRemoved(listing.id)),
        );
      },
    );
  }
}

/// One saved listing: photo, condition, saved-ago caption, title, price and a
/// "Contact" shortcut that opens the same details page.
class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.listing,
    required this.onTap,
    required this.onRemove,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accent = listing.isDonation
        ? LoqtaColors.accentCyan
        : LoqtaColors.primary;
    final price = listing.formattedPrice;
    final url = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LoqtaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LoqtaColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url == null)
                    Container(
                      color: accent.withValues(alpha: 0.12),
                      child: Icon(
                        listing.isDonation
                            ? Icons.redeem_outlined
                            : Icons.chair_outlined,
                        size: 34,
                        color: accent.withValues(alpha: 0.5),
                      ),
                    )
                  else
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: accent.withValues(alpha: 0.12),
                        child: Icon(
                          listing.isDonation
                              ? Icons.redeem_outlined
                              : Icons.chair_outlined,
                          size: 30,
                          color: accent.withValues(alpha: 0.5),
                        ),
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Container(color: LoqtaColors.fieldFill),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        listing.isDonation ? 'Donation' : 'For Sale',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.favorite,
                            size: 15,
                            color: Color(0xFFE5484D),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        listing.condition,
                        style: const TextStyle(
                          color: LoqtaColors.textSecondary,
                          fontSize: 9.5,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        // "Saved" describes the favourite, so it reads the
                        // favourites row's own timestamp and falls back to the
                        // listing date only if that row carried none.
                        'Saved ${_relativeSaved(listing.savedAt ?? listing.createdAt)}',
                        style: const TextStyle(
                          color: LoqtaColors.textTertiary,
                          fontSize: 9.5,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LoqtaColors.headingPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: LoqtaText.family,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          price == null ? 'Free' : '$price SYP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                      // A donation is free, so the approved design labels what
                      // the free price actually means.
                      if (listing.isDonation) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Community Gift',
                            style: TextStyle(
                              color: LoqtaColors.accentCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: LoqtaText.family,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // A shortcut into the same details page, never a second
                      // navigation path of its own.
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: LoqtaColors.fieldFill,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                listing.isDonation ? 'Request' : 'Contact',
                                style: const TextStyle(
                                  color: LoqtaColors.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: LoqtaText.family,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 9,
                                color: LoqtaColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 11,
                        color: LoqtaColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LoqtaColors.textTertiary,
                            fontSize: 9.5,
                            fontFamily: LoqtaText.family,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _relativeSaved(DateTime savedAt) {
    final difference = DateTime.now().difference(savedAt);
    if (difference.inMinutes < 60) {
      return difference.inMinutes <= 1
          ? 'just now'
          : '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 30) return '${difference.inDays}d ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        20,
        LoqtaSpacing.gutter,
        24,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: LoqtaColors.surfaceMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 32,
              color: LoqtaColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No other favorites yet',
            style: TextStyle(
              color: LoqtaColors.headingPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: LoqtaText.family,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Save items you like while browsing and find them easily here '
            'whenever you want to revisit them.',
            textAlign: TextAlign.center,
            style: LoqtaText.subtitle,
          ),
          const SizedBox(height: 18),
          // The approved design sends an empty Favourites screen to the
          // existing Search screen rather than to a second, browse-only one.
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SearchPage()),
              ),
              icon: const Icon(
                Icons.grid_view_outlined,
                size: 16,
                color: LoqtaColors.primary,
              ),
              label: const Text(
                'Browse More Items',
                style: TextStyle(
                  color: LoqtaColors.primary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: LoqtaText.family,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: LoqtaColors.primary,
                side: const BorderSide(color: LoqtaColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    LoqtaSpacing.radiusButton,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.message, required this.onRetry});

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
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: LoqtaColors.error,
            ),
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
