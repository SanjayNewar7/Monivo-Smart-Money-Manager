import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import 'bottom_nav.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350), // Smooth duration
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.reset();
      _controller.forward();
    }
  }

  /// Determines the slide direction based on navigation
  Offset _getSlideDirection() {
    final isMovingForward = widget.currentIndex > _previousIndex;

    // Handle wrap-around cases (Settings -> Home should go left)
    if (_previousIndex == 4 && widget.currentIndex == 0) {
      return const Offset(-1.0, 0.0); // Slide from left
    }
    if (_previousIndex == 0 && widget.currentIndex == 4) {
      return const Offset(1.0, 0.0); // Slide from right
    }

    // Normal navigation
    return isMovingForward
        ? const Offset(1.0, 0.0)  // Next screen slides from right
        : const Offset(-1.0, 0.0); // Previous screen slides from left
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (widget.currentIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/transactions');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/analytics');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/budgets');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Screen content with slide and fade transition
      body: SlideTransition(
        position: Tween<Offset>(
          begin: _getSlideDirection(),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic, // Smooth easing curve
        )),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        ),
      ),
      // Bottom navigation - completely static with no transitions
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            color: Colors.white, // Fixed background color
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      selectedColor: themeProvider.primaryColor,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.list_alt_outlined,
                      activeIcon: Icons.list_alt,
                      label: 'Transactions',
                      selectedColor: themeProvider.primaryColor,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.pie_chart_outline,
                      activeIcon: Icons.pie_chart,
                      label: 'Analytics',
                      selectedColor: themeProvider.primaryColor,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.track_changes_outlined,
                      activeIcon: Icons.track_changes,
                      label: 'Budgets',
                      selectedColor: themeProvider.primaryColor,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                      selectedColor: themeProvider.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color selectedColor,
  }) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? selectedColor : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Darker Grotesque',
                fontSize: 11,
                color: isSelected ? selectedColor : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}