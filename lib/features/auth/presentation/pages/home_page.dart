import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/navigation/main_shell.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/brand_logo.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/auth/presentation/widgets/home_widgets.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/domain/usecases/get_featured_listings_usecase.dart';
import 'package:loqta/features/listings/presentation/bloc/featured_listings_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/listing_details_page.dart';
import 'package:loqta/features/listings/presentation/pages/search_page.dart';
import 'package:loqta/features/listings/presentation/widgets/listing_card.dart';
import 'package:loqta/features/notifications/presentation/pages/notifications_page.dart';
import 'package:loqta/features/listings/presentation/pages/all_categories_page.dart';

/// The authenticated landing screen, rebuilt from
/// `design_drafts/screens/10_home.png`.
///
/// Keeps the approved layout: the brand header, the search bar, the two promo
/// cards, the category strip and the featured grid. The featured grid now reads
/// real listings from Supabase rather than hard-coded sample rows.
///
/// Search and Notifications are pushed on top of the shell. Favorites, Sell,
/// Messages and Profile are handled by [MainShell], so this page never draws
/// its own bottom bar.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeaturedListingsBloc>(
      create: (context) => FeaturedListingsBloc(
        GetFeaturedListingsUseCase(context.read<ListingRepository>()),
      )..add(const FeaturedListingsRequested()),
      child: const _HomeScaffold(),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  /// Opens the dedicated Search screen from the Home search bar.
  void _openSearch(BuildContext context) => _push(context, const SearchPage());

  void _openNotifications(BuildContext context) =>
      _push(context, const NotificationsPage());

  /// Switches the shell to the Profile destination instead of pushing a
  /// second copy of a screen that is already a tab.
  void _openProfile(BuildContext context) {
    MainShellScope.of(context)?.select(MainDestination.profile);
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _notifyNotAvailable(BuildContext context, String destination) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('$destination is coming in a later release.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  LoqtaSpacing.gutter,
                  8,
                  LoqtaSpacing.gutter,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(
                      onNotificationsTap: () => _openNotifications(context),
                      onProfileTap: () => _openProfile(context),
                    ),
                    const SizedBox(height: 16),
                    // Entry point to the Search screen. Not an editable field:
                    // the keyword is typed there.
                    HomeSearchBar(onTap: () => _openSearch(context)),
                    const SizedBox(height: 18),
                    // IntrinsicHeight lets both promo cards stretch to an equal
                    // height; a bare stretch Row would demand an infinite
                    // height inside the scroll view.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: HomePromoCard(
                              icon: Icons.sell_outlined,
                              pillLabel: 'Active',
                              title: 'For Sale',
                              caption: 'Browse items for sale',
                              accent: LoqtaColors.primary,
                              background: const Color(0xFFEFF9F2),
                              borderColor: const Color(0xFFD3EEDD),
                              // The approved design has no filtered browse
                              // screen, so the card opens Search rather than
                              // inventing one.
                              onTap: () => _push(
                                context,
                                const SearchPage(
                                  initialQuery: '',
                                  listingType: 'sale',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: HomePromoCard(
                              icon: Icons.redeem_outlined,
                              pillLabel: 'Community',
                              title: 'For Donation',
                              caption: 'Free community gifts',
                              accent: LoqtaColors.accentCyan,
                              background: const Color(0xFFEFF8FB),
                              borderColor: const Color(0xFFD3EAF2),
                              onTap: () => _push(
                                context,
                                const SearchPage(
                                  initialQuery: '',
                                  listingType: 'donation',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    HomeSectionHeader(
                      title: 'Categories',
                      trailing: GestureDetector(
                        onTap: () => _push(context, const AllCategoriesPage()),
                        child: const Text('See All', style: LoqtaText.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeCategoryStrip(
                onSelected: (label) => _push(
                  context,
                  SearchPage(initialQuery: '', category: label),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                22,
                LoqtaSpacing.gutter,
                0,
              ),
              sliver: const SliverToBoxAdapter(
                child: HomeSectionHeader(
                  title: 'Featured Finds',
                  trailingCaption: 'Latest items',
                ),
              ),
            ),
            const _FeaturedGrid(),
          ],
        ),
      ),
    );
  }
}

/// The "Featured Finds" grid, driven by [FeaturedListingsBloc].
class _FeaturedGrid extends StatelessWidget {
  const _FeaturedGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        LoqtaSpacing.gutter,
        14,
        LoqtaSpacing.gutter,
        20,
      ),
      sliver: BlocBuilder<FeaturedListingsBloc, FeaturedListingsState>(
        builder: (context, state) => switch (state) {
          FeaturedListingsInProgress() => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    LoqtaColors.primary,
                  ),
                ),
              ),
            ),
          ),
          FeaturedListingsFailure(:final message) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: LoqtaText.caption,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.read<FeaturedListingsBloc>().add(
                      const FeaturedListingsRequested(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LoqtaColors.primary,
                      side: const BorderSide(color: LoqtaColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Try again',
                      style: TextStyle(
                        color: LoqtaColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: LoqtaText.family,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FeaturedListingsSuccess(:final listings) =>
            listings.isEmpty
                ? const SliverToBoxAdapter(child: _NoFeaturedListings())
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          // Matches ListingCard.cardExtent: a fixed thumbnail height
                          // plus a fixed text block. Both are constant so the card
                          // can neither overflow on a wide viewport nor collapse on a
                          // narrow one.
                          mainAxisExtent: ListingCard.cardExtent,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final listing = listings[index];
                      return ListingCard(
                        listing: listing,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ListingDetailsPage(listingId: listing.id),
                          ),
                        ),
                      );
                    }, childCount: listings.length),
                  ),
        },
      ),
    );
  }
}

class _NoFeaturedListings extends StatelessWidget {
  const _NoFeaturedListings();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: LoqtaColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LoqtaColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: LoqtaColors.textTertiary,
          ),
          const SizedBox(height: 10),
          const Text(
            'No listings yet',
            style: TextStyle(
              color: LoqtaColors.headingPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: LoqtaText.family,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Be the first to list an item for sale or donation.',
            textAlign: TextAlign.center,
            style: LoqtaText.caption,
          ),
        ],
      ),
    );
  }
}

/// The brand row: logo plus wordmark on the leading edge, the location pill
/// and the Notifications and Profile actions on the trailing edge.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandLogo(size: 34),
        const SizedBox(width: 8),
        const Text(
          'Loqta',
          style: TextStyle(
            color: LoqtaColors.headingPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            fontFamily: LoqtaText.family,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: LoqtaColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LoqtaColors.border),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place, size: 12, color: LoqtaColors.textSecondary),
              SizedBox(width: 5),
              Text(
                'Home',
                style: TextStyle(
                  color: LoqtaColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: LoqtaText.family,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onNotificationsTap,
          tooltip: 'Notifications',
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.notifications_none,
            size: 21,
            color: LoqtaColors.headingPrimary,
          ),
        ),
        AccountButton(onPressed: onProfileTap, size: 32),
      ],
    );
  }
}
