import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/gamification_service.dart';
import '../../core/utils/image_helper.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_profile.dart';

final friendsListProvider = FutureProvider.family<List<UserProfile>, List<String>>((ref, friendUsernames) {
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getFriendsProfiles(friendUsernames);
});

final discoverUsersProvider = FutureProvider.family<List<UserProfile>, String>((ref, query) async {
  final firestore = ref.watch(firestoreServiceProvider);
  if (query.isEmpty) {
    return firestore.getDiscoverUsers(10); // get 10 random
  } else {
    return firestore.searchUsersByUsername(query);
  }
});

class SocialTab extends ConsumerWidget {
  const SocialTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              height: 46,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: '👥 My Friends'),
                  Tab(text: '🔍 Discover'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
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

class _FriendsList extends ConsumerWidget {
  final List<String> friendIds;
  const _FriendsList({required this.friendIds});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (friendIds.isEmpty) {
      return const Center(
        child: Text('You have no friends yet. Go to Discover to find some!'),
      );
    }
    
    final friendsAsync = ref.watch(friendsListProvider(friendIds));
    
    return friendsAsync.when(
      data: (friends) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => context.push('/friend-profile', extra: friend.username),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: getAvatarImageProvider(friend.avatarEmoji),
                  child: buildAvatar(friend.avatarEmoji, fontSize: 20),
                ),
                title: Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('@${friend.username} • Level ${friend.currentLevel} • Online'),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent),
                  onPressed: () => context.push('/friend-chat', extra: friend.username),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _DiscoverList extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DiscoverList> createState() => _DiscoverListState();
}

class _DiscoverListState extends ConsumerState<_DiscoverList> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final discoverAsync = ref.watch(discoverUsersProvider(_searchQuery));
    
    return profileAsync.when(
      data: (profile) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: discoverAsync.when(
                data: (users) {
                  final toDiscover = users.where((u) => 
                      u.username != profile.username && 
                      !profile.friendIds.contains(u.username)).toList();
                      
                  if (toDiscover.isEmpty) {
                    return Center(child: Text(_searchQuery.isEmpty ? 'No more people to discover right now.' : 'No users found matching "$_searchQuery"'));
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: toDiscover.length,
                    itemBuilder: (context, index) {
                      final user = toDiscover[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => context.push('/friend-profile', extra: user.username),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            backgroundImage: getAvatarImageProvider(user.avatarEmoji),
                            child: buildAvatar(user.avatarEmoji, fontSize: 20),
                          ),
                          title: Row(
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              if (user.pronouns.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.pronouns,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text('@${user.username} • Level ${user.currentLevel}'),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () async {
                              final gamification = ref.read(gamificationProvider);
                              final newFriends = List<String>.from(profile.friendIds)..add(user.username);
                              await gamification.updateProfile(friendIds: newFriends);
                              ref.invalidate(userProfileProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added ${user.username} to your friends!')),
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
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
