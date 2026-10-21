import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/login_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp(initialScreen: LoginScreen()));
    expect(find.text('ĐIỂM DANH SINH VIÊN'), findsOneWidget);
  });
}
