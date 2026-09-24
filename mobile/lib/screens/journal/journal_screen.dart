import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/distortion_result.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';
import '../result/result_screen.dart';
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}
class _JournalScreenState extends ConsumerState<JournalScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  bool _isLoading = false;
  int _hintIndex = 0;
  static const _hints = [
    'Write about something on your mind...',
    'How are you feeling right now?',
    'What happened today that bothered you?',
    'Describe a thought that keeps coming back...',
    'What are you worried about?',
  ];
  Timer? _hintTimer;
  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      }
    });
  }
  @override
  void dispose() {
    _hintTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }
  PredictApiResult _mockPredict(String text) {
    final random = Random(text.hashCode);
    final allDistortions = [
      'all_or_nothing',
      'overgeneralization',
      'mental_filter',
      'disqualifying_positive',
      'jumping_to_conclusions',
      'magnification',
      'emotional_reasoning',
      'should_statements',
      'labeling',
      'personalization',
      'catastrophizing',
      'mind_reading',
      'fortune_telling',
    ];
    final shuffled = List<String>.from(allDistortions)..shuffle(random);
    final triggeredCount = 2 + random.nextInt(3);
    final triggered = shuffled.take(triggeredCount).toSet();
    final distortions = allDistortions.map((label) {
      final isTriggered = triggered.contains(label);
      return DistortionResult(
        label: label,
        confidence: isTriggered
            ? 0.65 + random.nextDouble() * 0.3
            : random.nextDouble() * 0.3,
        triggered: isTriggered,
      );
    }).toList();
    distortions.sort((a, b) {
      if (a.triggered && !b.triggered) return -1;
      if (!a.triggered && b.triggered) return 1;
      return b.confidence.compareTo(a.confidence);
    });
    return PredictApiResult.success(distortions);
  }
  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first 🐾')),
      );
      return;
    }
    if (text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a bit more for better analysis 📝'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      PredictApiResult result;
      try {
        final apiService = ref.read(apiServiceProvider);
        result = await apiService
            .predict(text)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        await Future.delayed(
          const Duration(milliseconds: 800),
        ); 
        result = _mockPredict(text);
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            journalText: text,
            predictResult: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: AppColors.crisisRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textLength = _textController.text.length;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐾', style: GoogleFonts.outfit(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('New Entry'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                'Write freely — your thoughts are analyzed for cognitive distortion patterns.',
                style: theme.textTheme.bodySmall,
              ).animate().fadeIn(duration: 400.ms),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _isLoading
                        ? const Center(child: LoadingShimmer(itemCount: 3))
                        : TextField(
                            controller: _textController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (_) => setState(() {}),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                            ),
                            decoration: InputDecoration(
                              hintText: _hints[_hintIndex],
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: textLength > 0 ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '$textLength characters',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _analyze,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            )
                          : const Text(
                              '🐾',
                              style: TextStyle(fontSize: 18),
                            ),
                      label: Text(_isLoading ? 'Analyzing...' : 'Analyze'),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
