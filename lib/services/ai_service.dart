import 'package:algebrix/models/equation_model.dart';

/// Conceptual reflection question presented after solving an equation to prevent button spamming.
class ReflectionQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const ReflectionQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

/// Service powering Xy mascot's anti-spamming conceptual guidance and reflection challenges.
class AiService {
  /// Generates synchronized hints matching the student's isolation & balance steps.
  String generateXyAdvice({
    required EquationModel equation,
  }) {
    if (equation.isSolved) {
      return "🎉 PERFECT ISOLATION! You kept the scale balanced and discovered X = ${equation.targetXValue}!";
    }

    final diff = equation.weightDifference;

    if (diff != 0) {
      if (diff > 0) {
        return "⚠️ Scale tilted! Right pan is heavier. Think: what strategic move balances both sides?";
      } else {
        return "⚠️ Scale tilted! Left pan is heavier. Think: what strategic move balances both sides?";
      }
    }

    if (equation.leftUnits > 0) {
      return "💡 Think strategically: What algebraic operation on BOTH sides will isolate X?";
    }

    if (equation.leftVariables > 1) {
      return "💡 Think: You have ${equation.leftVariables}X. What operation gives you 1 X?";
    }

    return "Choose the correct algebraic strategy to isolate X!";
  }

  /// Generates a post-solve conceptual reflection question to verify understanding.
  ReflectionQuestion generateReflectionQuestion(EquationModel equation) {
    if (equation.initialLeftUnits > 0) {
      return ReflectionQuestion(
        question: "Why did subtracting ${equation.initialLeftUnits} from BOTH sides solve the equation?",
        options: [
          "It isolated X while keeping both sides equal",
          "It made the numbers smaller on the scale",
          "Because ${equation.initialLeftUnits} was the smallest number",
        ],
        correctIndex: 0,
        explanation: "Subtracting the same amount from both sides maintains equality (Addition/Subtraction Property of Equality) and isolates X!",
      );
    } else {
      return ReflectionQuestion(
        question: "Why did dividing BOTH sides by 2 work?",
        options: [
          "It split 2X into 1X while keeping the scale balanced",
          "Because division is always mandatory",
          "To make the scale tilt to the left",
        ],
        correctIndex: 0,
        explanation: "Dividing both sides by the coefficient scales both sides down equally, leaving 1X!",
      );
    }
  }
}
