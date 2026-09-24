import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/gamification_service.dart';
import 'chat_tab.dart'; 
import 'package:go_router/go_router.dart';
class SocialTab extends ConsumerWidget {
  const SocialTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: '🤖 AI Companion'),
                  Tab(text: '👥 My Friends'),
                  Tab(text: '🔍 Discover'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const ChatTab(),
                  profileAsync.when(
                    data: (profile) => _FriendsList(friendIds: profile.friendIds),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Center(child: Text('Error loading friends')),
                  ),
                  _DiscoverList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _FriendsList extends StatelessWidget {
  final List<String> friendIds;
  const _FriendsList({required this.friendIds});
  @override
  Widget build(BuildContext context) {
    if (friendIds.isEmpty) {
      return const Center(
        child: Text('You have no friends yet. Go to Discover to find some!'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friendIds.length,
      itemBuilder: (context, index) {
        final friendName = friendIds[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Text('🐾'),
            ),
            title: Text(friendName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Online'),
            trailing: IconButton(
              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent),
              onPressed: () {
                context.push('/friend-chat', extra: friendName);
              },
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
      },
    );
  }
}
class _DiscoverList extends ConsumerWidget {
  final List<String> _mockDiscover = [
    'Jordan_99', 'AlexTheGreat', 'TaylorSwift123', 'Casey_Jones', 'SammyBoy', 'Riley_R'
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      data: (profile) {
        final toDiscover = _mockDiscover.where((name) => !profile.friendIds.contains(name)).toList();
        if (toDiscover.isEmpty) {
          return const Center(child: Text('No more people to discover right now.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: toDiscover.length,
          itemBuilder: (context, index) {
            final name = toDiscover[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(name[0].toUpperCase()),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Suggested Friend'),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () async {
                    final gamification = ref.read(gamificationProvider);
                    final newFriends = List<String>.from(profile.friendIds)..add(name);
                    await gamification.updateProfile(friendIds: newFriends);
                    ref.invalidate(userProfileProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added $name to your friends!')),
                      );
                    }
                  },
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error')),
    );
  }
}
