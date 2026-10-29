import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/listings/presentation/bloc/my_listings_bloc.dart';
import 'package:loqta/features/listings/domain/usecases/get_my_listings_usecase.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/presentation/widgets/listing_card.dart';
import 'package:loqta/features/listings/presentation/pages/listing_details_page.dart';
import 'package:loqta/features/chat/presentation/pages/chat_list_page.dart';
import 'package:loqta/features/listings/presentation/pages/create_listing_page.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state);
    final userId = user is Authenticated ? user.user.id : '';

    return BlocProvider<MyListingsBloc>(
      create: (context) => MyListingsBloc(
        GetMyListingsUseCase(context.read<ListingRepository>()),
      )..add(MyListingsRequested(userId)),
      child: const MyListingsView(),
    );
  }
}

class MyListingsView extends StatelessWidget {
  const MyListingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(strings.myListingsTitle)),
      body: BlocBuilder<MyListingsBloc, MyListingsState>(
        builder: (context, state) {
          if (state is MyListingsInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MyListingsFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final user = context.read<AuthBloc>().state;
                      if (user is Authenticated) {
                        context.read<MyListingsBloc>().add(MyListingsRequested(user.user.id));
                      }
                    },
                    child: Text(strings.tryAgain),
                  ),
                ],
              ),
            );
          } else if (state is MyListingsSuccess) {
            if (state.listings.isEmpty) {
              return _buildEmptyState(context);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(LoqtaSpacing.gutter),
              itemCount: state.listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final listing = state.listings[index];
                return Column(
                  children: [
                    ListingCard(
                      listing: listing,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ListingDetailsPage(listingId: listing.id),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Navigate to conversations for this listing
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ChatListPage(listingId: listing.id),
                            ),
                          );
                        },
                        child: Text(strings.chatMessages),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(context.l10n.noListingsBody),
          const SizedBox(height: 24),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreateListingPage(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}