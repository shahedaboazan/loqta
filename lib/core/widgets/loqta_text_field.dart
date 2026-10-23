import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:loqta/core/theme/app_theme.dart';

/// The text input used across the rebuilt screens.
///
/// Matches the approved references: a bold label sits *above* the field rather
/// than floating inside it, the field itself is a flat rounded grey box, and
/// icons sit on the trailing edge (trailing eye for passwords). Validation is
/// reported through [helper] so the message renders in the dedicated helper
/// line the designs reserve for it, instead of Material's red inline text.
class LoqtaTextField extends StatefulWidget {
  const LoqtaTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.trailingIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofillHints,
    this.helper,
    this.helperWidget,
    this.helperError = false,
    this.inputFormatters,
    this.focusNode,
    this.maxLines = 1,
  });

  final TextEditingController controller;

  /// Bold label rendered above the field.
  final String label;

  final String? hintText;

  /// Non-interactive trailing icon (mail, person, ...).
  final IconData? trailingIcon;

  /// When true a visibility toggle replaces [trailingIcon].
  final bool obscureText;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final int maxLines;

  /// Static helper text rendered under the field, e.g. "Must be at least 8
  /// characters".
  final String? helper;

  /// Custom helper content, used where the design pairs an icon with text.
  final Widget? helperWidget;

  /// Tints [helper] with the error colour.
  final bool helperError;

  @override
  State<LoqtaTextField> createState() => _LoqtaTextFieldState();
}

class _LoqtaTextFieldState extends State<LoqtaTextField> {
  late bool _obscureText = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: LoqtaText.fieldLabel),
        const SizedBox(height: 7),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          style: const TextStyle(
            color: LoqtaColors.textPrimary,
            fontSize: 14.5,
            fontFamily: LoqtaText.family,
          ),
          cursorColor: LoqtaColors.primary,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: LoqtaText.fieldHint,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: _buildSuffix(),
          ),
        ),
        if (widget.helper != null || widget.helperWidget != null) ...[
          const SizedBox(height: 7),
          if (widget.helperWidget != null)
            widget.helperWidget!
          else
            Row(
              children: [
                Icon(
                  widget.helperError
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  size: 13,
                  color: widget.helperError
                      ? LoqtaColors.error
                      : LoqtaColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.helper!,
                    style: LoqtaText.caption.copyWith(
                      color: widget.helperError
                          ? LoqtaColors.error
                          : LoqtaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  Widget? _buildSuffix() {
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _obscureText = !_obscureText),
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          size: 19,
          color: LoqtaColors.textSecondary,
        ),
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }
    if (widget.trailingIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Icon(
          widget.trailingIcon,
          size: 18,
          color: LoqtaColors.textSecondary,
        ),
      );
    }
    return null;
  }
}
