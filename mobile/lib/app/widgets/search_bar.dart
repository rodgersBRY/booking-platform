import 'package:flutter/material.dart';

/// Search input with a reactive clear button. Named AppSearchBar to avoid
/// colliding with Flutter's own material SearchBar widget.
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  /// Defaults to true (the original behavior, right for a freshly-pushed
  /// search screen like SearchPage). Pass false when this bar lives on a
  /// screen that can be mounted off-screen — e.g. a bottom-nav tab inside
  /// an IndexedStack, which builds every tab immediately — where grabbing
  /// focus/keyboard while invisible would be surprising.
  final bool autofocus;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search',
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}
