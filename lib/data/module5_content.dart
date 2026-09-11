import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/data/module5/m5_l1_content.dart';
import 'package:algebrix/data/module5/m5_l2_content.dart';
import 'package:algebrix/data/module5/m5_l3_content.dart';
import 'package:algebrix/data/module5/m5_l4_content.dart';
import 'package:algebrix/data/module5/m5_l5_content.dart';
import 'package:algebrix/data/module5/m5_l6_content.dart';
import 'package:algebrix/data/module5/m5_l7_content.dart';
import 'package:algebrix/data/module5/m5_l8_content.dart';
import 'package:algebrix/models/lesson_content_model.dart';

final module5 = ModuleContent(
  id: 'module5',
  title: 'Linear Relationships',
  description:
      'Algebra you can see.\n\nPlot points on the coordinate plane, discover '
      'what slope really measures, and learn to move freely between a story, a '
      'table, an equation and a graph — then take the sliders into the Line '
      'Lab and watch a line answer you.',
  icon: '📈',
  xyDialogue:
      "Until now algebra lived on a line. Let's give it a second dimension — "
      "and watch equations turn into pictures!",
  xyAsset: AppAssets.xyLessons,
  buttonLabel: 'Explore Module 5',
  lessons: [
    m5Lesson1,
    m5Lesson2,
    m5Lesson3,
    m5Lesson4,
    m5Lesson5,
    m5Lesson6,
    m5Lesson7,
    m5Lesson8,
  ],
);
