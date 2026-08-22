enum QuizQuestionType {
  multipleChoice,
  trueFalse;

  static QuizQuestionType fromString(String val) {
    if (val.toLowerCase().contains('true') ||
        val.toLowerCase().contains('tf') ||
        val.toLowerCase().contains('boolean')) {
      return QuizQuestionType.trueFalse;
    }
    return QuizQuestionType.multipleChoice;
  }
}

class ModuleQuizQuestion {
  final String id;
  final String subLessonTitle;
  final String question;
  final QuizQuestionType type;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int difficulty; // 1 = Foundations, 2 = Procedural, 3 = Mastery

  const ModuleQuizQuestion({
    required this.id,
    required this.subLessonTitle,
    required this.question,
    required this.type,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
  });

  factory ModuleQuizQuestion.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final rawType = json['type'] as String? ?? 'multipleChoice';
    final type = QuizQuestionType.fromString(rawType);

    final rawOptions = (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];

    // Ensure options count matches question type
    List<String> options;
    int correctIndex = (json['correctIndex'] as num?)?.toInt() ?? 0;

    if (type == QuizQuestionType.trueFalse) {
      if (rawOptions.length >= 2) {
        options = rawOptions.take(2).toList();
      } else {
        options = ['True', 'False'];
      }
    } else {
      if (rawOptions.length >= 3) {
        options = rawOptions.take(3).toList();
      } else {
        options = [...rawOptions, 'Option B', 'Option C'].take(3).toList();
      }
    }

    // Sanitize correctIndex
    if (correctIndex < 0 || correctIndex >= options.length) {
      correctIndex = 0;
    }

    // Determine progressive difficulty based on question index (1-15)
    final diff = index <= 5 ? 1 : (index <= 10 ? 2 : 3);

    return ModuleQuizQuestion(
      id: json['id'] as String? ?? 'q_$index',
      subLessonTitle: json['subLessonTitle'] as String? ?? 'Algebra Concept',
      question: json['question'] as String? ?? 'Solve the problem:',
      type: type,
      options: options,
      correctIndex: correctIndex,
      explanation: json['explanation'] as String? ??
          'Apply the algebraic property step-by-step.',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? diff,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subLessonTitle': subLessonTitle,
        'question': question,
        'type': type.name,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'difficulty': difficulty,
      };
}

class ModuleQuiz {
  final String moduleId;
  final String moduleTitle;
  final List<ModuleQuizQuestion> questions;
  final DateTime generatedAt;
  final String providerUsed;

  const ModuleQuiz({
    required this.moduleId,
    required this.moduleTitle,
    required this.questions,
    required this.generatedAt,
    required this.providerUsed,
  });

  factory ModuleQuiz.fromJson(
    Map<String, dynamic> json, {
    required String moduleId,
    required String moduleTitle,
    required String providerUsed,
  }) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final parsedQuestions = <ModuleQuizQuestion>[];

    for (var i = 0; i < rawQuestions.length; i++) {
      if (rawQuestions[i] is Map<String, dynamic>) {
        parsedQuestions.add(
          ModuleQuizQuestion.fromJson(
            rawQuestions[i] as Map<String, dynamic>,
            index: i + 1,
          ),
        );
      }
    }

    return ModuleQuiz(
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      questions: parsedQuestions,
      generatedAt: DateTime.now(),
      providerUsed: providerUsed,
    );
  }

  int get totalQuestions => questions.length;
}
