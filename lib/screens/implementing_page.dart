import 'package:flutter/material.dart';

class ImplementingPage extends StatelessWidget {
  final String title;
  final VoidCallback? onOpenDrawer;

  const ImplementingPage({super.key, required this.title, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            onOpenDrawer?.call();
          },
        ),
      ),
      body: const Center(
        child: Text(
          'This feature is being implemented',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
