import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/models/distortion_result.dart';
import '../core/theme/app_theme.dart';
import 'confidence_bar.dart';

class DistortionCard extends StatefulWidget {
  final DistortionResult distortion;
  final int index;
  final Color? accentColor;

  const DistortionCard({
    super.key,
    required this.distortion,
    required this.index,
    this.accentColor,
  });

  @override
  State<DistortionCard> createState() => _DistortionCardState();
}

class _DistortionCardState extends State<DistortionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        widget.accentColor ??
        AppColors.chipColors[widget.index % AppColors.chipColors.length];

    return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.distortion.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConfidenceBar(confidence: widget.distortion.confidence),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        widget.distortion.description,
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                      ),
                    ),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 80 * widget.index),
          duration: const Duration(milliseconds: 400),
        )
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 80 * widget.index),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
  }
}
