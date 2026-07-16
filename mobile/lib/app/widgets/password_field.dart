import 'package:flutter/material.dart';

/// TextField for password entry with a show/hide toggle. Visibility is
/// local UI state — it doesn't belong on the GetX controller.
class PasswordField extends StatefulWidget {
  final String label;
  final String? helperText;
  final ValueChanged<String> onChanged;

  const PasswordField({
    super.key,
    required this.label,
    required this.onChanged,
    this.helperText,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        suffixIcon: IconButton(
          icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
      obscureText: _obscured,
      onChanged: widget.onChanged,
    );
  }
}
