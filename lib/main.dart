import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/auth/data/datasources/auth_data_source.dart';
import 'package:loqta/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:loqta/features/auth/domain/repositories/auth_repository.dart';
import 'package:loqta/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:loqta/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:loqta/features/auth/presentation/bloc/splash_bloc.dart';
import 'package:loqta/features/auth/presentation/pages/auth_gate.dart';
import 'package:loqta/features/auth/presentation/pages/startup_failure_page.dart';
import 'package:loqta/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:loqta/features/chat/data/datasources/image_picker_data_source.dart';
import 'package:loqta/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:loqta/features/chat/domain/repositories/chat_repository.dart';
import 'package:loqta/features/chat/domain/services/image_picker_service.dart';
import 'package:loqta/features/listings/data/datasources/favorites_remote_data_source.dart';
import 'package:loqta/features/listings/data/datasources/listing_remote_data_source.dart';
import 'package:loqta/features/listings/data/repositories/favorites_repository_impl.dart';
import 'package:loqta/features/listings/data/repositories/listing_repository_impl.dart';
import 'package:loqta/features/listings/data/datasources/transaction_remote_data_source.dart';
import 'package:loqta/features/listings/data/repositories/transaction_repository_impl.dart';
import 'package:loqta/features/listings/domain/repositories/transaction_repository.dart';
import 'package:loqta/features/listings/domain/repositories/favorites_repository.dart';
import 'package:loqta/features/listings/domain/repositories/listing_repository.dart';
import 'package:loqta/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:loqta/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:loqta/features/notifications/domain/repositories/notification_repository.dart';
import 'package:loqta/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/profile/data/models/user_profile_model.dart';
import 'package:loqta/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:loqta/features/profile/domain/repositories/profile_repository.dart';
import 'package:loqta/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:loqta/features/settings/domain/entities/app_preferences.dart';
import 'package:loqta/features/settings/domain/repositories/settings_repository.dart';
import 'package:loqta/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
}

/// Initializes the app and runs it.
///
/// A failure here (an unusable Supabase configuration, for instance) must
/// not leave the user on a blank screen or stuck on the splash, so the error
/// is shown with a way to try again.
Future<void> _bootstrap() async {
  try {
    // Supabase is initialized once, here, with the existing project
    // configuration. Everything else reads Supabase.instance.client.
    await Supabase.initialize(
      url: 'https://vklwahgitznqvybcgqim.supabase.co',
      publishableKey: 'sb_publishable_eGnlynlQdj2a4UUVCmK9tw_7yaLNKgo',
    );

    final authRepository = AuthRepositoryImpl(AuthDataSource());

    // The repository guards the signup-confirmation session, which needs the
    // locally stored "awaiting confirmation" address to be available before the
    // first frame. Awaiting it here keeps the startup check in AuthBloc from
    // ever seeing a just-confirmed account as signed in.
    await authRepository.ready;

    // Marketplace, chat and notification repositories. Supabase stays the single
    // source of truth for listings, conversations, messages and notification
    // records; the BLoCs read through these abstractions only.
    final listingRepository = ListingRepositoryImpl(ListingRemoteDataSource());
    final transactionRepository = TransactionRepositoryImpl(TransactionRemoteDataSource(Supabase.instance.client));
    final favoritesRepository = FavoritesRepositoryImpl(
      FavoritesRemoteDataSource(),
    );
    final chatRepository = ChatRepositoryImpl(ChatRemoteDataSource());

    // The platform image picker behind the Chat screen's attachment button.
    final imagePickerService = ImagePickerDataSource();
    final notificationRepository = NotificationRepositoryImpl(
      NotificationRemoteDataSource(),
    );

    // Onboarding state is device-local and deliberately separate from the
    // Supabase-backed auth repository.
    final onboardingRepository = OnboardingRepositoryImpl();

    // Profile rows and display preferences are also device/account-local
    // concerns owned by their feature layers.
    final profileRepository = ProfileRepositoryImpl(ProfileRemoteDataSource());
    final settingsRepository = SettingsRepositoryImpl();

    runApp(
      LoqtaApp(
        authRepository: authRepository,
        listingRepository: listingRepository,
        favoritesRepository: favoritesRepository,
        chatRepository: chatRepository,
        notificationRepository: notificationRepository,
        onboardingRepository: onboardingRepository,
        profileRepository: profileRepository,
        settingsRepository: settingsRepository,
        transactionRepository: transactionRepository,
        imagePickerService: imagePickerService,
      ),
    );
  } catch (error) {
    // Startup failed: show what went wrong instead of a blank screen, and
    // let the user try again.
    runApp(StartupFailureApp(error: error, onRetry: _bootstrap));
  }
}

class LoqtaApp extends StatelessWidget {
  const LoqtaApp({
    super.key,
    required this.authRepository,
    required this.listingRepository,
    required this.favoritesRepository,
    required this.chatRepository,
    required this.notificationRepository,
    required this.onboardingRepository,
    required this.profileRepository,
    required this.settingsRepository,
    required this.transactionRepository,
    required this.imagePickerService,
  });

  final AuthRepository authRepository;
  final ListingRepository listingRepository;
  final FavoritesRepository favoritesRepository;
  final ChatRepository chatRepository;
  final NotificationRepository notificationRepository;
  final OnboardingRepository onboardingRepository;
  final ProfileRepository profileRepository;
  final SettingsRepository settingsRepository;
  final TransactionRepository transactionRepository;

  final ImagePickerService imagePickerService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ListingRepository>.value(value: listingRepository),
        RepositoryProvider<FavoritesRepository>.value(
          value: favoritesRepository,
        ),
        RepositoryProvider<ChatRepository>.value(value: chatRepository),
        RepositoryProvider<NotificationRepository>.value(
          value: notificationRepository,
        ),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<TransactionRepository>.value(
          value: transactionRepository,
        ),
        RepositoryProvider<ImagePickerService>.value(value: imagePickerService),
      ],
      // The session and onboarding BLoCs sit above MaterialApp, alongside the
      // repositories, so pushed routes (sign-up, forgot password, reset
      // password, the confirmation-pending screen) can resolve them. Providing
      // them inside `home:` would scope them to the gate's own route only.
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              authUserStream: authRepository.watchAuthState(),
              currentUser: () => authRepository.currentUser,
              signOutUseCase: SignOutUseCase(authRepository),
            )..add(const AuthStarted()),
          ),
          BlocProvider<OnboardingBloc>(
            create: (_) =>
                OnboardingBloc(repository: onboardingRepository)
                  ..add(const OnboardingStarted()),
          ),
          // Holds the splash screen for a minimum time, so the app never
          // starts straight on the sign-in or home screen.
          BlocProvider<SplashBloc>(
            create: (_) => SplashBloc()..add(const SplashStarted()),
          ),
          // The single source of truth for the persisted language and theme.
          // It sits above MaterialApp so a Settings change repaints the whole
          // app, including the LTR/RTL flip, without any screen keeping a
          // duplicate copy of the preference.
          BlocProvider<SettingsBloc>(
            create: (_) =>
                SettingsBloc(repository: settingsRepository)
                  ..add(const SettingsRequested()),
          ),
        ],
        child: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settings) {
            final preferences = settings.preferences;
            return MaterialApp(
              title: 'Loqta',
              debugShowCheckedModeBanner: false,
              theme: LoqtaTheme.light,
              darkTheme: LoqtaTheme.dark,
              themeMode: preferences.themeMode == AppThemeMode.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              locale: preferences.resolvedLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Unsupported device locales fall back to English rather than
              // leaving the app with no resolved copy.
              localeResolutionCallback: (locale, supportedLocales) {
                if (locale != null) {
                  for (final supported in supportedLocales) {
                    if (supported.languageCode == locale.languageCode) {
                      return supported;
                    }
                  }
                }
                return AppLocalizations.fallbackLocale;
              },
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}
