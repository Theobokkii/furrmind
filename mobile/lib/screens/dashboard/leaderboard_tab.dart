import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gamification_service.dart';
class MockUser {
  final String name;
  final String emoji;
  final int points;
  MockUser(this.name, this.emoji, this.points);
}
final leaderboardProvider = Provider.family<List<MockUser>, int>((ref, userPoints) {
  final random = Random(42); 
  final avatars = ['🦊', '🐱', '🐶', '🐼', '🐨', '🐯', '🦁', '🐻', '🐰', '🐹'];
  final names = ['Alex', 'Jordan', 'Taylor', 'Casey', 'Sam', 'Riley', 'Jamie', 'Morgan', 'Quinn', 'Drew'];
  final mockUsers = <MockUser>[];
  for (int i = 0; i < 20; i++) {
    int points = max(0, userPoints + random.nextInt(200) - 100);
    mockUsers.add(MockUser(
      '${names[random.nextInt(names.length)]}${random.nextInt(99)}',
      avatars[random.nextInt(avatars.length)],
      points,
    ));
  }
  mockUsers.sort((a, b) => b.points.compareTo(a.points));
  return mockUsers;
});
class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key});
  String _getLeagueName(int points) {
    if (points >= 1000) return 'Diamond League 💎';
    if (points >= 600) return 'Platinum League 🏆';
    if (points >= 300) return 'Gold League 🥇';
    if (points >= 100) return 'Silver League 🥈';
    return 'Bronze League 🥉';
  }
  Color _getLeagueColor(int points) {
    if (points >= 1000) return Colors.cyan;
    if (points >= 600) return Colors.blueGrey;
    if (points >= 300) return Colors.amber;
    if (points >= 100) return Colors.grey.shade400;
    return Colors.brown.shade400;
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    return SafeArea(
      child: profileAsync.when(
        data: (profile) {
          final leagueName = _getLeagueName(profile.totalPoints);
          final leagueColor = _getLeagueColor(profile.totalPoints);
          final mockUsers = ref.read(leaderboardProvider(profile.totalPoints));
          final allUsers = [
            ...mockUsers,
            MockUser(profile.username, profile.avatarEmoji, profile.totalPoints)
          ];
          allUsers.sort((a, b) => b.points.compareTo(a.points));
          final userRank = allUsers.indexWhere((u) => u.name == profile.username) + 1;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      leagueColor.withValues(alpha: 0.8),
                      leagueColor.withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      leagueName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(label: 'Rank', value: '#$userRank'),
                        _StatBox(label: 'Points', value: '${profile.totalPoints}'),
                      ],
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final user = allUsers[index];
                    final isMe = user.name == profile.username;
                    return Card(
                      color: isMe ? theme.colorScheme.primaryContainer : null,
                      elevation: isMe ? 4 : 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: index < 3 ? leagueColor : null,
                                ),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              child: Text(user.emoji),
                            ),
                          ],
                        ),
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '${user.points} XP',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 100 + (index * 50))).slideX(begin: 0.1, end: 0);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error loading leaderboard')),
      ),
    );
  }
}
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
