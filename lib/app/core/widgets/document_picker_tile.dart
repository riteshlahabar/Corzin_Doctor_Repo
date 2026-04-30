import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DocumentPickerTile extends StatelessWidget {
  const DocumentPickerTile({
    super.key,
    required this.title,
    required this.fileName,
    required this.onTap,
    this.hasError = false,
    this.errorText,
  });

  final String title;
  final String? fileName;
  final VoidCallback onTap;
  final bool hasError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: hasError ? const Color(0xFFD32F2F) : AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName ?? 'Tap to upload required file',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: fileName == null ? AppColors.grey : AppColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
              ],
            ),
          ),
        ),
        if (hasError && errorText != null && errorText!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD32F2F),
              ),
            ),
          ),
      ],
    );
  }
}
