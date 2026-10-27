import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/domain/usecases/search_listings_usecase.dart';
import 'package:loqta/features/listings/domain/usecases/toggle_favorite_usecase.dart';
import 'package:loqta/features/listings/presentation/bloc/search_bloc.dart';
import 'package:loqta/features/listings/presentation/pages/listing_details_page.dart';
import 'package:loqta/features/listings/presentation/widgets/listing_card.dart';

/// Screen 11 — Search.
///
/// One screen holds both the keyword input and its results: the approved design
/// has no separate results page, and no filters of any kind.
///
/// Results are paginated server-side in batches of four behind a
/// "Show more items" button, with the running total shown as
/// "Viewing 4 of 24 listings".
class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
    this.initialQuery,
    this.listingType,
    this.governorate,
    this.category,
  });

  /// Optional pre-filled keyword. Null when the user arrives from Home.
  final String? initialQuery;
  final String? listingType;
  final String? governorate;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (context) {
        final bloc = SearchBloc(
          SearchListingsUseCase(context.read<ListingRepository>()),
          ToggleFavoriteUseCase(context.read<FavoritesRepository>()),
        );
        final seed = initialQuery?.trim() ?? '';
        if (seed.isNotEmpty || listingType != null || governorate != null || category != null) {
          bloc.add(SearchSubmitted(
            seed,
            listingType: listingType,
            governorate: governorate,
            category: category,
          ));
        }
        return bloc;
      },
      child: const SearchView(),
    );
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final searchBloc = context.read<SearchBloc>();
    final state = searchBloc.state;
    
    // Maintain previous filter state if possible or get from some widget state
    // But currently filters are not in the UI, need to add them.
    searchBloc.add(SearchSubmitted(
      _controller.text,
      listingType: state is SearchSuccess ? state.listingType : null,
      governorate: state is SearchSuccess ? state.governorate : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoqtaColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const LoqtaAppBar(title: 'Search'),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LoqtaSpacing.gutter,
                4,
                LoqtaSpacing.gutter,
                12,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Search for items...',
                  hintStyle: LoqtaText.fieldHint,
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: LoqtaColors.textSecondary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) => value.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: LoqtaColors.textSecondary,
                                ),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  context.read<SearchBloc>().add(
                                    const SearchCleared(),
                                  );
                                },
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.filter_list, size: 20, color: LoqtaColors.textSecondary),
                        onPressed: () {
                          // TODO: Implement filter modal
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocConsumer<SearchBloc, SearchState>(
                // Only react to a *new* transient failure, so the same message is
                // not shown repeatedly on every rebuild.
                listenWhen: (previous, current) =>
                    current is SearchSuccess &&
                    current.actionError != null &&
                    (previous is! SearchSuccess ||
                        previous.actionError != current.actionError),
                listener: (context, state) {
                  if (state is SearchSuccess && state.actionError != null) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(content: Text(state.actionError!)),
                      );
                  }
                },
                builder: (context, state) => switch (state) {
                  SearchIdle() => const _IdleHint(),
                  SearchInProgress() => const _SearchLoading(),
                  SearchFailureState(:final message) => _ErrorState(
                    message: message,
                    onRetry: _submit,
                  ),
                  SearchEmpty(:final query) => _EmptyState(query: query),
                  SearchSuccess() => _Results(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The keyword line and results grid, including the counter and the
/// "Show more items" button.
class _Results extends StatelessWidget {
  const _Results({required this.state});

  final SearchSuccess state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LoqtaSpacing.gutter,
                    4,
                    LoqtaSpacing.gutter,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search results for "${state.query}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LoqtaColors.textSecondary,
                          fontSize: 13.5,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.total} results found',
                        style: const TextStyle(
                          color: LoqtaColors.headingPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: LoqtaText.family,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LoqtaSpacing.gutter,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: ListingCard.cardExtent,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final listing = state.listings[index];
                    return ListingCard(
                      listing: listing,
                      onTap: () => _openDetails(context, listing.id),
                      onFavoriteTap: () => _toggleFavorite(context, listing.id),
                    );
                  }, childCount: state.listings.length),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LoqtaSpacing.gutter,
                    18,
                    LoqtaSpacing.gutter,
                    20,
                  ),
                  child: Column(
                    children: [
                      // "Viewing 4 of 24 listings"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Viewing',
                            style: TextStyle(
                              color: LoqtaColors.textSecondary,
                              fontSize: 12,
                              fontFamily: LoqtaText.family,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${state.loadedCount} of ${state.total} listings',
                            style: const TextStyle(
                              color: LoqtaColors.headingPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: LoqtaText.family,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Hidden once every match has been displayed, which is
                      // what stops the button appearing when there is nothing
                      // left to load.
                      if (!state.hasReachedEnd)
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: state.isLoadingMore
                                ? null
                                : () => context.read<SearchBloc>().add(
                                    const SearchNextPageRequested(),
                                  ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: LoqtaColors.primary,
                              side: const BorderSide(
                                color: LoqtaColors.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  LoqtaSpacing.radiusButton,
                                ),
                              ),
                            ),
                            child: state.isLoadingMore
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        LoqtaColors.primary,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Show more items',
                                    style: TextStyle(
                                      color: LoqtaColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: LoqtaText.family,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDetails(BuildContext context, String listingId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailsPage(listingId: listingId),
      ),
    );
  }

  void _toggleFavorite(BuildContext context, String listingId) {
    // The bloc patches the heart from the state the database reports, so the
    // card can never drift from what is actually saved.
    context.read<SearchBloc>().add(SearchFavoriteToggled(listingId));
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 42, color: LoqtaColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'Search Loqta',
              style: TextStyle(
                color: LoqtaColors.headingPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: LoqtaText.family,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Type a keyword above to find items for sale and items for donation.',
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoqtaSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off,
              size: 42,
              color: LoqtaColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LoqtaColors.headingPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: LoqtaText.family,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different keyword, such as "sofa" or "laptop".',
              textAlign: TextAlign.center,
              style: LoqtaText.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
