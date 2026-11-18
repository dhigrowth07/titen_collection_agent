import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:collection_agent/modules/auth/viewmodel/auth_viewmodel.dart';
import 'package:collection_agent/modules/auth/views/widgets/login_phone_field.dart';

void main() {
  testWidgets('LoginPhoneField restricts input to 10 digits and numbers only', (WidgetTester tester) async {
    final authViewModel = AuthViewModel();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AuthViewModel>.value(
            value: authViewModel,
            child: const LoginPhoneField(),
          ),
        ),
      ),
    );

    final textFieldFinder = find.byType(TextFormField);
    expect(textFieldFinder, findsOneWidget);

    // Try entering 13 digits: 9876543210123
    await tester.enterText(textFieldFinder, '9876543210123');
    await tester.pump();

    // Verify text field clamped text to exactly 10 digits
    expect(authViewModel.phoneNumber, '9876543210');
    expect(authViewModel.phoneNumber.length, 10);
  });
}
