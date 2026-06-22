import 'package:flutter/material.dart';

import '../../utils/app_keys.dart';
import '../journal/journal_search_screen.dart';
import '../keyword/keyword_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../trend/trend_analyzer_home_page_screen.dart';

/// The root navigation shell of the app. Uses an [IndexedStack] + [BottomNavigationBar]
/// so each tab preserves its state when the user switches between tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Keep screens alive by building them once inside IndexedStack.
  static final List<Widget> _screens = [
    const TrendAnalyzerHomePage(),
    const JournalSearchScreen(),
    const KeywordDashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // No drawer, no leading menu button — just content + bottom nav.
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        primaryColor: colorScheme.primary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable bottom navigation bar
// ---------------------------------------------------------------------------

class _AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Color primaryColor;

  const _AppBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.primaryColor,
  });

  static const _items = [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(
      label: 'Journal',
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
    ),
    _NavItem(
      label: 'Keywords',
      icon: Icons.sell_outlined,
      activeIcon: Icons.sell,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.brightness == Brightness.dark
        ? Colors.grey.shade500
        : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = index == selectedIndex;
              return Expanded(
                child: _NavButton(
                  key: [
                    AppKeys.homeTab,
                    AppKeys.journalsTab,
                    AppKeys.keywordsTab,
                    AppKeys.profileTab,
                  ][index],
                  item: item,
                  isSelected: isSelected,
                  primaryColor: primaryColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Color primaryColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? primaryColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
