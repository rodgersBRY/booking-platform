import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Honest placeholder for features that don't have a data source yet
/// (Explore, Favorites, Notifications, Promotions). One shared widget,
/// parameterized per feature — no fake content.
class ComingSoonPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// When true, wraps in a Scaffold with an AppBar (for full-screen
  /// pushes); when false, renders bare (for use as a tab body).
  final bool withAppBar;

  const ComingSoonPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.withAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = EmptyState(icon: icon, title: title, subtitle: subtitle);
    if (!withAppBar) return Scaffold(body: body);
    return Scaffold(appBar: AppBar(title: Text(title)), body: body);
  }
}
