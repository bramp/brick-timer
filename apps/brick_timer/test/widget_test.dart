import 'package:brick_timer/main.dart';
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestActiveSessionNotifier extends ActiveSessionNotifier {
  @override
  ActiveSessionState build() => ActiveSessionState();
}

void main() {
  testWidgets('App smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildSessionsProvider.overrideWith((ref) => Stream.value([])),
          unsyncedBagsCountProvider.overrideWith((ref) => Stream.value(0)),
          activeSessionProvider.overrideWith(_TestActiveSessionNotifier.new),
        ],
        child: const BrickTimerApp(),
      ),
    );

    // Give it a moment to resolve the provider.
    await tester.pumpAndSettle();

    // Verify that our app shows the dashboard title instead of basic text.
    expect(find.text('Brick Timer'), findsOneWidget);
    expect(find.text('Start build'), findsOneWidget);
  });
}
