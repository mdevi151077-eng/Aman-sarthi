import 'dart:convert';

import 'package:aman_sarthi/quiz_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('validates and imports question banks up to 100 questions', () {
    final questions = List.generate(
      100,
      (index) => {
        'prompt': 'Question $index',
        'options': ['one', 'two'],
        'answerIndex': 0,
      },
    );
    final quizzes = decodeQuizImport(
      jsonEncode({'title': 'Chapter test', 'questions': questions}),
    );

    expect(quizzes, hasLength(1));
    expect(quizzes.single.questions, hasLength(100));
    expect(quizzes.single.totalMarks, 100);
  });

  test(
    'rejects invalid answer keys, duplicate options, and oversized imports',
    () {
      expect(
        () => StudyQuiz.fromJson({
          'title': 'Bad answer',
          'questions': [
            {
              'prompt': 'Question?',
              'options': ['A', 'B'],
              'answerIndex': 2,
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => StudyQuiz.fromJson({
          'title': 'Duplicate options',
          'questions': [
            {
              'prompt': 'Question?',
              'options': ['A', 'A'],
              'answerIndex': 0,
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => StudyQuiz.fromJson({
          'title': 'Too many',
          'questions': List.generate(
            101,
            (_) => {
              'prompt': 'Q',
              'options': ['A', 'B'],
              'answerIndex': 0,
            },
          ),
        }),
        throwsFormatException,
      );
    },
  );

  test('stores quizzes, resumable answers and timed review markers', () async {
    final store = QuizStore();
    final quiz = StudyQuiz.fromJson({
      'title': 'Algebra',
      'subject': 'Maths',
      'chapter': 'Linear equations',
      'durationMinutes': 20,
      'questions': [
        {
          'prompt': 'Question?',
          'options': ['A', 'B'],
          'answerIndex': 1,
          'marks': 2,
          'negativeMarks': 0.5,
          'explanation': 'Because B is correct.',
        },
      ],
    });
    await store.saveQuiz(quiz);
    await store.saveDraft(quiz.id, [0], {0}, 321);

    final restored = await store.loadQuizzes();
    final draft = await store.loadDraft(quiz.id, 1, 1200);

    expect(restored.single.title, 'Algebra');
    expect(
      restored.single.questions.single.explanation,
      'Because B is correct.',
    );
    expect(draft.answers, [0]);
    expect(draft.reviewedQuestions, {0});
    expect(draft.remainingSeconds, 321);
  });

  test('records attempt accuracy and score with negative marking', () async {
    final store = QuizStore();
    final attempt = QuizAttempt(
      quizId: 'quiz-1',
      quizTitle: 'Practice',
      answers: [0, 1, null],
      correctCount: 1,
      answeredCount: 2,
      score: 0.5,
      totalMarks: 2,
      completedAt: DateTime.utc(2026, 1, 1),
    );

    await store.saveAttempt(attempt);
    final attempts = await store.loadAttempts(quizId: 'quiz-1');

    expect(attempts, hasLength(1));
    expect(attempts.single.accuracy, 50);
    expect(attempts.single.score, 0.5);
    expect(attempts.single.answers, [0, 1, null]);
  });
}
