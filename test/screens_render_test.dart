import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/auth/domain/entities/auth_entities.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/email_confirmation_pending_page.dart';
import 'package:loqta/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:loqta/features/auth/presentation/pages/home_page.dart';
import 'package:loqta/features/auth/presentation/pages/reset_password_page.dart';
import 'package:loqta/features/auth/presentation/pages/sign_in_page.dart';
import 'package:loqta/features/auth/presentation/pages/sign_up_page.dart';
import 'package:loqta/features/auth/presentation/pages/splash_page.dart';
import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:loqta/features/chat/domain/entities/conversation.dart';
import 'package:loqta/features/chat/domain/errors/chat_failure.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/chat/presentation/pages/chat_list_page.dart';
import 'package:loqta/features/chat/presentation/pages/chat_page.dart';
import 'package:loqta/features/chat/presentation/pages/image_viewer_page.dart';
import 'package:loqta/features/listings/domain/entities/listing.dart';
import 'package:loqta/features/listings/domain/errors/listing_failure.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/listings/domain/entities/listing_page.dart';
import 'package:loqta/features/listings/presentation/pages/favorites_page.dart';
import 'package:loqta/features/listings/presentation/pages/listing_details_page.dart';
import 'package:loqta/features/listings/presentation/pages/search_page.dart';
import 'package:loqta/features/notifications/domain/entities/app_notification.dart';
import 'package:loqta/features/notifications/domain/errors/notification_failure.dart';
import 'package:loqta/features/notifications/presentation/pages/notifications_page.dart';

import 'support/fake_listing_repository.dart';
import 'support/fake_marketplace_repositories.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.user});

  AuthUser? user;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<Object?> watchAuthState() =>
      Stream<Object?>.value(user).asBroadcastStream();

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<AuthUser> signUpWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> resetPassword({required String newPassword}) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async => user = null;
}

class _FakeOnboardingRepository implements OnboardingRepository {
  @override
  Future<void> completeOnboarding() async {}

  @override
  Future<bool> isOnboardingCompleted() async => false;
}

/// Fails every read the way the real data layer does when the network is down,
/// so the screens' error and retry states can be exercised.
class _ThrowingChatRepository extends FakeChatRepository {
  _ThrowingChatRepository()
    : super(
        historyError: const ChatFailure(
          'Network error. Check your connection and try again.',
        ),
      );

  @override
  Future<List<Conversation>> fetchConversations() async =>
      throw const ChatFailure(
        'Network error. Check your connection and try again.',
      );
}

class _ThrowingListingRepository implements ListingRepository {
  @override
  Future<List<Listing>> fetchFeatured({int limit = 6}) async =>
      throw const ListingFailure(
        'Network error. Check your connection and try again.',
      );

  @override
  Future<ListingPage> search({
    required String query,
    required int offset,
    int limit = 4,
  }) async => throw const ListingFailure(
    'Network error. Check your connection and try again.',
  );

  @override
  Future<Listing> fetchById(String id) async => throw const ListingFailure(
    'Network error. Check your connection and try again.',
  );
}

/// Wraps [child] the same way main.dart does, so pages can resolve the
/// repositories and blocs they need.
///
/// [listingRepository] mirrors the real registration above `MaterialApp`: Home
/// reads `ListingRepository` when it builds `FeaturedListingsBloc`, so a test
/// that pumps Home has to supply one or the grid throws
/// `ProviderNotFoundException`.
Widget _host(
  Widget child, {
  AuthRepository? authRepository,
  ListingRepository? listingRepository,
  FavoritesRepository? favoritesRepository,
  ChatRepository? chatRepository,
  ImagePickerService? imagePickerService,
  NotificationRepository? notificationRepository,
}) {
  final repository = authRepository ?? _FakeAuthRepository();
  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: repository),
      RepositoryProvider<ListingRepository>.value(
        value: listingRepository ?? FakeListingRepository(),
      ),
      RepositoryProvider<FavoritesRepository>.value(
        value: favoritesRepository ?? FakeFavoritesRepository(),
      ),
      RepositoryProvider<ChatRepository>.value(
        value: chatRepository ?? FakeChatRepository(),
      ),
      RepositoryProvider<ImagePickerService>.value(
        value: imagePickerService ?? FakeImagePickerService(),
      ),
      RepositoryProvider<NotificationRepository>.value(
        value: notificationRepository ?? FakeNotificationRepository(),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        // main.dart provides AuthBloc above MaterialApp, so screens that react
        // to session changes (the confirmation-pending screen) can resolve it
        // from a pushed route too.
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            authUserStream: repository.watchAuthState(),
            currentUser: () => repository.currentUser,
            signOutUseCase: SignOutUseCase(repository),
          )..add(const AuthStarted()),
        ),
      ],
      child: MaterialApp(theme: LoqtaTheme.light, home: child),
    ),
  );
}

void main() {
  // Each test sets its own viewport through tester.view so every rebuilt
  // screen is exercised at a small phone size.
  group('rebuilt screens render their approved copy', () {
    testWidgets('01 splash', (tester) async {
      await tester.pumpWidget(_host(const SplashPage()));
      // The splash spinner is indeterminate, so settle is not an option here.
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('02/03/04 onboarding pages', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final bloc = OnboardingBloc(repository: _FakeOnboardingRepository())
        ..add(const OnboardingStarted());
      await tester.pumpWidget(
        _host(
          BlocProvider<OnboardingBloc>.value(
            value: bloc,
            child: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step through the three pages in order, checking each one's approved
      // copy and that it lays out cleanly.
      final pages = <({String title, String action, List<String> copy})>[
        (
          title: 'Find What You Need',
          action: 'Next',
          copy: ['BEST DEALS', '100% Local Finds'],
        ),
        (
          title: 'Sell or Give',
          action: 'Next',
          copy: ['Pass It On', 'Sell Simply', 'Fair Price', 'Zero Cost'],
        ),
        (
          title: 'Simple. Local. Useful.',
          action: 'Get Started',
          copy: ['Direct Chat', 'Real Peers', 'Safe Deals'],
        ),
      ];

      for (final page in pages) {
        expect(find.text(page.title), findsOneWidget, reason: page.title);
        expect(find.text(page.action), findsOneWidget, reason: page.title);
        expect(find.text('Skip'), findsOneWidget, reason: page.title);
        for (final text in page.copy) {
          expect(
            find.text(text),
            findsOneWidget,
            reason: '$text on ${page.title}',
          );
        }
        expect(tester.takeException(), isNull, reason: page.title);

        if (page != pages.last) {
          bloc.add(const OnboardingNextRequested());
          await tester.pumpAndSettle();
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(bloc.close);
    });

    testWidgets('05 sign in', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SignInPage()));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to Loqta'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(
        find.text('Safe & Verified Syria Pre-Owned Marketplace'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('06 sign up', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const SignUpPage()));
      await tester.pumpAndSettle();

      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(
        find.textContaining('confirmation link will be sent'),
        findsOneWidget,
      );
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('07 email confirmation pending', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _host(
          const EmailConfirmationPendingPage(email: 'sami.ahmad@example.com'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.text('One last step'), findsOneWidget);
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.textContaining('We sent you a confirmation link'),
        findsOneWidget,
      );
      expect(find.text('sami.ahmad@example.com'), findsOneWidget);
      expect(
        find.text('Guarding your Damascus marketplace account'),
        findsOneWidget,
      );
      expect(find.text('Check your spam folder'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
      // The OTP affordances are gone from the signup journey.
      expect(find.text('Verify & Continue'), findsNothing);
      expect(find.text('Resend Code'), findsNothing);
      expect(find.textContaining('6-digit'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('08 forgot password', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const ForgotPasswordPage()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Forgot Your Password?'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Send Reset Email'), findsOneWidget);
      expect(find.textContaining('expire within 30 minutes'), findsOneWidget);
      expect(find.textContaining('Enter your email address'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('09 reset password', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(const ResetPasswordPage()));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Loqta Secure Guard'), findsOneWidget);
      expect(find.text('Reset Your Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Min. 8 chars'), findsOneWidget);
      expect(find.text('Must be at least 8 characters'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Passwords must match'), findsOneWidget);
      expect(find.text('Save New Password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10 home', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      const user = AuthUser(
        id: 'u1',
        email: 'sara@example.com',
        firstName: 'Sara',
      );
      final repository = _FakeAuthRepository(user: user);
      // Home renders its "Featured Finds" grid from this repository, so the
      // fixture below is what puts real rows on screen.
      final listings = FakeListingRepository(
        featured: featuredFixtureListings(),
      );

      // Unmount before the test ends even when an assertion fails, so a broken
      // tree here cannot leak into the next test in this file.
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              authUserStream: repository.watchAuthState(),
              currentUser: () => repository.currentUser,
              signOutUseCase: SignOutUseCase(repository),
            )..add(const AuthStarted()),
            child: const HomePage(),
          ),
          authRepository: repository,
          listingRepository: listings,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Loqta'), findsOneWidget);
      expect(find.text('Search for items...'), findsOneWidget);
      expect(find.text('For Sale'), findsWidgets);
      expect(find.text('For Donation'), findsOneWidget);
      expect(find.text('Browse items for sale'), findsOneWidget);
      expect(find.text('Free community gifts'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.text('Featured Finds'), findsOneWidget);
      expect(find.text('Damascus'), findsWidgets);
      // The rebuilt Home strip lists fixed category tiles and the approved
      // design has no per-category item counts, so the labels it renders are
      // what is asserted here.
      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
      expect(find.text('Modern Fabric Sofa'), findsOneWidget);
      expect(find.text('1,500,000'), findsOneWidget);
      // Two of the four featured listings are priced, so two "SYP" suffixes;
      // the donations show "Free" with no currency.
      expect(find.text('SYP'), findsNWidgets(2));
      expect(find.text('Free'), findsNWidgets(2));
      // Home renders its own content only; the single bottom bar and the
      // Messages/Profile destinations come from MainShell.
      expect(find.text('Home'), findsWidgets);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      // The grid is repository-driven, not static chrome.
      expect(listings.featuredCalls, 1);

      // Tapping a category has no browse screen yet, so it reports that
      // destination instead of navigating anywhere.
      await tester.tap(find.text('Furniture'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('The Furniture category is coming in a later release.'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('11 search shows results for a keyword', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const SearchPage(),
          listingRepository: FakeListingRepository(
            all: listingFixtureCatalogue(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before a keyword is entered the screen shows its hint, not results.
      expect(find.text('Search Loqta'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Sofa');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Search results for "Sofa"'), findsOneWidget);
      expect(find.text('1 results found'), findsOneWidget);
      expect(find.text('Modern Fabric Sofa'), findsOneWidget);
      expect(find.text('1 of 1 listings'), findsOneWidget);
      // The only match is loaded, so the batch button is gone.
      expect(find.text('Show more items'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('11 search renders empty, cleared and error states', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const SearchPage(),
          listingRepository: FakeListingRepository(
            all: listingFixtureCatalogue(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A keyword that matches nothing.
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No results for "zzz"'), findsOneWidget);

      // Clearing the keyword returns to the hint, not the empty state.
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Search Loqta'), findsOneWidget);
      expect(find.text('No results for "zzz"'), findsNothing);

      // A failure is surfaced with a retry, never as a silent empty list.
      // Unmount first: pumping another SearchPage would update the existing
      // element tree and keep the previous bloc, which holds the old repository.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _host(
          const SearchPage(initialQuery: 'Sofa'),
          listingRepository: _ThrowingListingRepository(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Network error. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12 listing details renders the approved copy', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const ListingDetailsPage(listingId: 'l1'),
          authRepository: _FakeAuthRepository(
            user: const AuthUser(
              id: 'u1',
              email: 'sara@example.com',
              firstName: 'Sara',
            ),
          ),
          listingRepository: FakeListingRepository(
            all: listingFixtureCatalogue(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListingDetailsPage), findsOneWidget);
      expect(find.text('Modern Fabric Sofa'), findsWidgets);
      expect(find.text('1,500,000'), findsOneWidget);
      expect(find.text('SYP'), findsOneWidget);
      expect(find.text('Item Details'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Furniture'), findsOneWidget);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Like New'), findsWidgets);
      expect(find.text('Listing Type'), findsOneWidget);
      expect(find.text('Delivery Option'), findsOneWidget);
      expect(find.text('Pickup Only'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Seller'), findsOneWidget);
      expect(find.text('Contact Seller'), findsOneWidget);
      expect(find.text('Report this listing'), findsOneWidget);
      // Only the public area is published, and it is shown with the privacy
      // notice rather than as an address.
      expect(find.text('Damascus'), findsWidgets);
      expect(
        find.text(
          'Exact pickup details are shared privately upon confirmation.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('12 listing details favourites and contacts the seller', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final favorites = FakeFavoritesRepository();
      final chat = FakeChatRepository();

      await tester.pumpWidget(
        _host(
          const ListingDetailsPage(listingId: 'l1'),
          authRepository: _FakeAuthRepository(
            user: const AuthUser(
              id: 'u1',
              email: 'sara@example.com',
              firstName: 'Sara',
            ),
          ),
          listingRepository: FakeListingRepository(
            all: listingFixtureCatalogue(),
          ),
          favoritesRepository: favorites,
          chatRepository: chat,
        ),
      );
      await tester.pumpAndSettle();

      // The heart in the app bar writes through the favourites repository.
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(favorites.toggled, ['l1']);

      // "Contact Seller" opens the thread for the listing on screen.
      await tester.tap(find.text('Contact Seller'));
      await tester.pumpAndSettle();
      expect(chat.requestedListingIds, ['l1']);
      expect(find.byType(ChatPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13 favorites lists the saved listings', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const FavoritesPage(),
          favoritesRepository: FakeFavoritesRepository(
            rows: [favoriteFixtureListing()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FavoritesPage), findsOneWidget);
      expect(find.text('Private to you. Tap heart to remove.'), findsOneWidget);
      expect(find.text('Kids Bicycle'), findsOneWidget);
      expect(find.text('Donation'), findsOneWidget);
      // A donation is free, and the approved design says what that means.
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Community Gift'), findsOneWidget);
      expect(find.text('Like New'), findsOneWidget);
      expect(find.text('Request'), findsOneWidget);
      // "Saved" reads the favourite row's timestamp, not the listing's.
      expect(find.text('Saved 4d ago'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13 favorites removes a row and shows its empty state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final favorites = FakeFavoritesRepository(
        rows: [favoriteFixtureListing()],
      );

      await tester.pumpWidget(
        _host(const FavoritesPage(), favoritesRepository: favorites),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kids Bicycle'), findsOneWidget);

      // Tapping the heart removes it through the repository, and the list
      // falls back to the empty state rather than keeping a stale row.
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pumpAndSettle();
      expect(favorites.toggled, ['l3']);
      expect(find.text('No other favorites yet'), findsOneWidget);
      expect(find.text('Browse More Items'), findsOneWidget);
      expect(find.text('Kids Bicycle'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat renders the thread and sends a message', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final chat = FakeChatRepository(
        history: [
          messageFixture(id: 'm1', content: 'Hi, is this still available?'),
          messageFixture(
            id: 'm2',
            content: 'Yes, it is still available.',
            isMine: true,
          ),
        ],
      );
      addTearDown(chat.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Fallback name',
          ),
          chatRepository: chat,
        ),
      );
      await tester.pumpAndSettle();

      // The header's participant and listing context come from the server, not
      // from what the opening screen passed in.
      expect(chat.requestedConversationIds, ['conversation-1']);
      expect(find.text('Omar Al-Hassan'), findsWidgets);
      expect(find.text('Modern Fabric Sofa'), findsOneWidget);
      expect(find.text('1,500,000 SYP · Damascus - Mazzeh'), findsOneWidget);

      // The approved design's safety notice and pickup bar are fixed chrome.
      expect(find.textContaining('Agree on pickup times'), findsOneWidget);
      expect(find.text('Pickup only · Damascus - Mazzeh'), findsOneWidget);

      expect(find.text('Hi, is this still available?'), findsOneWidget);
      expect(find.text('Yes, it is still available.'), findsOneWidget);

      // Opening the thread advanced the read cursor.
      expect(chat.markedRead, isNotEmpty);

      // Sending writes through the repository and shows the returned message.
      await tester.enterText(
        find.widgetWithText(TextField, 'Write a message...'),
        'Can I pick it up tomorrow?',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Can I pick it up tomorrow?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat receives realtime messages without duplicates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final chat = FakeChatRepository(
        history: [messageFixture(id: 'm1', content: 'First message')],
      );
      addTearDown(chat.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: chat,
        ),
      );
      await tester.pumpAndSettle();

      final incoming = messageFixture(id: 'm2', content: 'Realtime reply');

      // The same row arriving twice is the normal case: the insert response and
      // the realtime event race each other.
      chat.emitRealtime(incoming);
      chat.emitRealtime(incoming);
      await tester.pumpAndSettle();

      expect(find.text('Realtime reply'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat reports a failed send instead of faking it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final chat = FakeChatRepository(
        history: [messageFixture(id: 'm1', content: 'First message')],
        sendError: const ChatFailure('That message could not be sent.'),
      );
      addTearDown(chat.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: chat,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Write a message...'),
        'This will not send',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // The failure is surfaced and the message is not shown as delivered.
      expect(find.text('That message could not be sent.'), findsOneWidget);
      expect(find.text('This will not send'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat shows an error state with retry', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final failing = FakeChatRepository(
        historyError: const ChatFailure(
          'Network error. Check your connection and try again.',
        ),
      );
      addTearDown(failing.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: failing,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Network error. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16 chat list renders conversations and their unread counts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final chat = FakeChatRepository(
        conversation: conversationFixture(
          unreadCount: 3,
          preview: 'Yes, it is still available.',
        ),
      );
      addTearDown(chat.dispose);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        _host(const ChatListPage(), chatRepository: chat),
      );
      await tester.pumpAndSettle();

      expect(find.text('Direct & secure peer-to-peer chats'), findsOneWidget);
      expect(find.text('Omar Al-Hassan'), findsOneWidget);
      expect(find.text('Modern Fabric Sofa - 1,500,000 SYP'), findsOneWidget);
      expect(find.text('Yes, it is still available.'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16 chat list shows empty, error and retry states', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      // No conversations yet.
      final none = FakeChatRepository(conversations: const []);
      addTearDown(none.dispose);
      await tester.pumpWidget(
        _host(const ChatListPage(), chatRepository: none),
      );
      await tester.pumpAndSettle();
      expect(find.text('No other messages'), findsOneWidget);

      // A failure is reported with a retry, never as an empty list.
      // Unmount first: pumping another ChatListPage would keep the existing
      // bloc, which still holds the repository that just succeeded.
      final failing = _ThrowingChatRepository();
      addTearDown(failing.dispose);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _host(const ChatListPage(), chatRepository: failing),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Network error. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15 image viewer opens one attachment and swipes between them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      const urls = [
        'https://example.invalid/a.jpg',
        'https://example.invalid/b.jpg',
        'https://example.invalid/c.jpg',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewerPage(
            imageUrl: 'https://example.invalid/b.jpg',
            position: 2,
            itemCount: 3,
            imageUrls: urls,
          ),
        ),
      );
      await tester.pump();

      // It opens on the attachment that was tapped, and the counter reflects
      // the conversation's whole attachment list.
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // The counter follows the swipe, rather than staying on the tapped page.
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15 image viewer reports a failed image with retry', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ImageViewerPage(
            imageUrl: 'https://example.invalid/missing.jpg',
            position: 1,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // A single attachment shows no counter and no dots.
      expect(find.text('This image could not be loaded.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat attaches a picked image and uploads it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final chat = FakeChatRepository(
        history: [messageFixture(id: 'm1', content: 'First message')],
      );
      final picker = FakeImagePickerService(
        result: PickedImage(
          bytes: Uint8List.fromList(List<int>.filled(8, 7)),
          fileName: 'sofa.jpg',
        ),
      );
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: chat,
          imagePickerService: picker,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      // The picker ran, and its bytes went through the bloc into the
      // repository rather than being handled by the widget.
      expect(picker.calls, 1);
      expect(chat.uploads.single.$1, 8);
      expect(chat.uploads.single.$3, 'sofa.jpg');
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat treats a cancelled picker as nothing happening', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final chat = FakeChatRepository(
        history: [messageFixture(id: 'm1', content: 'First message')],
      );
      final picker = FakeImagePickerService();
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: chat,
          imagePickerService: picker,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      // Nothing was uploaded and no error was shown for a cancellation.
      expect(chat.uploads, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat reports a denied photo permission honestly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final chat = FakeChatRepository(
        history: [messageFixture(id: 'm1', content: 'First message')],
      );
      final picker = FakeImagePickerService(
        error: const ImagePickException(
          'Photo access was denied. Allow it in Settings to attach a photo.',
        ),
      );
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: chat,
          imagePickerService: picker,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('Photo access was denied'), findsOneWidget);
      expect(chat.uploads, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14 chat reports a failed upload without faking a send', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final chat = FakeChatRepository(
        history: [messageFixture(id: 'm1', content: 'First message')],
        uploadError: const ChatFailure('That photo could not be sent.'),
      );
      final picker = FakeImagePickerService(
        result: PickedImage(
          bytes: Uint8List.fromList(List<int>.filled(8, 7)),
          fileName: 'sofa.jpg',
        ),
      );
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        _host(
          const ChatPage(
            conversationId: 'conversation-1',
            otherParticipantName: 'Omar Al-Hassan',
          ),
          chatRepository: chat,
          imagePickerService: picker,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      expect(find.text('That photo could not be sent.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('17 notifications lists rows and marks them read', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final repository = FakeNotificationRepository(
        rows: [
          notificationFixture(
            id: 'n1',
            title: 'New message',
            body: 'Omar sent you a message.',
            conversationId: 'conversation-1',
          ),
          notificationFixture(
            id: 'n2',
            title: 'Listing update',
            body: 'Your listing is now reserved.',
            type: NotificationType.listingStatusUpdate,
            listingId: 'l1',
            isRead: true,
          ),
        ],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _host(const NotificationsPage(), notificationRepository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notification'), findsOneWidget);
      expect(find.text('All Notification'), findsOneWidget);
      expect(find.text('New message'), findsOneWidget);
      expect(find.text('Omar sent you a message.'), findsOneWidget);
      expect(find.text('Listing update'), findsOneWidget);
      expect(find.text('Mark all read (1)'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17 notifications receives a realtime row', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final repository = FakeNotificationRepository(
        rows: [notificationFixture(id: 'n1', title: 'First update')],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        _host(const NotificationsPage(), notificationRepository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('First update'), findsOneWidget);

      repository.emit(notificationFixture(id: 'n2', title: 'Second update'));
      await tester.pumpAndSettle();

      expect(find.text('Second update'), findsOneWidget);
      // The unread count follows the new row.
      expect(find.text('Mark all read (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17 notifications shows empty and error states with retry', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      // Nothing in the history yet.
      final empty = FakeNotificationRepository();
      addTearDown(empty.dispose);
      await tester.pumpWidget(
        _host(const NotificationsPage(), notificationRepository: empty),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nothing new'), findsOneWidget);

      // A failure is reported with a retry, never as an empty list.
      final failing = FakeNotificationRepository(
        fetchError: const NotificationFailure(
          'Network error. Check your connection and try again.',
        ),
      );
      addTearDown(failing.dispose);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _host(const NotificationsPage(), notificationRepository: failing),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Network error. Check your connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Nothing new'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17 notifications opens a conversation destination', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
      });

      final notifications = FakeNotificationRepository(
        rows: [
          notificationFixture(
            id: 'n1',
            title: 'New message',
            conversationId: 'conversation-1',
          ),
        ],
      );
      addTearDown(notifications.dispose);
      final chat = FakeChatRepository();
      addTearDown(chat.dispose);

      await tester.pumpWidget(
        _host(
          const NotificationsPage(),
          notificationRepository: notifications,
          chatRepository: chat,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New message'));
      await tester.pumpAndSettle();

      // Opening a row marks it read and navigates to the existing chat.
      expect(notifications.markedRead, ['n1']);
      expect(find.byType(ChatPage), findsOneWidget);
      expect(chat.requestedConversationIds, ['conversation-1']);
      expect(tester.takeException(), isNull);
    });
    testWidgets('the official SVG logo is bundled and rendered', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      // The asset must be declared in pubspec.yaml and parse as SVG.
      final svg = await rootBundle.loadString('assets/logo.svg');
      expect(svg, contains('<svg'));

      await tester.pumpWidget(_host(const SignInPage()));
      await tester.pumpAndSettle();

      // flutter_svg draws through a PictureRecorder rather than an Image
      // widget, so assert the SvgPicture resolved and nothing threw.
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
