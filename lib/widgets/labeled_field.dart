import 'package:flutter/material.dart';
import '../theme.dart';

/// A form input with the design's exact label-above-field style, backed by
/// a persistent [TextEditingController] so focus/cursor position survives
/// the parent's rebuilds while typing.
class LabeledField extends StatefulWidget {
  final String label;
  final String value;
  final String? placeholder;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    this.placeholder,
  });

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.placeholder,
            hintStyle: const TextStyle(fontSize: 13, color: AdminColors.placeholder),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AdminColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.accentColor),
            ),
          ),
        ),
      ],
    );
  }
}
