import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/data/module2/m2_l1_content.dart';
import 'package:algebrix/data/module2/m2_l2_content.dart';
import 'package:algebrix/data/module2/m2_l3_content.dart';
import 'package:algebrix/data/module2/m2_l4_content.dart';
import 'package:algebrix/data/module2/m2_l5_content.dart';
import 'package:algebrix/data/module2/m2_l6_content.dart';
import 'package:algebrix/data/module2/m2_l7_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

final module2 = ModuleContent(
  id: 'module2',
  title: 'Working with Expressions',
  description:
      'Make sense of the pieces.\n\nIn this module, we\'ll learn how to recognize like terms, combine them, use the distributive property, understand algebraic properties, simplify expressions, and evaluate them.',
  icon: '🧩',
  xyDialogue:
      "Ready to make sense of the pieces? Let's master how algebraic expressions work and fit together!",
  xyAsset: AppAssets.xyLessons,
  buttonLabel: 'Explore Module 2',
  lessons: [
    m2Lesson1,
    m2Lesson2,
    m2Lesson3,
    m2Lesson4,
    m2Lesson5,
    m2Lesson6,
    m2Lesson7,
  ],
);
