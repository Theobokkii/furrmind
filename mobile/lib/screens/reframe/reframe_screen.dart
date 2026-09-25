import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/models/distortion_result.dart';
import '../../core/services/api_service.dart';
import '../../core/services/journal_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_shimmer.dart';
class ReframeScreen extends ConsumerStatefulWidget {
  final String journalText;
  final List<DistortionResult> triggeredDistortions;
  const ReframeScreen({
    super.key,
    required this.journalText,
    required this.triggeredDistortions,
  });
  @override
  ConsumerState<ReframeScreen> createState() => _ReframeScreenState();
}
class _ReframeScreenState extends ConsumerState<ReframeScreen> {
  ReframeResult? _reframeResult;
  bool _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _fetchReframe();
  }
  ReframeResult _mockReframe() {
    final labels =
        widget.triggeredDistortions.map((d) => d.displayName).join(', ');
    return ReframeResult(
      reframe:
          'While it\'s understandable to feel this way, consider that your perspective may be influenced by $labels. Try to look at the evidence objectively — what would you tell a friend in this situation?',
      explanation:
          'CBT teaches us that our feelings are influenced by our interpretations, not just events themselves. By identifying patterns like $labels, you can begin to challenge these automatic thoughts and develop more balanced perspectives.',
      sources: [
        'Cognitive Restructuring',
        'Socratic Questioning',
        'Thought Records',
      ],
    );
  }
  Future<void> _fetchReframe() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      ReframeResult result;
      try {
        final apiService = ref.read(apiServiceProvider);
        final distortionLabels =
            widget.triggeredDistortions.map((d) => d.label).toList();
        result = await apiService
            .reframe(widget.journalText, distortionLabels)
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 1200));
        result = _mockReframe();
      }
      if (mounted) {
        setState(() {
          _reframeResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _saveAndComplete() async {
    final storage = ref.read(journalStorageProvider);
    await storage.saveEntry(
      text: widget.journalText,
      distortions: widget.triggeredDistortions,
      reframe: _reframeResult,
    );
    ref.invalidate(journalEntriesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session saved successfully! ✨')),
      );
      context.go('/dashboard');
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ CBT Reframe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Home',
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: LoadingShimmer(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.sentiment_dissatisfied,
                          size: 64,
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not generate reframe',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchReframe,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightPrimary
                                  .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORIGINAL THOUGHT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.journalText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('🌟',
                                      style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'A Balanced Perspective',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _reframeResult?.reframe ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      if (_reframeResult?.explanation.isNotEmpty ?? false) ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('💡',
                                        style: TextStyle(fontSize: 20)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Why This Helps (CBT)',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _reframeResult!.explanation,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 20),
                      ],
                      if ((_reframeResult?.sources ?? []).isNotEmpty) ...[
                        Text(
                          'CBT Principles Referenced:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _reframeResult!.sources.map((src) {
                            return Chip(
                              label: Text(src),
                              avatar:
                                  const Icon(Icons.bookmark_border, size: 16),
                            );
                          }).toList(),
                        ).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 24),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveAndComplete,
                          icon: const Icon(Icons.done_all),
                          label: const Text('Save & Complete Session'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}
