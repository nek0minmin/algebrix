import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/widgets/app_header.dart';
import 'package:algebrix/widgets/bottom_nav_bar.dart';
import 'package:algebrix/screens/home/home_screen.dart';
import 'package:algebrix/screens/lessons/lessons_screen.dart';
import 'package:algebrix/screens/practice/quiz_screen.dart';
import 'package:algebrix/screens/practice/practice_screen.dart';
import 'package:algebrix/models/user_model.dart';

/// The root navigation scaffold that manages bottom navigation state.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  // Using placeholder user for now
  final UserModel _user = UserModel.placeholder();

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    LessonsScreen(),
    QuizScreen(),
    PracticeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              userName: _user.name,
              onProfileTap: () {
                // TODO: Implement profile tap
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
