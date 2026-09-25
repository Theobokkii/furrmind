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
        length: 3,
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
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: const [
                  Tab(text: '👥 Friends'),
                  Tab(text: '📩 Requests'),
                  Tab(text: '🔍 Discover'),
                ],
              ),
            ),
            Expanded(
              child: profileAsync.when(
                data: (profile) => TabBarView(
                  children: [
                    _FriendsList(profile: profile),
                    _RequestsList(profile: profile),
                    _DiscoverList(),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Error loading profile')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendsList extends ConsumerWidget {
  final UserProfile profile;
  const _FriendsList({required this.profile});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.friendIds.isEmpty) {
      return const Center(
        child: Text('You have no friends yet. Go to Discover to find some!'),
      );
    }
    
    final friendsAsync = ref.watch(friendsListProvider(profile.friendIds));
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile.friendIds.isNotEmpty) ...[
          friendsAsync.when(
            data: (friends) => Column(
              children: friends.asMap().entries.map((entry) {
                final index = entry.key;
                final friend = entry.value;
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
                    subtitle: Text('@${friend.username} • Level ${friend.currentLevel}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blueAccent),
                      onPressed: () => context.push('/friend-chat', extra: friend.username),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading friends: $e')),
          ),
        ],
      ],
    );
  }
}

class _RequestsList extends ConsumerWidget {
  final UserProfile profile;
  const _RequestsList({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (profile.pendingFriendRequests.isEmpty && profile.sentFriendRequests.isEmpty) {
      return const Center(
        child: Text('No pending requests.'),
      );
    }
    
    final incomingAsync = profile.pendingFriendRequests.isNotEmpty 
        ? ref.watch(friendsListProvider(profile.pendingFriendRequests))
        : const AsyncValue<List<UserProfile>>.data([]);
        
    final sentAsync = profile.sentFriendRequests.isNotEmpty 
        ? ref.watch(friendsListProvider(profile.sentFriendRequests))
        : const AsyncValue<List<UserProfile>>.data([]);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (profile.pendingFriendRequests.isNotEmpty) ...[
          Text('Incoming Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          incomingAsync.when(
            data: (pending) => Column(
              children: pending.map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: ListTile(
                  onTap: () => context.push('/friend-profile', extra: user.username),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: getAvatarImageProvider(user.avatarEmoji),
                    child: buildAvatar(user.avatarEmoji, fontSize: 20),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('@${user.username}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                        onPressed: () async {
                          await ref.read(firestoreServiceProvider).acceptFriendRequest(user.username);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                        onPressed: () async {
                          await ref.read(firestoreServiceProvider).declineFriendRequest(user.username);
                        },
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: 24),
        ],
        
        if (profile.sentFriendRequests.isNotEmpty) ...[
          Text('Sent Requests', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          sentAsync.when(
            data: (sent) => Column(
              children: sent.map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                child: ListTile(
                  onTap: () => context.push('/friend-profile', extra: user.username),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    backgroundImage: getAvatarImageProvider(user.avatarEmoji),
                    child: buildAvatar(user.avatarEmoji, fontSize: 20),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('@${user.username}'),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(firestoreServiceProvider).cancelFriendRequest(user.username);
                    },
                    child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ),
              )).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ],
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
                          trailing: Builder(
                            builder: (context) {
                              final isPending = profile.sentFriendRequests.contains(user.username);
                              return ElevatedButton.icon(
                                icon: Icon(isPending ? Icons.pending_actions_rounded : Icons.person_add_rounded, size: 18),
                                label: Text(isPending ? 'Pending' : 'Add'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () async {
                                  final firestore = ref.read(firestoreServiceProvider);
                                  if (isPending) {
                                    await firestore.cancelFriendRequest(user.username);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Canceled request to ${user.username}')),
                                      );
                                    }
                                  } else {
                                    await firestore.sendFriendRequest(user.username);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Friend request sent to ${user.username}!')),
                                      );
                                    }
                                  }
                                },
                              );
                            }
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
