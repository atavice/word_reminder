import 'package:flutter_test/flutter_test.dart';
import 'package:word_reminder/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const WordReminderApp());
    expect(find.text('WordReminder'), findsOneWidget);
  });
}
