import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StudyCoachApp()),
    );
    // App builds without crashing
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
