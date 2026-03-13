// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_companion_app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: VirtualCompanionApp()),
    );
    expect(find.text('下一步'), findsOneWidget);
  });
}
