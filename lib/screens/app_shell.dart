import 'package:flutter/material.dart';
import '../models/app_page.dart';
import '../widgets/app_drawer.dart';
import 'implementing_page.dart';
import 'trend_analyzer_home_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage selectedPage = AppPage.home;

  Widget _buildBody() {
    switch (selectedPage) {
      case AppPage.home:
      case AppPage.searchTopic:
        return const TrendAnalyzerHomePage();

      case AppPage.recentSearches:
        return const ImplementingPage(title: 'Recent Searches');

      case AppPage.publications:
        return const ImplementingPage(title: 'Publications');

      case AppPage.details:
        return const ImplementingPage(title: 'Journal Details');

      case AppPage.trends:
        return const ImplementingPage(title: 'Keyword Trends');

      case AppPage.authors:
        return const ImplementingPage(title: 'Authors');

      case AppPage.journals:
        return const ImplementingPage(title: 'Journals');

      case AppPage.settings:
        return const ImplementingPage(title: 'Settings');

      case AppPage.about:
        return const ImplementingPage(title: 'About');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedPage: selectedPage,
        onPageSelected: (page) {
          setState(() {
            selectedPage = page;
          });
          // Close the drawer if it's open
          if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
            Navigator.of(context).pop();
          } else {
             // If accessed via a globally keyed Scaffold or similar, pop might pop the whole route.
             // Usually, Drawer opens a modal route.
             Navigator.of(context).pop(); 
          }
        },
      ),
      body: _buildBody(),
    );
  }
}
