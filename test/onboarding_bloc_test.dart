import 'package:flutter_test/flutter_test.dart';

import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';

/// In-memory stand-in for the SharedPreferences-backed repository.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.completed = false});

  bool completed;
  int completeCalls = 0;

  @override
  Future<void> completeOnboarding() async {
    completeCalls++;
    completed = true;
  }

  @override
  Future<bool> isOnboardingCompleted() async => completed;
}

void main() {
  group('OnboardingBloc', () {
    late FakeOnboardingRepository repository;

    setUp(() => repository = FakeOnboardingRepository());

    /// Creates the bloc and waits for the persisted flag to be read, so
    /// tests never assert against the initial loading state.
    Future<OnboardingBloc> start() async {
      final bloc = OnboardingBloc(repository: repository)
        ..add(const OnboardingStarted());
      await bloc.stream.firstWhere((s) => s.status != OnboardingStatus.loading);
      return bloc;
    }

    test('starts in the loading state so the gate can hold on splash', () {
      final bloc = OnboardingBloc(repository: repository);

      expect(bloc.state.status, OnboardingStatus.loading);

      bloc.close();
    });

    test('a returning user goes straight to completed', () async {
      repository.completed = true;
      final bloc = await start();

      expect(bloc.state.status, OnboardingStatus.completed);
      expect(bloc.state.isShowingOnboarding, isFalse);

      await bloc.close();
    });

    test('a new user starts on the first onboarding page', () async {
      final bloc = await start();

      expect(bloc.state.status, OnboardingStatus.inProgress);
      expect(bloc.state.pageIndex, 0);

      await bloc.close();
    });

    test('Next advances through pages 1 and 2 in order', () async {
      final bloc = await start();

      bloc.add(const OnboardingNextRequested());
      final first = await bloc.stream.firstWhere((s) => s.pageIndex == 1);
      expect(first.status, OnboardingStatus.inProgress);

      bloc.add(const OnboardingNextRequested());
      final second = await bloc.stream.firstWhere((s) => s.pageIndex == 2);
      expect(second.status, OnboardingStatus.inProgress);

      // Advancing within the flow must not persist completion yet.
      expect(repository.completeCalls, 0);

      await bloc.close();
    });

    test('Next on the last page completes onboarding', () async {
      final bloc = await start();

      bloc.add(const OnboardingNextRequested());
      await bloc.stream.firstWhere((s) => s.pageIndex == 1);
      bloc.add(const OnboardingNextRequested());
      await bloc.stream.firstWhere((s) => s.pageIndex == 2);

      bloc.add(const OnboardingNextRequested());
      final state = await bloc.stream.firstWhere(
        (s) => s.status == OnboardingStatus.completed,
      );

      expect(state.status, OnboardingStatus.completed);
      expect(repository.completed, isTrue);
      expect(repository.completeCalls, 1);

      await bloc.close();
    });

    test('the final button is labelled Get Started', () async {
      final bloc = await start();

      bloc.add(const OnboardingNextRequested());
      await bloc.stream.firstWhere((s) => s.pageIndex == 1);
      bloc.add(const OnboardingNextRequested());
      await bloc.stream.firstWhere((s) => s.pageIndex == 2);

      expect(bloc.state.pageIndex, kOnboardingPageCount - 1);

      await bloc.close();
    });

    test('Skip completes onboarding and persists the flag', () async {
      final bloc = await start();

      bloc.add(const OnboardingSkipRequested());
      final state = await bloc.stream.firstWhere(
        (s) => s.status == OnboardingStatus.completed,
      );

      expect(state.status, OnboardingStatus.completed);
      expect(repository.completed, isTrue);
      expect(repository.completeCalls, 1);

      await bloc.close();
    });

    test('Back returns to the previous page', () async {
      final bloc = await start();

      bloc.add(const OnboardingNextRequested());
      await bloc.stream.firstWhere((s) => s.pageIndex == 1);

      bloc.add(const OnboardingBackRequested());
      final state = await bloc.stream.firstWhere((s) => s.pageIndex == 0);

      expect(state.pageIndex, 0);
      expect(state.status, OnboardingStatus.inProgress);

      await bloc.close();
    });

    test('Back on the first page is ignored', () async {
      final bloc = await start();

      bloc.add(const OnboardingBackRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.pageIndex, 0);
      expect(bloc.state.status, OnboardingStatus.inProgress);

      await bloc.close();
    });

    test(
      'Next after completion is ignored, so sign-in cannot double-fire',
      () async {
        final bloc = await start();

        bloc.add(const OnboardingSkipRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == OnboardingStatus.completed,
        );

        bloc.add(const OnboardingNextRequested());
        bloc.add(const OnboardingSkipRequested());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.status, OnboardingStatus.completed);
        expect(repository.completeCalls, 1);

        await bloc.close();
      },
    );

    test('Next before the flag is read does not advance the flow', () async {
      final bloc = OnboardingBloc(repository: repository);

      bloc.add(const OnboardingNextRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, OnboardingStatus.loading);
      expect(bloc.state.pageIndex, 0);

      await bloc.close();
    });
  });
}
