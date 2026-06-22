import 'package:flutter/material.dart';
import '../models/app/app_page.dart';

class AppDrawer extends StatelessWidget {
  final AppPage selectedPage;
  final Function(AppPage) onPageSelected;

  const AppDrawer({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2F6FB0);
    const bgColor = Color(0xFFFFFFFF);
    const activeBgColor = Color(0xFFEAF3FF);
    const textColor = Color(0xFF1F2937);
    const mutedColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFE5E7EB);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Drawer(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent, // Avoid material 3 tint
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // 1. App logo section
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Row(
                  children: [
                    // Mock logo icon
                    Icon(Icons.analytics, color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'openalex',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: mutedColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Navigation groups
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildNavGroup(
                    context: context,
                    title: 'Home',
                    icon: Icons.home_outlined,
                    initiallyExpanded:
                        true, // Always expand this group for easy access
                    children: [
                      _buildNavItem(
                        title: 'Search Topic',
                        icon: Icons.search,
                        page: AppPage.searchTopic,
                        primaryColor: primaryColor,
                        activeBgColor: activeBgColor,
                        mutedColor: mutedColor,
                        textColor: textColor,
                      ),
                    ],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  _buildNavGroup(
                    context: context,
                    title: 'Journal',
                    icon: Icons.menu_book_outlined,
                    initiallyExpanded: selectedPage == AppPage.journals,
                    children: [
                      _buildNavItem(
                        title: 'Search Journal',
                        icon: Icons.manage_search,
                        page: AppPage.journals,
                        primaryColor: primaryColor,
                        activeBgColor: activeBgColor,
                        mutedColor: mutedColor,
                        textColor: textColor,
                      ),
                    ],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  _buildNavGroup(
                    context: context,
                    title: 'Keywords',
                    icon: Icons.local_offer_outlined,
                    initiallyExpanded: selectedPage == AppPage.trends,
                    children: [
                      _buildNavItem(
                        title: 'Trends',
                        icon: Icons.trending_up,
                        page: AppPage.trends,
                        primaryColor: primaryColor,
                        activeBgColor: activeBgColor,
                        mutedColor: mutedColor,
                        textColor: textColor,
                      ),
                    ],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ],
              ),
            ),

            // Profile Card at bottom
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: activeBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                      foregroundColor: primaryColor,
                      child: const Text(
                        'AR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alex Researcher',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            'researcher@example.com',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: mutedColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavGroup({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool initiallyExpanded = false,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ), // Remove expansion tile border
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(icon, color: textColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 15,
          ),
        ),
        iconColor: mutedColor,
        collapsedIconColor: mutedColor,
        children: children,
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required AppPage page,
    required Color primaryColor,
    required Color activeBgColor,
    required Color mutedColor,
    required Color textColor,
  }) {
    // Treat home and searchTopic as active for 'Search Topic' if they map together,
    // but the user's prompt says: "Nếu selectedPage là home hoặc searchTopic thì Home/Search Topic active."
    bool isActive = selectedPage == page;
    if (page == AppPage.searchTopic && selectedPage == AppPage.home) {
      isActive = true;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 8.0,
        top: 4.0,
        bottom: 4.0,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? activeBgColor : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 0.0,
        ),
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? primaryColor : mutedColor,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? primaryColor : textColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          onPageSelected(page);
        },
      ),
    );
  }
}
