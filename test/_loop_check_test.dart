import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loqta/core/theme/app_theme.dart';
import 'package:loqta/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:loqta/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:loqta/features/onboarding/presentation/pages/onboarding_page.dart';

class _O implements OnboardingRepository {
  bool c = false;

  @override
  Future<bool> isOnboardingCompleted() async => c;

  @override
  Future<void> completeOnboarding() async => c = true;
}

/// Smoke check that onboarding page 1 lays out on small phone viewports
/// without overflowing, and prints the text it renders.
void main() {
  testWidgets('onboarding lays out on small screens', (tester) async {
    for (final s in <Size>[const Size(320, 568), const Size(360, 640)]) {
      tester.view.physicalSize = s * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final bloc = OnboardingBloc(repository: _O())
        ..add(const OnboardingStarted());

      await tester.pumpWidget(
        MaterialApp(
          theme: LoqtaTheme.light,
          home: BlocProvider.value(
            // A per-iteration key forces a fresh element tree, so each size
            // builds against its own bloc instead of reusing the previous one.
            key: ValueKey('size-$s'),
            value: bloc,
            child: const OnboardingPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final texts = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .whereType<String>()
          .toList();
      debugPrint('SIZE=$s TEXTS=$texts');

      expect(tester.takeException(), isNull, reason: 'no overflow at $s');

      // Unmount before closing: while OnboardingPage is still mounted it holds
      // a subscription to the bloc, and closing it under the test binding's
      // fake async never completes, which hangs the test for 10 minutes.
      await tester.pumpWidget(const SizedBox.shrink());
      // runAsync gives the close a real event-loop turn to finish on.
      await tester.runAsync(bloc.close);
    }
  });
}
