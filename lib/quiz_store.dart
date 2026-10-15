import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    this.explanation = '',
    this.difficulty = 'Medium',
    this.marks = 1,
    this.negativeMarks = 0,
  });

  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String explanation;
  final String difficulty;
  final double marks;
  final double negativeMarks;

  factory QuizQuestion.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Each question must be a JSON object.');
    }
    final prompt = value['prompt'] ?? value['question'];
    final options = value['options'];
    final answer = value['answerIndex'] ?? value['answer'];
    if (prompt is! String ||
        options is! List ||
        options.length < 2 ||
        options.length > 8 ||
        options.any((option) => option is! String) ||
        answer is! int) {
      throw const FormatException(
        'Each question needs prompt, 2–8 text options, and an integer answerIndex.',
      );
    }
    final question = QuizQuestion(
      prompt: prompt.trim(),
      options: options.cast<String>().map((option) => option.trim()).toList(),
      answerIndex: answer,
      explanation: value['explanation'] is String
          ? (value['explanation'] as String).trim()
          : '',
      difficulty: value['difficulty'] is String
          ? (value['difficulty'] as String).trim()
          : 'Medium',
      marks: _number(value['marks'], defaultValue: 1),
      negativeMarks: _number(value['negativeMarks'], defaultValue: 0),
    );
    question.validate();
    return question;
  }

  void validate() {
    if (prompt.isEmpty || prompt.length > 2000) {
      throw const FormatException('Question text must contain 1–2000 characters.');
    }
    if (options.length < 2 ||
        options.length > 8 ||
        options.any((option) => option.isEmpty || option.length > 500)) {
      throw const FormatException(
        'Provide 2–8 non-empty answer options, each at most 500 characters.',
      );
    }
    if (options.toSet().length != options.length) {
      throw const FormatException('Answer options must be unique.');
    }
    if (answerIndex < 0 || answerIndex >= options.length) {
      throw const FormatException('answerIndex must point to an available option.');
    }
    if (!marks.isFinite || marks <= 0 || marks > 1000) {
      throw const FormatException('Marks must be greater than 0 and at most 1000.');
    }
    if (!negativeMarks.isFinite ||
        negativeMarks < 0 ||
        negativeMarks > marks) {
      throw const FormatException(
        'Negative marks must be between 0 and the question marks.',
      );
    }
    if (explanation.length > 4000 || difficulty.length > 40) {
      throw const FormatException('Explanation or difficulty is too long.');
    }
  }

  Map<String, Object> toJson() => {
    'prompt': prompt,
    'options': options,
    'answerIndex': answerIndex,
    'explanation': explanation,
    'difficulty': difficulty,
    'marks': marks,
    'negativeMarks': negativeMarks,
  };
}

class StudyQuiz {
  const StudyQuiz({
    required this.id,
    required this.title,
    required this.course,
    required this.subject,
    required this.chapter,
    required this.durationMinutes,
    required this.questions,
  });

  final String id;
  final String title;
  final String course;
  final String subject;
  final String chapter;
  final int durationMinutes;
  final List<QuizQuestion> questions;

  double get totalMarks =>
      questions.fold(0, (total, question) => total + question.marks);

  factory StudyQuiz.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('A quiz must be a JSON object.');
    }
    final questionsValue = value['questions'];
    if (questionsValue is! List ||
        questionsValue.isEmpty ||
        questionsValue.length > 100) {
      throw const FormatException('A quiz must contain 1–100 questions.');
    }
    final quiz = StudyQuiz(
      id: value['id'] is String && (value['id'] as String).isNotEmpty
          ? value['id'] as String
          : DateTime.now().microsecondsSinceEpoch.toString(),
      title: _requiredText(value['title'], 'title', 120),
      course: _optionalText(value['course'], 100),
      subject: _optionalText(value['subject'], 100),
      chapter: _optionalText(value['chapter'], 120),
      durationMinutes: _integer(value['durationMinutes'], defaultValue: 30),
      questions: questionsValue.map(QuizQuestion.fromJson).toList(),
    );
    quiz.validate();
    return quiz;
  }

  void validate() {
    if (id.isEmpty || id.length > 120) {
      throw const FormatException('Quiz id is invalid.');
    }
    _requiredText(title, 'title', 120);
    _optionalText(course, 100);
    _optionalText(subject, 100);
    _optionalText(chapter, 120);
    if (durationMinutes < 0 || durationMinutes > 600) {
      throw const FormatException('Duration must be between 0 and 600 minutes.');
    }
    if (questions.isEmpty || questions.length > 100) {
      throw const FormatException('A quiz must contain 1–100 questions.');
    }
    for (final question in questions) {
      question.validate();
    }
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'course': course,
    'subject': subject,
    'chapter': chapter,
    'durationMinutes': durationMinutes,
    'questions': questions.map((question) => question.toJson()).toList(),
  };
}

class QuizAttempt {
  const QuizAttempt({
    required this.quizId,
    required this.quizTitle,
    required this.answers,
    required this.correctCount,
    required this.answeredCount,
    required this.score,
    required this.totalMarks,
    required this.completedAt,
  });

  final String quizId;
  final String quizTitle;
  final List<int?> answers;
  final int correctCount;
  final int answeredCount;
  final double score;
  final double totalMarks;
  final DateTime completedAt;

  double get accuracy =>
      answeredCount == 0 ? 0 : correctCount * 100 / answeredCount;

  factory QuizAttempt.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['answers'] is! List ||
        value['quizId'] is! String ||
        value['quizTitle'] is! String ||
        value['completedAt'] is! String) {
      throw const FormatException('Saved test attempt has invalid data.');
    }
    final answers = (value['answers'] as List).map((answer) {
      if (answer == null) return null;
      if (answer is! int) {
        throw const FormatException('Saved answer is invalid.');
      }
      return answer;
    }).toList();
    return QuizAttempt(
      quizId: value['quizId'] as String,
      quizTitle: value['quizTitle'] as String,
      answers: answers,
      correctCount: _integer(value['correctCount']),
      answeredCount: _integer(value['answeredCount']),
      score: _number(value['score']),
      totalMarks: _number(value['totalMarks']),
      completedAt: DateTime.parse(value['completedAt'] as String),
    );
  }

  Map<String, Object?> toJson() => {
    'quizId': quizId,
    'quizTitle': quizTitle,
    'answers': answers,
    'correctCount': correctCount,
    'answeredCount': answeredCount,
    'score': score,
    'totalMarks': totalMarks,
    'completedAt': completedAt.toIso8601String(),
  };
}

class QuizDraft {
  const QuizDraft({
    required this.answers,
    required this.reviewedQuestions,
    required this.remainingSeconds,
  });

  final List<int?> answers;
  final Set<int> reviewedQuestions;
  final int remainingSeconds;
}

class QuizStore {
  QuizStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _quizzesKey = 'aman_sarthi_quizzes_v1';
  static const _attemptsKey = 'aman_sarthi_quiz_attempts_v1';
  static const _draftKeyPrefix = 'aman_sarthi_quiz_draft_v1_';

  final SharedPreferencesAsync _preferences;

  Future<List<StudyQuiz>> loadQuizzes() async {
    final saved = await _preferences.getString(_quizzesKey);
    if (saved == null) return [];
    final decoded = jsonDecode(saved);
    if (decoded is! List) {
      throw const FormatException('Saved question bank is not a list.');
    }
    return decoded.map(StudyQuiz.fromJson).toList();
  }

  Future<void> saveQuiz(StudyQuiz quiz) async {
    quiz.validate();
    final quizzes = await loadQuizzes();
    final index = quizzes.indexWhere((item) => item.id == quiz.id);
    if (index == -1) {
      quizzes.insert(0, quiz);
    } else {
      quizzes[index] = quiz;
    }
    await _preferences.setString(
      _quizzesKey,
      jsonEncode(quizzes.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> deleteQuiz(String id) async {
    final quizzes = await loadQuizzes()
      ..removeWhere((quiz) => quiz.id == id);
    await _preferences.setString(
      _quizzesKey,
      jsonEncode(quizzes.map((quiz) => quiz.toJson()).toList()),
    );
    await clearDraft(id);
  }

  Future<List<QuizAttempt>> loadAttempts({String? quizId}) async {
    final saved = await _preferences.getString(_attemptsKey);
    if (saved == null) return [];
    final decoded = jsonDecode(saved);
    if (decoded is! List) {
      throw const FormatException('Saved test history is not a list.');
    }
    final attempts = decoded.map(QuizAttempt.fromJson).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return quizId == null
        ? attempts
        : attempts.where((attempt) => attempt.quizId == quizId).toList();
  }

  Future<void> saveAttempt(QuizAttempt attempt) async {
    final attempts = await loadAttempts();
    attempts.insert(0, attempt);
    if (attempts.length > 100) attempts.removeRange(100, attempts.length);
    await _preferences.setString(
      _attemptsKey,
      jsonEncode(attempts.map((item) => item.toJson()).toList()),
    );
  }

  Future<QuizDraft> loadDraft(
    String quizId,
    int questionCount,
    int defaultRemainingSeconds,
  ) async {
    final saved = await _preferences.getString('$_draftKeyPrefix$quizId');
    if (saved == null) {
      return QuizDraft(
        answers: List<int?>.filled(questionCount, null),
        reviewedQuestions: const {},
        remainingSeconds: defaultRemainingSeconds,
      );
    }
    final decoded = jsonDecode(saved);
    if (decoded is! Map<String, dynamic> ||
        decoded['answers'] is! List ||
        decoded['reviewedQuestions'] is! List) {
      throw const FormatException('Saved test progress is invalid.');
    }
    final rawAnswers = decoded['answers'] as List;
    final answers = List<int?>.generate(questionCount, (index) {
      if (index >= rawAnswers.length || rawAnswers[index] == null) return null;
      final answer = rawAnswers[index];
      if (answer is! int || answer < 0) {
        throw const FormatException('Saved test answer is invalid.');
      }
      return answer;
    });
    final reviewed = (decoded['reviewedQuestions'] as List).map((value) {
      if (value is! int || value < 0 || value >= questionCount) {
        throw const FormatException('Saved review marker is invalid.');
      }
      return value;
    }).toSet();
    final remaining = _integer(
      decoded['remainingSeconds'],
      defaultValue: defaultRemainingSeconds,
    );
    if (remaining < 0 || remaining > defaultRemainingSeconds) {
      throw const FormatException('Saved test timer is invalid.');
    }
    return QuizDraft(
      answers: answers,
      reviewedQuestions: reviewed,
      remainingSeconds: remaining,
    );
  }

  Future<void> saveDraft(
    String quizId,
    List<int?> answers,
    Set<int> reviewedQuestions,
    int remainingSeconds,
  ) => _preferences.setString(
        '$_draftKeyPrefix$quizId',
        jsonEncode({
          'answers': answers,
          'reviewedQuestions': reviewedQuestions.toList(),
          'remainingSeconds': remainingSeconds,
        }),
      );

  Future<void> clearDraft(String quizId) =>
      _preferences.remove('$_draftKeyPrefix$quizId');
}

List<StudyQuiz> decodeQuizImport(String source) {
  final decoded = jsonDecode(source);
  final values = decoded is List
      ? decoded
      : decoded is Map<String, dynamic> && decoded['quizzes'] is List
      ? decoded['quizzes'] as List
      : [decoded];
  if (values.isEmpty || values.length > 50) {
    throw const FormatException('Import must contain 1–50 quizzes.');
  }
  final quizzes = values.map(StudyQuiz.fromJson).toList();
  if (quizzes.map((quiz) => quiz.id).toSet().length != quizzes.length) {
    throw const FormatException('Imported quizzes must have unique ids.');
  }
  return quizzes;
}

String _requiredText(Object? value, String label, int maxLength) {
  if (value is! String || value.trim().isEmpty || value.trim().length > maxLength) {
    throw FormatException('$label must contain 1–$maxLength characters.');
  }
  return value.trim();
}

String _optionalText(Object? value, int maxLength) {
  if (value == null) return '';
  if (value is! String || value.trim().length > maxLength) {
    throw FormatException('Text must contain at most $maxLength characters.');
  }
  return value.trim();
}

int _integer(Object? value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  throw const FormatException('Expected an integer value.');
}

double _number(Object? value, {double defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  throw const FormatException('Expected a numeric value.');
}
