import 'dart:math';
import 'package:flutter/material.dart';
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
    if (points >= 1000) return const Color(0xFF00838F); // Deep Cyan
    if (points >= 600) return const Color(0xFF37474F); // Deep Slate
    if (points >= 300) return const Color(0xFFB78103); // Deep Rich Gold
    if (points >= 100) return const Color(0xFF546E7A); // Deep Silver Slate
    return const Color(0xFF5D4037); // Deep Bronze
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
                      leagueColor,
                      leagueColor.withValues(alpha: 0.85),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), 
                        Text(
                          leagueName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16),
                          label: const Text('Ranks', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => _showRankLadder(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatBox(label: 'Rank', value: '#$userRank'),
                        _StatBox(label: 'Points', value: '${profile.totalPoints}'),
                      ],
                    ),
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
                      elevation: isMe ? 3 : 1,
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
                                  color: index < 3 ? leagueColor : theme.colorScheme.onSurface,
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
                            color: isMe ? theme.colorScheme.onPrimaryContainer : null,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isMe
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${user.points} XP',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
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
void _showRankLadder(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rank Ladder', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const _RankItem(icon: '💎', title: 'Diamond League', points: '1000+ XP', color: Colors.cyan),
            const _RankItem(icon: '🏆', title: 'Platinum League', points: '600+ XP', color: Colors.blueGrey),
            const _RankItem(icon: '🥇', title: 'Gold League', points: '300+ XP', color: Colors.amber),
            const _RankItem(icon: '🥈', title: 'Silver League', points: '100+ XP', color: Colors.grey),
            const _RankItem(icon: '🥉', title: 'Bronze League', points: '0+ XP', color: Colors.brown),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
class _RankItem extends StatelessWidget {
  final String icon;
  final String title;
  final String points;
  final Color color;
  const _RankItem({required this.icon, required this.title, required this.points, required this.color});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Text(icon, style: const TextStyle(fontSize: 24)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: Text(points, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
    );
  }
}
