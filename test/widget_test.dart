import 'package:aman_sarthi/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  const englishTopics = [
    'Grammar',
    'Tenses',
    'Active and Passive Voice',
    'Direct and Indirect Speech',
    'Vocabulary',
    'Reading Comprehension',
    'Practice Quiz',
  ];

  testWidgets('English is available from Home with all requested topics', (
    tester,
  ) async {
    await tester.pumpWidget(const AmanSarthiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('English'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    for (final topic in englishTopics) {
      await tester.scrollUntilVisible(
        find.text(topic),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(topic), findsOneWidget);
    }
  });

  testWidgets('English remains available in Notes for board classes', (
    tester,
  ) async {
    await tester.pumpWidget(const AmanSarthiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CBSE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class 9'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    for (final topic in englishTopics) {
      await tester.scrollUntilVisible(
        find.text(topic),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(topic), findsOneWidget);
    }
  });

  testWidgets('Home exposes classes 6 to 12 and a labeled Graduation path', (
    tester,
  ) async {
    await tester.pumpWidget(const AmanSarthiApp());
    await tester.pumpAndSettle();

    final homeScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Class 6'),
      350,
      scrollable: homeScroll,
    );
    expect(find.text('Class 6'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Class 12'),
      350,
      scrollable: homeScroll,
    );
    expect(find.text('Class 12'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Graduation'),
      350,
      scrollable: homeScroll,
    );
    await tester.tap(find.text('Graduation').last);
    await tester.pumpAndSettle();

    expect(find.text('Demo learning path'), findsOneWidget);
    expect(find.textContaining('Local sample content'), findsOneWidget);
  });

  testWidgets('Lesson bookmarks persist and open from the profile', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(const AmanSarthiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Maths'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Maths').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Number System').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save bookmark'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.text('Number System'), findsOneWidget);
    expect(find.text('Maths'), findsOneWidget);
  });

  testWidgets('AI chat reports the missing backend instead of faking a reply', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(const AmanSarthiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI Tutor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chat shuru karein'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('AI_API_BASE_URL'),
      findsOneWidget,
      reason: 'The app must explain missing backend configuration.',
    );
    expect(find.text('Hello'), findsOneWidget);
  });
}
