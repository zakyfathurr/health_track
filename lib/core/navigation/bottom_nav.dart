import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;

  const AppBottomNav({super.key, required this.child});

  // Maksimal 5 tab. Jangan ditambah lagi.
  static const _tabs = [
    _TabItem(path: '/home', icon: Icons.home_rounded, label: 'Home'),
    _TabItem(path: '/mood', icon: Icons.sentiment_satisfied_rounded, label: 'Mood'),
    _TabItem(path: '/goals', icon: Icons.track_changes_rounded, label: 'Goals'),
    _TabItem(path: '/community', icon: Icons.forum_rounded, label: 'Community'),
    _TabItem(path: '/profile', icon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      // Pastikan pencocokan path lebih spesifik agar tidak bentrok
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: _tabs
            .map(
              (tab) =>
              NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        )
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final String label;

  const _TabItem({required this.path, required this.icon, required this.label});
}