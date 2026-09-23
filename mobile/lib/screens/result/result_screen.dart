import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../widgets/distortion_card.dart';
import '../../widgets/crisis_overlay.dart';
import '../reframe/reframe_screen.dart';

class ResultScreen extends ConsumerWidget {
  final String journalText;
  final PredictApiResult predictResult;

  const ResultScreen({
    super.key,
    required this.journalText,
    required this.predictResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (predictResult.isCrisis) {
      return CrisisOverlay(
        message: predictResult.crisisMessage ?? '',
        resources: predictResult.crisisResources ?? [],
        action: predictResult.crisisAction ?? '',
        onDismiss: () => Navigator.of(context).pop(),
      );
    }

    final distortions = predictResult.distortions ?? [];
    final triggered = distortions.where((d) => d.triggered).toList();
    final notTriggered = distortions.where((d) => !d.triggered).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        triggered.isEmpty
                            ? 'No distortions detected! 🎉'
                            : '${triggered.length} pattern${triggered.length != 1 ? 's' : ''} detected',
                        style: theme.textTheme.headlineMedium,
                      ).animate().fadeIn(
                        duration: const Duration(milliseconds: 400),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        triggered.isEmpty
                            ? 'Your thinking looks balanced. Great job!'
                            : 'Tap a card to learn more about each pattern.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ).animate().fadeIn(
                        delay: const Duration(milliseconds: 200),
                        duration: const Duration(milliseconds: 400),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: ExpansionTile(
                      leading: Icon(
                        Icons.edit_note_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        'Your Journal Entry',
                        style: theme.textTheme.titleSmall,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            journalText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 400),
                ),

                const SizedBox(height: 8),

                if (triggered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                    child: Text(
                      'DETECTED PATTERNS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...triggered.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DistortionCard(
                        distortion: entry.value,
                        index: entry.key,
                      ),
                    ),
                  ),
                ],

                if (notTriggered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                    child: Text(
                      'NOT DETECTED',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                  ...notTriggered.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Opacity(
                        opacity: 0.5,
                        child: DistortionCard(
                          distortion: entry.value,
                          index: entry.key + triggered.length,
                          accentColor: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: triggered.isNotEmpty
          ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReframeScreen(
                          journalText: journalText,
                          triggeredDistortions: triggered,
                        ),
                      ),
                    );
                  },
                  icon: const Text('✨', style: TextStyle(fontSize: 18)),
                  label: const Text('Get Reframe'),
                )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 800),
                  duration: const Duration(milliseconds: 400),
                )
                .slideY(begin: 0.5, end: 0)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
