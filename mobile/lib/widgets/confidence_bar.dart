import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ConfidenceBar extends StatelessWidget {
  final double confidence;
  final double height;

  const ConfidenceBar({super.key, required this.confidence, this.height = 8});

  Color _getColor() {
    if (confidence < 0.4) return AppColors.success;
    if (confidence < 0.7) return AppColors.warning;
    return AppColors.crisisRed;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _getColor(),
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: confidence),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
                  minHeight: height,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
