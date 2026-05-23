import 'package:brick_timer/main.dart';
import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buildSessionsProvider.overrideWith((ref) => Stream.value([])),
          unsyncedBagsCountProvider.overrideWith((ref) => Stream.value(0)),
        ],
        child: const BrickTimerApp(),
      ),
    );

    // Give it a moment to resolve the provider.
    await tester.pumpAndSettle();

    // Verify that our app shows the dashboard title instead of basic text.
    expect(find.text('Brick Timer Dashboard'), findsOneWidget);
  });
}
