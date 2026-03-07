import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/cards/partner_card.dart';

void main() {
  group('PartnerCard', () {
    testWidgets('builds and shows partner name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PartnerCard(
              id: 'p1',
              name: 'Partner One',
              age: 25,
              avatarUrl: 'https://example.com/avatar.jpg',
              rating: 4.5,
              reviews: 10,
              hourlyRate: '100k',
            ),
          ),
        ),
      );

      expect(find.text('Partner One, 25'), findsOneWidget);
    });

    testWidgets('shows online badge when isOnline is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PartnerCard(
              id: 'p2',
              name: 'Online Partner',
              age: 28,
              avatarUrl: '',
              rating: 4.8,
              reviews: 5,
              hourlyRate: '150k',
              isOnline: true,
            ),
          ),
        ),
      );

      expect(find.text('Online Partner, 28'), findsOneWidget);
    });
  });
}
