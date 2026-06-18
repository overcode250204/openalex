import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
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
                    children: [
                      _buildNavItem('Search Topic', Icons.search, mutedColor, textColor),
                      _buildNavItem('Recent Searches', Icons.history, mutedColor, textColor),
                    ],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  _buildNavGroup(
                    context: context,
                    title: 'Journal',
                    icon: Icons.menu_book_outlined,
                    children: [
                      _buildNavItem('Publications', Icons.article_outlined, mutedColor, textColor),
                      _buildNavItem('Details', Icons.bar_chart, mutedColor, textColor),
                    ],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  _buildNavGroup(
                    context: context,
                    title: 'Keywords',
                    icon: Icons.local_offer_outlined,
                    initiallyExpanded: true,
                    children: [
                      _buildActiveNavItem('Trends', Icons.trending_up, primaryColor, activeBgColor),
                      _buildNavItem('Authors', Icons.person_outline, mutedColor, textColor),
                      _buildNavItem('Journals', Icons.account_balance_outlined, mutedColor, textColor),
                    ],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                  const SizedBox(height: 8),
                  _buildNavGroup(
                    context: context,
                    title: 'Profile',
                    icon: Icons.person_outline,
                    children: [
                      _buildNavItem('Settings', Icons.settings_outlined, mutedColor, textColor),
                      _buildNavItem('About', Icons.info_outline, mutedColor, textColor),
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
                      backgroundColor: primaryColor.withOpacity(0.2),
                      foregroundColor: primaryColor,
                      child: const Text('AR', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                            ),
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
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // Remove expansion tile border
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

  Widget _buildNavItem(String title, IconData icon, Color mutedColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 4.0, bottom: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        dense: true,
        leading: Icon(icon, color: mutedColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildActiveNavItem(String title, IconData icon, Color primaryColor, Color activeBgColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 4.0, bottom: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: activeBgColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        dense: true,
        leading: Icon(icon, color: primaryColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
