import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoctorTextField extends StatelessWidget {
  const DoctorTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.obscureText = false,
    this.singleLineVerticalPadding,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final bool obscureText;
  final double? singleLineVerticalPadding;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          buildCounter: maxLength == null
              ? null
              : (
                  BuildContext context, {
                  required int currentLength,
                  required bool isFocused,
                  required int? maxLength,
                }) =>
                    null,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            errorMaxLines: 3,
            suffixIcon: suffixIcon,
            suffixIconConstraints: suffixIcon == null
                ? null
                : const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: maxLines > 1 ? 10 : (singleLineVerticalPadding ?? 8),
            ),
          ),
        ),
      ],
    );
  }
}
