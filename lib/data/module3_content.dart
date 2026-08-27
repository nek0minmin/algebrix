import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/data/module3/m3_l1_content.dart';
import 'package:algebrix/data/module3/m3_l2_content.dart';
import 'package:algebrix/data/module3/m3_l3_content.dart';
import 'package:algebrix/data/module3/m3_l4_content.dart';
import 'package:algebrix/data/module3/m3_l5_content.dart';
import 'package:algebrix/data/module3/m3_l6_content.dart';
import 'package:algebrix/data/module3/m3_l7_content.dart';
import 'package:algebrix/data/module3/m3_l8_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

final module3 = ModuleContent(
  id: 'module3',
  title: 'Solving Equations',
  description:
      'Find the unknown. Keep it equal.\n\nIn this module, students learn to solve linear equations by maintaining equality, using inverse operations, and reasoning through increasingly complex equations.',
  icon: '⚖️',
  xyDialogue:
      "Ready to find the unknown? Let's master inverse operations and keep both sides perfectly balanced!",
  xyAsset: AppAssets.xyLessons,
  buttonLabel: 'Explore Module 3',
  lessons: [
    m3Lesson1,
    m3Lesson2,
    m3Lesson3,
    m3Lesson4,
    m3Lesson5,
    m3Lesson6,
    m3Lesson7,
    m3Lesson8,
  ],
);
