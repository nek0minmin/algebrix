import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/data/module4/m4_l1_content.dart';
import 'package:algebrix/data/module4/m4_l2_content.dart';
import 'package:algebrix/data/module4/m4_l3_content.dart';
import 'package:algebrix/data/module4/m4_l4_content.dart';
import 'package:algebrix/data/module4/m4_l5_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

final module4 = ModuleContent(
  id: 'module4',
  title: 'Inequalities',
  description:
      'Not just one answer.\n\nLearn how to solve one-step and two-step '
      'inequalities, understand why negatives reverse the sign, and represent '
      'whole ranges of solutions by graphing them on a number line.',
  icon: '📊',
  xyDialogue:
      "Equations point at one value. Inequalities open up a whole range — let's "
      "learn to find them and draw them!",
  xyAsset: AppAssets.xyLessons,
  buttonLabel: 'Explore Module 4',
  lessons: [
    m4Lesson1,
    m4Lesson2,
    m4Lesson3,
    m4Lesson4,
    m4Lesson5,
  ],
);
