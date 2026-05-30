import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  final Widget child;

  const AppBottomNav({super.key, required this.child});

  static const _tabs = [
    _TabItem(path: '/home', icon: Icons.home_rounded, label: 'Home'),
    _TabItem(
      path: '/mood',
      icon: Icons.sentiment_satisfied_rounded,
      label: 'Mood',
    ),
    _TabItem(
      path: '/workout',
      icon: Icons.fitness_center_rounded,
      label: 'Workout',
    ),
    _TabItem(path: '/goals', icon: Icons.track_changes_rounded, label: 'Goals'),
    _TabItem(path: '/profile', icon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
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
