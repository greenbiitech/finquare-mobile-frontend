import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finsquare_mobile_app/app.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FinSquareApp(),
      ),
    );

    // Verify app renders with FinSquare text
    expect(find.text('FinSquare'), findsOneWidget);
  });
}
