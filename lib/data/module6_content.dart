import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/data/module6/m6_l1_content.dart';
import 'package:algebrix/data/module6/m6_l2_content.dart';
import 'package:algebrix/data/module6/m6_l3_content.dart';
import 'package:algebrix/data/module6/m6_l4_content.dart';
import 'package:algebrix/data/module6/m6_l5_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

final module6 = ModuleContent(
  id: 'module6',
  title: 'Polynomials',
  description:
      'Expressions with more moving parts.\n\nName the pieces of a polynomial, '
      'add and subtract them without losing a sign, multiply them with an area '
      'model, and run that model backwards to factor.',
  icon: '🔷',
  xyDialogue:
      "Expressions can grow much longer than 3x + 2 — and every rule you "
      "already know still works. Let's scale up!",
  xyAsset: AppAssets.xyLessons,
  buttonLabel: 'Explore Module 6',
  lessons: [
    m6Lesson1,
    m6Lesson2,
    m6Lesson3,
    m6Lesson4,
    m6Lesson5,
  ],
);
