import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/widgets/app_header.dart';
import 'package:algebrix/widgets/bottom_nav_bar.dart';
import 'package:algebrix/screens/home/home_screen.dart';
import 'package:algebrix/screens/lessons/lessons_screen.dart';
import 'package:algebrix/screens/notes/notes_screen.dart';
import 'package:algebrix/screens/practice/practice_screen.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/models/user_model.dart';

/// The root navigation scaffold that manages bottom navigation state,
/// fluid horizontal swipe gestures, and enforces auth locks.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final PageController _pageController;
  final UserModel _fallbackUser = UserModel.placeholder();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    LessonsScreen(),
    PracticeScreen(),
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
        bottom: false,
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
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
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
