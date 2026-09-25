import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/models/journal_entry.dart';
import '../../core/models/mood_entry.dart';
import '../../core/services/journal_storage.dart';
import '../../core/utils/mood_utils.dart';
import '../../core/services/gamification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_helper.dart';
import '../chat/cato_chat_screen.dart';
import 'social_tab.dart';
import 'leaderboard_tab.dart';
final dashboardTabProvider = StateProvider<int>((ref) => 0);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(dashboardTabProvider);
    final pages = [
      const _HomeTab(),
      const CatoChatScreen(),
      const SocialTab(),
      const LeaderboardTab(),
      const _MoodTab(),
      const _ProfileTab(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(dashboardTabProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Cato',
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
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'write_fab',
              onPressed: () => context.push('/journal'),
              icon: const Text('✍️', style: TextStyle(fontSize: 18)),
              label: const Text('Write'),
            )
          : null,
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
    
    int todayScore = 3;
    final currentMood = todayMoodAsync.valueOrNull;
    final hasMood = currentMood != null && currentMood.id != 'mock';
    if (hasMood) {
      todayScore = currentMood.moodScore;
    } else {
      // Mock score for demo
      todayScore = 5;
    }
    
    final hasJournaled = entriesAsync.maybeWhen(
      data: (entries) {
        final now = DateTime.now();
        return entries.any((e) => 
            e.createdAt.year == now.year && 
            e.createdAt.month == now.month && 
            e.createdAt.day == now.day);
      },
      orElse: () => false,
    );

    return Stack(
      children: [
        // Full Page Weather Background with immersive gradients
        Positioned.fill(
          child: _WeatherAnimationBackground(score: todayScore),
        ),
        if (theme.brightness == Brightness.dark)
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
          ),
        // Content
        SafeArea(
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
                  if (mood == null) {
                    // Show CheckIn prompt, but also show a mock MoodCard for demonstration!
                    return Column(
                      children: [
                        _DailyMoodCheckIn(),
                        _TodayMoodCard(mood: MoodEntry(id: 'mock', moodScore: 5, createdAt: DateTime.now())),
                      ],
                    );
                  }
                  return _TodayMoodCard(mood: mood);
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
              child: _DailyTasksCard(
                hasJournaled: hasJournaled,
                hasMood: hasMood,
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
            const SliverToBoxAdapter(
              child: _TrendSummaryCard(),
            ),
            const SliverToBoxAdapter(
              child: _TodayEmotionAnalysisCard(),
            ),
            const SliverToBoxAdapter(
              child: _MeowFactCard(),
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
    ),
      ],
    );
  }
}
class _DailyMoodCheckIn extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DailyMoodCheckIn> createState() => _DailyMoodCheckInState();
}
class _DailyMoodCheckInState extends ConsumerState<_DailyMoodCheckIn> {
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
                'How are you feeling?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a moment to check in with yourself.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/mood-checkin'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.tertiary,
                  ),
                  child: const Text('Check In'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _TodayMoodCard extends StatelessWidget {
  final dynamic mood;
  const _TodayMoodCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    int score = 3;
    try { 
      score = mood.moodScore; 
    } catch (e) {
      // Ignore fallback
    }

    String emoji = MoodUtils.moodEmoji(score);
    Color color = MoodUtils.moodColor(score);
    String label = _getMoodLabel(score);
    Color textColor = Color.lerp(color, theme.brightness == Brightness.dark ? Colors.white : Colors.black, 0.5) ?? color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.3),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Stack(
            children: [
              // Glassmorphism Blur
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/mood-checkin'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Emotion\nfor today:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  color: theme.brightness == Brightness.dark ? Colors.white : textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: Text(emoji, style: const TextStyle(fontSize: 72)),
                              ),
                            ],
                          ),
                        ),
                        // Right Side
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.brightness == Brightness.dark ? Colors.white : textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Info lines
                              Text(
                                _getWeatherText(score),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.brightness == Brightness.dark 
                                      ? Colors.white.withValues(alpha: 0.9) 
                                      : textColor.withValues(alpha: 0.9),
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.brightness == Brightness.dark 
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Score: $score/5 • Inten: ${_getIntensityLabel(score)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  String _getIntensityLabel(int score) {
    if (score == 1 || score == 5) return 'High';
    if (score == 2 || score == 4) return 'Medium';
    return 'Low';
  }

  String _getMoodLabel(int score) {
    switch (score) {
      case 1: return 'Tough & Heavy';
      case 2: return 'A Bit Down';
      case 3: return 'Okay / Neutral';
      case 4: return 'Pretty Good';
      case 5: return 'Fantastic!';
      default: return 'Okay';
    }
  }

  String _getWeatherText(int score) {
    switch (score) {
      case 1: return 'You must have been tired, lately? (っ- ‸ - ς)';
      case 2: return 'It\'s a gloomy day, but I\'m here for you! ( ◡ ‿ ◡ )';
      case 3: return 'Just a normal day, rolling along~ ( ˘ ▽ ˘ )';
      case 4: return 'Let the shine appear in your heart, meow! (≧◡≦)';
      case 5: return 'Purr-fect! You are glowing today! (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧';
      default: return 'Take it one step at a time, meow~ (=^･ω･^=)';
    }
  }
}

class _WeatherAnimationBackground extends StatelessWidget {
  final int score;
  const _WeatherAnimationBackground({required this.score});

  @override
  Widget build(BuildContext context) {
    // Determine the atmospheric gradient based on the weather/mood score
    List<Color> gradientColors;
    if (score == 1) {
      gradientColors = [const Color(0xFF2C3E50), const Color(0xFF34495E), const Color(0xFF5D6D7E)]; // Stormy Dark
    } else if (score == 2) {
      gradientColors = [const Color(0xFF7F8C8D), const Color(0xFF95A5A6), const Color(0xFFBDC3C7)]; // Gloomy Grey
    } else if (score == 3) {
      gradientColors = [const Color(0xFF85C1E9), const Color(0xFFD6EAF8), const Color(0xFFFDFEFE)]; // Soft Sky Blue
    } else if (score == 4) {
      gradientColors = [const Color(0xFF3498DB), const Color(0xFF85C1E9), const Color(0xFFFAD7A1)]; // Bright Day
    } else {
      gradientColors = [const Color(0xFFF39C12), const Color(0xFFF1C40F), const Color(0xFFFAD7A1)]; // Vibrant Sunset/Golden Hour
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: _buildWeatherParticles(score, constraints),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildWeatherParticles(int score, BoxConstraints constraints) {
    if (score == 1) {
      // Heavy Rain + Sliding Drops on Glass
      final random = Random(42);
      return List.generate(40, (index) {
        final startX = random.nextDouble() * constraints.maxWidth;
        final isSliding = index % 3 == 0; // Some drops stick and slide slowly
        final size = isSliding ? (16.0 + random.nextDouble() * 12.0) : (10.0 + random.nextDouble() * 8.0);
        final duration = isSliding ? (4000 + random.nextInt(3000)) : (400 + random.nextInt(400));
        final delayMs = random.nextInt(4000);
        
        // Use a slide ratio to move exactly from top to bottom
        final slideRatio = constraints.maxHeight / size + 2;

        return Positioned(
          left: startX,
          top: -40, // start above the screen
          child: Icon(Icons.water_drop, color: Colors.blue.shade200.withValues(alpha: isSliding ? 0.5 : 0.3), size: size)
              .animate(onPlay: (controller) => controller.repeat(), delay: delayMs.ms)
              .slideY(begin: 0, end: slideRatio, duration: duration.ms, curve: isSliding ? Curves.easeInOutSine : Curves.linear)
              .fadeIn(duration: 200.ms)
              .fadeOut(delay: (duration * 0.8).toInt().ms),
        );
      });
    } else if (score == 2) {
      // Cloudy / Overcast
      return [
        Positioned(
          right: -50,
          top: -20,
          child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.3), size: 180)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideX(begin: 0, end: -0.15, duration: 6.seconds),
        ),
        Positioned(
          left: -60,
          top: 60,
          child: Icon(Icons.cloud, color: Colors.grey.shade400.withValues(alpha: 0.3), size: 140)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideX(begin: 0, end: 0.1, duration: 8.seconds),
        ),
        Positioned(
          right: 20,
          top: 150,
          child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.2), size: 100)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideX(begin: 0, end: -0.2, duration: 10.seconds),
        ),
      ];
    } else if (score == 4) {
      // Sunny
      return [
        Positioned(
          right: -40,
          top: -40,
          child: Icon(Icons.wb_sunny, color: Colors.yellow.shade100.withValues(alpha: 0.5), size: 220)
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 30.seconds),
        ),
        Positioned(
          left: -20,
          top: 40,
          child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.6), size: 120)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideX(begin: 0, end: 0.1, duration: 12.seconds),
        ),
      ];
    } else if (score == 5) {
      // Glowing / Golden Hour / Sparkles
      return [
        Positioned(
          right: -60,
          top: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.4),
                  blurRadius: 60,
                  spreadRadius: 40,
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 0.9, end: 1.1, duration: 3.seconds),
        ),
        ...List.generate(6, (index) {
          return Positioned(
            left: 30.0 + (index * 50),
            top: 40.0 + (index % 3 * 60),
            child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.6), size: 24)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 0.5, end: 1.5, duration: (800 + (index * 300)).ms)
                .fadeIn(duration: 400.ms),
          );
        }),
      ];
    } else {
      // Normal (Score 3) - Few gentle clouds
      return [
        Positioned(
          left: -40,
          top: 30,
          child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.7), size: 150)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideX(begin: 0, end: 0.15, duration: 9.seconds),
        ),
        Positioned(
          right: -30,
          top: 120,
          child: Icon(Icons.cloud, color: Colors.white.withValues(alpha: 0.5), size: 100)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideX(begin: 0, end: -0.1, duration: 14.seconds),
        ),
      ];
    }
  }
}

class _TodayEmotionAnalysisCard extends StatefulWidget {
  const _TodayEmotionAnalysisCard();
  @override
  State<_TodayEmotionAnalysisCard> createState() => _TodayEmotionAnalysisCardState();
}

class _TodayEmotionAnalysisCardState extends State<_TodayEmotionAnalysisCard> {
  String _chartType = 'Bar Chart';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Mock data for today's emotions (adaptive to chatbot/mood analyzer)
    final emotionData = [
      {'label': 'Joy', 'value': 40.0, 'color': Colors.amber},
      {'label': 'Calm', 'value': 30.0, 'color': Colors.blue[300]!},
      {'label': 'Anx.', 'value': 15.0, 'color': Colors.purple[300]!},
      {'label': 'Sad', 'value': 15.0, 'color': Colors.blueGrey},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emotion Intensity',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _chartType,
                    underline: const SizedBox(),
                    items: ['Bar Chart', 'Pie Chart'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _chartType = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: _chartType == 'Pie Chart' 
                  ? _buildPieChart(emotionData, theme) 
                  : _buildBarChart(emotionData, theme),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: data.map((e) {
                return PieChartSectionData(
                  color: e['color'] as Color,
                  value: e['value'] as double,
                  title: '${(e['value'] as double).toInt()}%',
                  radius: 45,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12, 
                      height: 12, 
                      decoration: BoxDecoration(color: e['color'] as Color, shape: BoxShape.circle)
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e['label'] as String, 
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, ThemeData theme) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 50,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[value.toInt()]['label'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == 25 || value == 50) {
                  return Text(
                    '${value.toInt()}%', 
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor, fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.5), 
            strokeWidth: 1, 
            dashArray: [4, 4]
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: item['value'] as double,
                color: item['color'] as Color,
                width: 28,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 50,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                )
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}


class _TrendSummaryCard extends ConsumerWidget {
  const _TrendSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            ref.read(dashboardTabProvider.notifier).state = 4;
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.auto_graph_rounded, color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Weekly Trend',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ve felt mostly Positive this week. Keep up the good momentum!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _MeowFactCard extends StatefulWidget {
  const _MeowFactCard();

  @override
  State<_MeowFactCard> createState() => _MeowFactCardState();
}

class _MeowFactCardState extends State<_MeowFactCard> {
  late Timer _timer;
  int _factIndex = 0;

  final List<String> _facts = [
    "Did you know? Naming your emotions (affect labeling) can reduce the intensity of sadness and anger in the brain. Meow! 🐾",
    "Purr-spective matters! CBT helps us reframe 'I always fail' to 'I struggled this time, but I can learn'. 😸",
    "Feeling anxious? Taking deep, slow breaths signals your nervous system to chill out. Like a sleeping cat! 🐈💤",
    "Emotions are like passing clouds. They come and go. Don't let them dictate your entire day! 🌦️🐈",
    "Cognitive distortions are just your brain's fur-balls! Cough them out by challenging negative thoughts. 🧶",
    "Action precedes motivation! Sometimes you just have to start playing with the yarn before you feel like it. 🐾",
  ];

  @override
  void initState() {
    super.initState();
    // Change fact every 20 seconds so user can read comfortably
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        setState(() {
          _factIndex = (_factIndex + 1) % _facts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: theme.colorScheme.tertiary.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'MeowFact!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: 500.ms,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _facts[_factIndex],
                  key: ValueKey<int>(_factIndex),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
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
  Widget _buildWeeklyTracker() {
    final now = DateTime.now();
    // Find the Monday of the current week (weekday 1 = Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = monday.add(Duration(days: index));
        final hasEntry = entries.any((e) => 
            e.createdAt.year == day.year && 
            e.createdAt.month == day.month && 
            e.createdAt.day == day.day);
        
        final isFuture = day.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
        final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
        
        return Column(
          children: [
            Text(
              days[index],
              style: GoogleFonts.inter(
                color: isToday ? Colors.white : Colors.white54,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.local_fire_department_rounded,
              color: hasEntry 
                  ? Colors.orangeAccent 
                  : (isFuture ? Colors.white12 : Colors.white24),
              size: 28,
            ),
          ],
        );
      }),
    );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orangeAccent,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  '$streak',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Day Streak',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildWeeklyTracker(),
            const SizedBox(height: 24),
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

class _DailyTasksCard extends StatelessWidget {
  final bool hasJournaled;
  final bool hasMood;

  const _DailyTasksCard({
    required this.hasJournaled,
    required this.hasMood,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Quests',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _TaskRow(
              title: '1x Journaling',
              isCompleted: hasJournaled,
              icon: Icons.edit_note_rounded,
            ),
            const SizedBox(height: 12),
            _TaskRow(
              title: '1x Mood Analysis',
              isCompleted: hasMood,
              icon: Icons.insights_rounded,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final IconData icon;

  const _TaskRow({
    required this.title,
    required this.isCompleted,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCompleted 
                ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ),
        if (isCompleted)
          Icon(
            Icons.check_circle_rounded,
            color: theme.colorScheme.primary,
          )
        else
          Icon(
            Icons.radio_button_unchecked_rounded,
            color: theme.colorScheme.outline,
          ),
      ],
    );
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
        color: theme.colorScheme.primary, // Solid high-contrast background
        borderRadius: BorderRadius.circular(16),
        elevation: 2, // Add slight shadow to make it pop
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
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
class _MoodTab extends ConsumerStatefulWidget {
  const _MoodTab();

  @override
  ConsumerState<_MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends ConsumerState<_MoodTab> {
  String _timeRange = 'This Week';
  String _chartType = 'bar';
  int _offset = 0; // 0 = current, < 0 = past

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! < -300) {
      if (_offset < 0) setState(() => _offset++);
    } else if (details.primaryVelocity! > 300) {
      setState(() => _offset--);
    }
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    if (_timeRange == 'This Day') {
      final target = now.add(Duration(days: _offset));
      return DateFormat('MMM d, yyyy').format(target);
    } else if (_timeRange == 'This Week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final targetMonday = monday.add(Duration(days: _offset * 7));
      final targetSunday = targetMonday.add(const Duration(days: 6));
      return '${DateFormat('MMM d').format(targetMonday)} - ${DateFormat('MMM d').format(targetSunday)}';
    } else {
      final target = DateTime(now.year, now.month + _offset, 1);
      return DateFormat('MMMM yyyy').format(target);
    }
  }

  List<MoodEntry> _getMockData(List<MoodEntry> realMoods) {
    final now = DateTime.now();
    final List<MoodEntry> generated = [];

    if (_timeRange == 'This Day') {
      final targetDay = now.add(Duration(days: _offset));
      for (int i = 0; i < 24; i++) {
        final hasReal = realMoods.where((m) => m.createdAt.year == targetDay.year && m.createdAt.month == targetDay.month && m.createdAt.day == targetDay.day && m.createdAt.hour == i);
        if (hasReal.isNotEmpty) {
          generated.add(hasReal.first);
        } else if (_offset < 0 || (targetDay.day != now.day || i <= now.hour)) {
          // Add some fake data for past hours
          if (i > 6 && i % 4 != 0) { // random gaps
             final val = ((i * 7) % 5) + 1;
             generated.add(MoodEntry(id: 'm_$i', moodScore: val, createdAt: DateTime(targetDay.year, targetDay.month, targetDay.day, i)));
          } else {
             generated.add(MoodEntry(id: 'gap', moodScore: 0, createdAt: DateTime(targetDay.year, targetDay.month, targetDay.day, i)));
          }
        } else {
          generated.add(MoodEntry(id: 'gap', moodScore: 0, createdAt: DateTime(targetDay.year, targetDay.month, targetDay.day, i)));
        }
      }
    } else if (_timeRange == 'This Week') {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final targetMonday = monday.add(Duration(days: _offset * 7));
      for (int i = 0; i < 7; i++) {
        final day = targetMonday.add(Duration(days: i));
        final dayMoods = realMoods.where((m) => m.createdAt.year == day.year && m.createdAt.month == day.month && m.createdAt.day == day.day);
        if (dayMoods.isNotEmpty) {
          generated.add(dayMoods.last);
        } else if (_offset < 0 || day.isBefore(now) || day.isAtSameMomentAs(now)) {
          final val = ((i * 3) % 4) + 2;
          generated.add(MoodEntry(id: 'm_$i', moodScore: val, createdAt: day));
        } else {
          generated.add(MoodEntry(id: 'gap', moodScore: 0, createdAt: day));
        }
      }
    } else {
      final targetDate = DateTime(now.year, now.month + _offset, 1);
      final daysInMonth = DateTime(targetDate.year, targetDate.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final day = DateTime(targetDate.year, targetDate.month, i);
        final dayMoods = realMoods.where((m) => m.createdAt.year == day.year && m.createdAt.month == day.month && m.createdAt.day == day.day);
        if (dayMoods.isNotEmpty) {
          generated.add(dayMoods.last);
        } else if (_offset < 0 || day.isBefore(now) || day.isAtSameMomentAs(now)) {
          final val = ((i * 2) % 4) + 1;
          generated.add(MoodEntry(id: 'm_$i', moodScore: val, createdAt: day));
        } else {
          generated.add(MoodEntry(id: 'gap', moodScore: 0, createdAt: day));
        }
      }
    }
    return generated;
  }

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _timeRange,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: ['This Day', 'This Week', 'This Month'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _timeRange = newValue;
                                _offset = 0;
                              });
                            }
                          },
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => setState(() => _offset--),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: _offset < 0 ? () => setState(() => _offset++) : null,
                            color: _offset < 0 ? null : Colors.grey,
                          ),
                          IconButton(
                            icon: Icon(_chartType == 'bar' ? Icons.show_chart_rounded : Icons.bar_chart_rounded),
                            tooltip: 'Toggle Chart Type',
                            onPressed: () {
                              setState(() => _chartType = _chartType == 'bar' ? 'line' : 'bar');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _getDateRangeText(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onHorizontalDragEnd: _onSwipe,
                    child: SizedBox(
                      height: 200,
                      child: weeklyMoodsAsync.when(
                        data: (realMoods) {
                          final displayMoods = _getMockData(realMoods);
                          final validSpots = displayMoods.where((m) => m.moodScore > 0).toList();
                          
                          if (_chartType == 'line') {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 10),
                              child: LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final intIndex = value.toInt();
                                          if (intIndex >= 0 && intIndex < displayMoods.length) {
                                            String label = '';
                                            if (_timeRange == 'This Day') {
                                              if (intIndex % 6 == 0) {
                                                label = intIndex == 0 ? '12am' : '${intIndex > 12 ? intIndex - 12 : intIndex}${intIndex >= 12 ? 'pm' : 'am'}';
                                              }
                                            } else if (_timeRange == 'This Week') {
                                              label = DateFormat('E').format(displayMoods[intIndex].createdAt);
                                            } else {
                                              if (intIndex % 5 == 0) {
                                                label = '${intIndex + 1}';
                                              }
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(label, style: theme.textTheme.labelSmall),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: validSpots.map((m) {
                                        return FlSpot(displayMoods.indexOf(m).toDouble(), m.moodScore.toDouble());
                                      }).toList(),
                                      isCurved: true,
                                      color: theme.colorScheme.primary,
                                      barWidth: 4,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(show: _timeRange != 'This Month'),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ],
                                  minY: 0,
                                  maxY: 6,
                                  minX: 0,
                                  maxX: (displayMoods.length - 1).toDouble(),
                                ),
                              ),
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: displayMoods.map((m) {
                                      final mood = m.moodScore;
                                      
                                      String day = '';
                                      final idx = displayMoods.indexOf(m);
                                      if (_timeRange == 'This Day') {
                                        if (idx % 6 == 0) {
                                          day = idx == 0 ? '12am' : '${idx > 12 ? idx - 12 : idx}${idx >= 12 ? 'pm' : 'am'}';
                                        }
                                      } else if (_timeRange == 'This Week') {
                                        day = DateFormat('E').format(m.createdAt);
                                      } else {
                                        if (idx % 5 == 0) {
                                          day = '${idx + 1}';
                                        }
                                      }
                                      
                                      final barHeight = mood > 0 ? (mood / 5.0) * 120 : 0.0;
                                      return Padding(
                                        padding: EdgeInsets.symmetric(horizontal: _timeRange == 'This Month' ? 4.0 : 8.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (_timeRange != 'This Month' && mood > 0)
                                              Text(
                                                MoodUtils.moodEmoji(mood),
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                            const SizedBox(height: 6),
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 500),
                                              width: _timeRange == 'This Month' ? 8 : 24,
                                              height: barHeight,
                                              decoration: BoxDecoration(
                                                color: mood > 0 ? MoodUtils.moodColor(mood) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (day.isNotEmpty)
                                              Text(
                                                day,
                                                style: theme.textTheme.labelSmall,
                                              )
                                            else
                                              const SizedBox(height: 14), // placeholder for label height
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, _) => const SizedBox(),
                      ),
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
