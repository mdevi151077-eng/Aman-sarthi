import 'package:aman_sarthi/ai_chat.dart';
import 'package:aman_sarthi/ai_service.dart';
import 'package:aman_sarthi/main.dart';
import 'package:aman_sarthi/quiz_store.dart';
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

    final homeScroll = find
        .descendant(
          of: find.byKey(const ValueKey('home-dashboard-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final homeList = find.byKey(const ValueKey('home-dashboard-scroll'));
    for (final className in [
      'Class 6',
      'Class 7',
      'Class 8',
      'Class 9',
      'Class 10',
      'Class 11',
      'Class 12',
    ]) {
      await tester.scrollUntilVisible(
        find.text(className),
        350,
        scrollable: homeScroll,
      );
      await tester.tap(find.text(className).last);
      await tester.pumpAndSettle();
      expect(find.text(className).first, findsOneWidget);
      expect(find.text('Your courses'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    for (var attempt = 0; attempt < 6; attempt++) {
      if (find
          .byKey(const ValueKey('home-graduation-card'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.drag(homeList, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('home-graduation-card')), findsOneWidget);
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

  testWidgets('AI chat explains a missing backend without faking a reply', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(
      MaterialApp(
        home: AiChatPage(aiService: AiService.backend(baseUrl: '')),
      ),
    );
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

  testWidgets('students can complete a question and review its result', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await tester.pumpWidget(
      MaterialApp(
        home: QuizAttemptPage(
          quiz: StudyQuiz.fromJson({
            'title': 'My chapter test',
            'subject': 'Maths',
            'chapter': 'Algebra',
            'durationMinutes': 0,
            'questions': [
              {
                'prompt': '2 + 2?',
                'options': ['3', '4'],
                'answerIndex': 1,
                'explanation': 'Add two and two.',
                'marks': 2,
                'negativeMarks': 0.5,
              },
            ],
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 + 2?'), findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit test'));
    await tester.pumpAndSettle();

    expect(find.text('2.0 / 2.0 marks'), findsOneWidget);
    expect(find.textContaining('100.0% accuracy'), findsOneWidget);
    expect(find.text('Add two and two.'), findsOneWidget);
  });
}
