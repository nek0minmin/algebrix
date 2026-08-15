import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:flutter/foundation.dart';

/// State management for AI-assisted study notes features.
class AiNotesProvider extends ChangeNotifier {
  final AiTutorService _aiService;

  AiNotesProvider({AiTutorService? aiService})
      : _aiService = aiService ?? AiTutorService();

  bool _isAnalyzing = false;
  AiFeedbackResult? _currentFeedback;
  String? _improvedSuggestion;
  String? _errorMessage;

  bool get isAnalyzing => _isAnalyzing;
  AiFeedbackResult? get currentFeedback => _currentFeedback;
  String? get improvedSuggestion => _improvedSuggestion;
  String? get errorMessage => _errorMessage;

  Future<void> checkWorkedExample({
    required String problem,
    required String solution,
  }) async {
    _startAnalyzing();
    try {
      _currentFeedback = await _aiService.checkWorkedExample(
        problem: problem,
        solution: solution,
      );
    } catch (e) {
      _errorMessage = 'Could not verify worked example. Please try again.';
    } finally {
      _stopAnalyzing();
    }
  }

  Future<void> diagnoseMistake({
    required String problem,
    required String incorrectAnswer,
  }) async {
    _startAnalyzing();
    try {
      _currentFeedback = await _aiService.diagnoseMistake(
        problem: problem,
        incorrectAnswer: incorrectAnswer,
      );
    } catch (e) {
      _errorMessage = 'Could not diagnose step. Please try again.';
    } finally {
      _stopAnalyzing();
    }
  }

  Future<void> getSocraticHint({
    required String question,
    String hintType = 'hint',
  }) async {
    _startAnalyzing();
    try {
      _currentFeedback = await _aiService.getSocraticHint(
        question: question,
        hintType: hintType,
      );
    } catch (e) {
      _errorMessage = 'Could not retrieve hint. Please try again.';
    } finally {
      _stopAnalyzing();
    }
  }

  Future<void> evaluateExplanation({
    required String topic,
    required String explanation,
  }) async {
    _startAnalyzing();
    try {
      _currentFeedback = await _aiService.evaluateExplanation(
        topic: topic,
        studentExplanation: explanation,
      );
    } catch (e) {
      _errorMessage = 'Could not check explanation. Please try again.';
    } finally {
      _stopAnalyzing();
    }
  }

  Future<String?> improveUnderstanding(String rawNote) async {
    _startAnalyzing();
    _improvedSuggestion = null;
    try {
      final result = await _aiService.improveUnderstanding(rawNote: rawNote);
      _improvedSuggestion = result;
      return result;
    } catch (e) {
      _errorMessage = 'Could not generate suggestion. Please try again.';
      return null;
    } finally {
      _stopAnalyzing();
    }
  }

  void setFeedback(AiFeedbackResult feedback) {
    _currentFeedback = feedback;
    notifyListeners();
  }

  void clearFeedback() {
    _currentFeedback = null;
    _improvedSuggestion = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _startAnalyzing() {
    _isAnalyzing = true;
    _currentFeedback = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopAnalyzing() {
    _isAnalyzing = false;
    notifyListeners();
  }
}
