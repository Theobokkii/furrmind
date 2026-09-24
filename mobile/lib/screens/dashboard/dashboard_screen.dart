import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/journal_entry.dart';
import '../../core/services/journal_storage.dart';
import '../../core/services/mock_data_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_helper.dart';
import 'social_tab.dart';
import 'leaderboard_tab.dart';
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const SocialTab(),
      const LeaderboardTab(),
      const _MoodTab(),
      const _ProfileTab(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Ranks',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Mood',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'write_fab',
        onPressed: () => context.push('/journal'),
        icon: const Text('✍️', style: TextStyle(fontSize: 18)),
        label: const Text('Write'),
      ),
    );
  }
}
class _HomeTab extends ConsumerWidget {
  const _HomeTab();
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(journalEntriesProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final todayMoodAsync = ref.watch(todayMoodProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(journalEntriesProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(todayMoodProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            data: (profile) => Text(
                              '${_greeting()}, ${profile.username}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            loading: () => const SizedBox(height: 16),
                            error: (_, _) => const SizedBox(height: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '🐾 FurrMind',
                            style: theme.textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            ),
            SliverToBoxAdapter(
              child: todayMoodAsync.when(
                data: (mood) {
                  if (mood != null) return const SizedBox.shrink();
                  return _DailyMoodCheckIn();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: entriesAsync.when(
                data: (entries) => _StreakCard(entries: entries),
                loading: () => const SizedBox(height: 140),
                error: (_, _) => const SizedBox(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    _QuickActionChip(
                      icon: Icons.edit_note_rounded,
                      label: 'New Entry',
                      onTap: () => context.push('/journal'),
                    ),
                    const SizedBox(width: 12),
                    _QuickActionChip(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => context.push('/history'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Entries',
                      style: theme.textTheme.headlineSmall,
                    ),
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📝', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'No journal entries yet',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "Write" to create your first entry and start understanding your thought patterns.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final recentEntries = entries.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = recentEntries[index];
                        return _JournalEntryCard(entry: entry, index: index);
                      },
                      childCount: recentEntries.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _DailyMoodCheckIn extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DailyMoodCheckIn> createState() => _DailyMoodCheckInState();
}
class _DailyMoodCheckInState extends ConsumerState<_DailyMoodCheckIn> {
  int? _selectedMood;
  bool _isSaving = false;
  final _moods = [
    {'emoji': '😢', 'score': 1},
    {'emoji': '😟', 'score': 2},
    {'emoji': '😐', 'score': 3},
    {'emoji': '😊', 'score': 4},
    {'emoji': '😄', 'score': 5},
  ];
  Future<void> _saveMood() async {
    if (_selectedMood == null) return;
    setState(() => _isSaving = true);
    final gamification = ref.read(gamificationProvider);
    await gamification.logMood(_selectedMood!);
    ref.invalidate(todayMoodProvider);
    ref.invalidate(weeklyMoodsProvider);
    ref.invalidate(userProfileProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mood logged! +5 points 🌟')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Card(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling today?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _moods.map((m) {
                  final isSelected = _selectedMood == m['score'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedMood = m['score'] as int);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.tertiary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        m['emoji'] as String,
                        style: TextStyle(fontSize: isSelected ? 32 : 28),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedMood != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveMood,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                    ),
                    child: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Log Mood'),
                  ),
                ).animate().fadeIn(duration: 200.ms),
              ]
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
class _StreakCard extends StatelessWidget {
  final List<JournalEntry> entries;
  const _StreakCard({required this.entries});
  int _calculateStreak() {
    if (entries.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i <= 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      final hasEntry = entries.any((e) =>
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day);
      if (hasEntry) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = _calculateStreak();
    final totalEntries = entries.length;
    final withDistortions =
        entries.where((e) => e.distortionLabels.isNotEmpty).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Streak',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$streak',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 6),
                            child: Text(
                              streak == 1 ? 'day' : 'days',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.orangeAccent,
                    size: 36,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '$totalEntries',
                    label: 'Entries',
                    icon: Icons.book_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white24,
                  ),
                  _StatItem(
                    value: '$withDistortions',
                    label: 'Analyzed',
                    icon: Icons.psychology_outlined,
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white24,
                  ),
                  _StatItem(
                    value:
                        '${entries.where((e) => e.reframeText != null).length}',
                    label: 'Reframed',
                    icon: Icons.auto_awesome_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }
}
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Material(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final int index;
  const _JournalEntryCard({required this.entry, required this.index});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat('MMM dd · hh:mm a').format(entry.createdAt);
    final hasDistortions = entry.distortionLabels.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/history'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (entry.reframeText != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 4),
                  Text(dateStr, style: theme.textTheme.bodySmall),
                  if (hasDistortions) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.psychology_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.distortionLabels.length} pattern${entry.distortionLabels.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              if (hasDistortions) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.distortionLabels.take(3).map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary.withValues(alpha: 0.15)
                            : AppColors.lightPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map((w) => w.isNotEmpty
                                ? '${w[0].toUpperCase()}${w.substring(1)}'
                                : w)
                            .join(' '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 300 + (index * 80)),
          duration: 400.ms,
        )
        .slideY(begin: 0.05, end: 0);
  }
}
class _MoodTab extends ConsumerWidget {
  const _MoodTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weeklyMoodsAsync = ref.watch(weeklyMoodsProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Mood Insights', style: theme.textTheme.displaySmall)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            'Track how you feel over time',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This Week',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: weeklyMoodsAsync.when(
                      data: (moods) {
                        if (moods.isEmpty) {
                          return const Center(child: Text('No moods logged this week yet.'));
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: moods.map((m) {
                            final mood = m.moodScore;
                            final day = DateFormat('E').format(m.createdAt);
                            final barHeight = (mood / 5.0) * 120;
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  MockDataService.moodEmoji(mood),
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  width: 28,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: MockDataService.moodColor(mood),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  day,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('😊', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Mood',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3.3 / 5.0 — Neutral-Good',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Common Patterns',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _PatternRow(
                    label: 'All-or-Nothing',
                    count: 3,
                    color: AppColors.chipColors[0],
                    progress: 0.8,
                  ),
                  const SizedBox(height: 12),
                  _PatternRow(
                    label: 'Mind Reading',
                    count: 2,
                    color: AppColors.chipColors[1],
                    progress: 0.5,
                  ),
                  const SizedBox(height: 12),
                  _PatternRow(
                    label: 'Should Statements',
                    count: 2,
                    color: AppColors.chipColors[2],
                    progress: 0.5,
                  ),
                  const SizedBox(height: 12),
                  _PatternRow(
                    label: 'Catastrophizing',
                    count: 1,
                    color: AppColors.chipColors[3],
                    progress: 0.25,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
class _PatternRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final double progress;
  const _PatternRow({
    required this.label,
    required this.count,
    required this.color,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          flex: 4,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();
  Color _getBannerColor(String bannerId, ThemeData theme) {
    switch (bannerId) {
      case 'ocean': return const Color(0xFF86A789);
      case 'sunset': return const Color(0xFFD5A760);
      case 'christmas': return const Color(0xFFC97B7B);
      case 'halloween': return const Color(0xFF978FAD);
      case 'neon_glow': return const Color(0xFF7BA1A8);
      default: return theme.colorScheme.primary;
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userProfileProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            image: getBannerImageProvider(profile.bannerUrl) != null 
                                ? DecorationImage(
                                    image: getBannerImageProvider(profile.bannerUrl)!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: getBannerImageProvider(profile.bannerUrl) == null 
                                ? LinearGradient(
                                    colors: [
                                      _getBannerColor(profile.bannerUrl, theme).withValues(alpha: 0.5),
                                      _getBannerColor(profile.bannerUrl, theme).withValues(alpha: 0.2),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.scaffoldBackgroundColor,
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: getAvatarImageProvider(profile.avatarEmoji),
                              child: buildAvatar(profile.avatarEmoji, fontSize: 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 52),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: profile.username,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (profile.pronouns.isNotEmpty)
                            TextSpan(
                              text: ' (${profile.pronouns})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          profile.bio,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BadgeChip(
                          icon: Icons.star_rounded,
                          label: 'Level ${profile.currentLevel}',
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        _BadgeChip(
                          icon: Icons.flash_on_rounded,
                          label: '${profile.totalPoints} XP',
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _BadgeChip(
                          icon: Icons.people_alt_rounded,
                          label: '${profile.friendIds.length} Friends',
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms),
                loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                error: (_, _) => const SizedBox(height: 300),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  profileAsync.when(
                    data: (profile) => profile.unlockedBadges.isNotEmpty ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: profile.unlockedBadges.map((badge) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🏅', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(badge, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ) : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  Text(
                    'Account',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your bio, avatar, and details',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.history_rounded,
                    title: 'Journal History',
                    subtitle: 'Look back at your past entries',
                    onTap: () => context.push('/history'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Preferences',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Theme, API config, notifications',
                    onTap: () => context.push('/settings'),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About FurrMind',
                    subtitle: 'Version 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'FurrMind',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Text('🐾', style: TextStyle(fontSize: 40)),
                        children: [
                          const Text(
                            'An AI-powered CBT journaling companion that helps you detect cognitive distortions and reframe negative thoughts into balanced perspectives.',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _BadgeChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)) : null,
        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}
