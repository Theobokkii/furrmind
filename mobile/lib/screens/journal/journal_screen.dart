import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first 🐾')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.predict(text);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(journalText: text, predictResult: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not connect to server. Check your settings.\n$e',
          ),
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                        children: [
                          Text('🐾', style: GoogleFonts.outfit(fontSize: 28)),
                          const SizedBox(width: 8),
                          Text('Furrmind', style: theme.textTheme.displaySmall),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 600))
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    'Your safe space to reflect and grow',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ).animate().fadeIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 600),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child:
                    Card(
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
                    ).animate().fadeIn(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 600),
                    ),
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
                      )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 600),
                        duration: const Duration(milliseconds: 400),
                      )
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
