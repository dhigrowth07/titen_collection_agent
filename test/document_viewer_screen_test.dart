import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collection_agent/shared/views/document_viewer_screen.dart';
import 'package:collection_agent/core/constants/app_strings.dart';

void main() {
  group('DocumentViewerScreen Widget Tests', () {
    testWidgets('renders empty URL error gracefully without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentViewerScreen(
            url: '',
            title: 'Test Empty Doc',
            subtitle: 'Tenant Name',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Test Empty Doc'), findsOneWidget);
      expect(find.text('Tenant Name'), findsOneWidget);
      expect(find.text(AppStrings.failedToLoadDocument), findsOneWidget);
      expect(find.text('No document URL provided'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });

    testWidgets('renders whitespace URL error gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentViewerScreen(
            url: '   ',
            title: 'Whitespace Doc',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Whitespace Doc'), findsOneWidget);
      expect(find.text('No document URL provided'), findsOneWidget);
    });

    testWidgets('identifies image URL and renders title and refresh action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DocumentViewerScreen(
            url: 'https://example.com/id_proof.png?token=12345',
            title: 'ID Proof (PNG)',
            subtitle: 'John Doe',
          ),
        ),
      );

      expect(find.text('ID Proof (PNG)'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });
}

