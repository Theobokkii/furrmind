import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/gamification_service.dart';
import '../../core/utils/image_helper.dart';
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
        // Get mock details for the friend if they exist in discover list
        final mockDiscoverList = [
          {'name': 'Jordan_99', 'avatar': 'https://picsum.photos/seed/jordan/150', 'level': 5},
          {'name': 'AlexTheGreat', 'avatar': 'https://picsum.photos/seed/alex/150', 'level': 8},
          {'name': 'TaylorSwift123', 'avatar': '👩🏼', 'level': 12},
          {'name': 'Casey_Jones', 'avatar': 'https://picsum.photos/seed/casey/150', 'level': 3},
          {'name': 'SammyBoy', 'avatar': '🐶', 'level': 2},
          {'name': 'Riley_R', 'avatar': 'https://picsum.photos/seed/riley/150', 'level': 6},
        ];
        
        final mockDetails = mockDiscoverList.firstWhere(
          (u) => u['name'] == friendName, 
          orElse: () => {'name': friendName, 'avatar': '🐾', 'level': 1}
        );
        
        final avatar = mockDetails['avatar'] as String;
        final level = mockDetails['level'] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: getAvatarImageProvider(avatar),
              child: buildAvatar(avatar, fontSize: 20),
            ),
            title: Text(friendName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Level $level • Online'),
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
  final List<Map<String, dynamic>> _mockDiscover = [
    {'name': 'Jordan_99', 'pronouns': 'he/him', 'level': 5, 'avatar': 'https://picsum.photos/seed/jordan/150'},
    {'name': 'AlexTheGreat', 'pronouns': 'they/them', 'level': 8, 'avatar': 'https://picsum.photos/seed/alex/150'},
    {'name': 'TaylorSwift123', 'pronouns': 'she/her', 'level': 12, 'avatar': '👩🏼'},
    {'name': 'Casey_Jones', 'pronouns': 'he/they', 'level': 3, 'avatar': 'https://picsum.photos/seed/casey/150'},
    {'name': 'SammyBoy', 'pronouns': 'he/him', 'level': 2, 'avatar': '🐶'},
    {'name': 'Riley_R', 'pronouns': 'she/they', 'level': 6, 'avatar': 'https://picsum.photos/seed/riley/150'},
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      data: (profile) {
        final toDiscover = _mockDiscover.where((user) => !profile.friendIds.contains(user['name'])).toList();
        if (toDiscover.isEmpty) {
          return const Center(child: Text('No more people to discover right now.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: toDiscover.length,
          itemBuilder: (context, index) {
            final user = toDiscover[index];
            final name = user['name'] as String;
            final pronouns = user['pronouns'] as String;
            final level = user['level'] as int;
            final avatar = user['avatar'] as String;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  backgroundImage: getAvatarImageProvider(avatar),
                  child: buildAvatar(avatar, fontSize: 20),
                ),
                title: Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pronouns,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text('Level $level • Suggested Friend'),
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
