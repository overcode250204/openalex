import 'package:flutter/material.dart';
import '../models/app_page.dart';
import '../widgets/app_drawer.dart';
import 'journal/journal_search_screen.dart';
import 'keyword_analyzer_page.dart';
import 'trend_analyzer_home_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage selectedPage = AppPage.home;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onPageSelected(AppPage page) {
    setState(() {
      selectedPage = page;
    });

    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBody() {
    switch (selectedPage) {
      case AppPage.home:
      case AppPage.searchTopic:
        return TrendAnalyzerHomePage(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );



      case AppPage.trends:
        return KeywordAnalyzerPage(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );



      case AppPage.journals:
        return JournalSearchScreen(
          onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        );


    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        selectedPage: selectedPage,
        onPageSelected: (page) {
          _onPageSelected(page);
        },
      ),
      body: _buildBody(),
    );
  }
}
