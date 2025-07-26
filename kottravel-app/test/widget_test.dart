import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';
import '../lib/screens/landing_screen.dart';

void main() {
  testWidgets('App starts and displays LandingScreen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KottravelApp());

    // Verify that the LandingScreen is the first screen shown.
    expect(find.byType(LandingScreen), findsOneWidget);

    // This test can be expanded later to simulate navigation to the HomeScreen.
  });
}
