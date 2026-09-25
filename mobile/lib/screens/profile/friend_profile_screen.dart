import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_profile.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/gamification_service.dart';

final friendProfileProvider = FutureProvider.family<UserProfile?, String>((ref, username) async {
  final firestore = ref.watch(firestoreServiceProvider);
  final results = await firestore.searchUsersByUsername(username);
  if (results.isEmpty) return null;
  try {
    return results.firstWhere((u) => u.username == username);
  } catch (e) {
    return null;
  }
});

// Helper for displaying emoji or image avatars (reusing logic)
ImageProvider? getBannerImageProvider(String id) {
  if (id.startsWith('http')) return NetworkImage(id);
  if (id.startsWith('assets/')) return AssetImage(id);
  return null;
}

ImageProvider? getAvatarImageProvider(String id) {
  if (id.startsWith('http')) return NetworkImage(id);
  if (id.startsWith('assets/')) return AssetImage(id);
  return null;
}

Widget buildAvatar(String id, {double fontSize = 40}) {
  if (id.startsWith('http') || id.startsWith('assets/')) return const SizedBox.shrink();
  return Text(id.isEmpty ? '🐾' : id, style: TextStyle(fontSize: fontSize));
}

class FriendProfileScreen extends ConsumerWidget {
  final String friendName; // This is actually the username
  
  const FriendProfileScreen({super.key, required this.friendName});

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
    final profileAsync = ref.watch(friendProfileProvider(friendName));
    final currentUserProfileAsync = ref.watch(userProfileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(friendName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('User not found'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
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
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profile.name,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (profile.pronouns.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  profile.pronouns,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${profile.username}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            profile.bio.isNotEmpty ? profile.bio : "This user hasn't written a bio yet.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BadgeChip(
                          icon: Icons.star_rounded,
                          label: 'Level ${profile.currentLevel}',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              
              if (profile.unlockedBadges.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Achievements',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
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
                ),
              ],
              
              const SizedBox(height: 32),
              
              currentUserProfileAsync.when(
                data: (currentUser) {
                  if (currentUser.username == friendName) {
                    return const SizedBox.shrink(); // own profile
                  }
                  
                  final isFriend = currentUser.friendIds.contains(friendName);
                  final isPendingIncoming = currentUser.pendingFriendRequests.contains(friendName);
                  final isPendingOutgoing = currentUser.sentFriendRequests.contains(friendName);
                  final firestore = ref.read(firestoreServiceProvider);

                  if (isFriend) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/friend-chat', extra: friendName);
                            },
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text('Send Message'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              await firestore.removeFriend(friendName);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unfriended $friendName')),
                                );
                                context.pop();
                              }
                            },
                            icon: Icon(Icons.person_remove_rounded, color: theme.colorScheme.error),
                            label: Text('Remove Friend', style: TextStyle(color: theme.colorScheme.error)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  if (isPendingIncoming) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await firestore.acceptFriendRequest(friendName);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('You are now friends with $friendName!')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('Accept Request'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async {
                              await firestore.declineFriendRequest(friendName);
                              if (context.mounted) {
                                context.pop();
                              }
                            },
                            icon: Icon(Icons.cancel_rounded, color: theme.colorScheme.error),
                            label: Text('Decline Request', style: TextStyle(color: theme.colorScheme.error)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  if (isPendingOutgoing) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await firestore.cancelFriendRequest(friendName);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Canceled request to $friendName')),
                            );
                          }
                        },
                        icon: const Icon(Icons.cancel_schedule_send_rounded),
                        label: const Text('Cancel Request'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.errorContainer,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    );
                  }
                  
                  // Not friends
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await firestore.sendFriendRequest(friendName);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Friend request sent to $friendName!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Add Friend'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
