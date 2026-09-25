import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';


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

class FriendProfileScreen extends StatelessWidget {
  final String friendName;
  
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Mock data for the friend based on name
    final List<Map<String, dynamic>> mockDiscoverList = [
      {'name': 'Jordan_99', 'avatar': 'https://picsum.photos/seed/jordan/150', 'level': 5, 'pronouns': 'he/him', 'bio': 'Loves cats and coding.', 'banner': 'ocean', 'badges': ['Early Adopter']},
      {'name': 'AlexTheGreat', 'avatar': 'https://picsum.photos/seed/alex/150', 'level': 8, 'pronouns': 'they/them', 'bio': 'Just exploring mindfulness.', 'banner': 'sunset', 'badges': ['Zen Master']},
      {'name': 'TaylorSwift123', 'avatar': '👩🏼', 'level': 12, 'pronouns': 'she/her', 'bio': 'Singing my feelings away 🎵', 'banner': 'neon_glow', 'badges': ['Superstar', 'Helper']},
      {'name': 'Casey_Jones', 'avatar': 'https://picsum.photos/seed/casey/150', 'level': 3, 'pronouns': 'he/they', 'bio': 'New here, saying hi!', 'banner': 'default', 'badges': []},
      {'name': 'SammyBoy', 'avatar': '🐶', 'level': 2, 'pronouns': 'he/him', 'bio': 'A dog person in a cat app?', 'banner': 'halloween', 'badges': ['Curious']},
      {'name': 'Riley_R', 'avatar': 'https://picsum.photos/seed/riley/150', 'level': 6, 'pronouns': 'she/they', 'bio': 'Tracking moods and taking names.', 'banner': 'christmas', 'badges': ['Consistent']},
    ];

    final mockDetails = mockDiscoverList.firstWhere(
      (u) => u['name'] == friendName, 
      orElse: () => {'name': friendName, 'avatar': '🐾', 'level': 1, 'pronouns': '', 'bio': 'This user loves privacy.', 'banner': 'default', 'badges': <String>[]}
    );

    final avatar = mockDetails['avatar'] as String;
    final level = mockDetails['level'] as int;
    final pronouns = mockDetails['pronouns'] as String;
    final bio = mockDetails['bio'] as String;
    final banner = mockDetails['banner'] as String;
    final badges = (mockDetails['badges'] as List).cast<String>();
    
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
        child: SingleChildScrollView(
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
                            image: getBannerImageProvider(banner) != null 
                                ? DecorationImage(
                                    image: getBannerImageProvider(banner)!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: getBannerImageProvider(banner) == null 
                                ? LinearGradient(
                                    colors: [
                                      _getBannerColor(banner, theme).withValues(alpha: 0.5),
                                      _getBannerColor(banner, theme).withValues(alpha: 0.2),
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
                              backgroundImage: getAvatarImageProvider(avatar),
                              child: buildAvatar(avatar, fontSize: 40),
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
                            text: friendName,
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (pronouns.isNotEmpty)
                            TextSpan(
                              text: ' ($pronouns)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BadgeChip(
                          icon: Icons.star_rounded,
                          label: 'Level $level',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 24),
              
              if (badges.isNotEmpty) ...[
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
                    children: badges.map((badge) => Container(
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
                  onPressed: () {
                    // Logic to remove friend could go here
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unfriended $friendName')),
                    );
                    context.pop();
                  },
                  icon: Icon(Icons.person_remove_rounded, color: theme.colorScheme.error),
                  label: Text('Remove Friend', style: TextStyle(color: theme.colorScheme.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
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
