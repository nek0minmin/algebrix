import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/widgets/app_header.dart';
import 'package:algebrix/widgets/bottom_nav_bar.dart';
import 'package:algebrix/screens/home/home_screen.dart';
import 'package:algebrix/screens/lessons/lessons_screen.dart';
import 'package:algebrix/screens/notes/notes_screen.dart';
import 'package:algebrix/screens/practice/quiz_screen.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/models/user_model.dart';

/// The root navigation scaffold that manages bottom navigation state and enforces auth locks.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final UserModel _fallbackUser = UserModel.placeholder();

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    LessonsScreen(),
    QuizScreen(),
    NotesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Lock dashboard access so unauthenticated users cannot bypass LoginScreen
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.pink)),
      );
    }

    final currentUser = authProvider.currentUser ?? _fallbackUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              userName: currentUser.name,
              onLogoutTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
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
