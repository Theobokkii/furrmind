import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/gamification_service.dart';
import '../../core/utils/image_helper.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _pronounsController;
  late TextEditingController _bioController;
  
  String _avatarEmoji = '👤';
  String _bannerColorId = 'default';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).value;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _pronounsController = TextEditingController(text: profile?.pronouns ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _avatarEmoji = profile?.avatarEmoji ?? '🐼';
    _bannerColorId = profile?.bannerUrl ?? 'default';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Color _getBannerColor(String id, ThemeData theme) {
    switch (id) {
      case 'ocean': return const Color(0xFF86A789);
      case 'sunset': return const Color(0xFFD5A760);
      case 'christmas': return const Color(0xFFC97B7B);
      case 'halloween': return const Color(0xFF978FAD);
      case 'neon_glow': return const Color(0xFF7BA1A8);
      default: return theme.colorScheme.primary;
    }
  }

  String? get _usernameError {
    final val = _usernameController.text.trim().replaceFirst('@', '');
    if (val.isEmpty) return 'Username cannot be empty';
    if (!RegExp(r'^([a-zA-Z0-9_]+)#(\d{4})$').hasMatch(val)) {
      return 'Format must be name#1234 (e.g. john#1234)';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (_usernameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before saving.')),
      );
      return;
    }

    final gamification = ref.read(gamificationProvider);
    final cleanUsername = _usernameController.text.trim().replaceFirst('@', '');
    await gamification.updateProfile(
      name: _nameController.text.trim(),
      username: cleanUsername,
      pronouns: _pronounsController.text.trim(),
      bio: _bioController.text.trim(),
      avatarEmoji: _avatarEmoji,
      bannerUrl: _bannerColorId,
    );
    ref.invalidate(userProfileProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated! ✨')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
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
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('PREVIEW', style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              )),
              const SizedBox(height: 12),
              
              // Discord-style Profile Card Preview
              Card(
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      // Banner
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: getBannerImageProvider(_bannerColorId) != null ? null : _getBannerColor(_bannerColorId, theme),
                              image: getBannerImageProvider(_bannerColorId) != null
                                  ? DecorationImage(
                                      image: getBannerImageProvider(_bannerColorId)!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          // Avatar
                          Positioned(
                            left: 16,
                            bottom: -32,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.cardColor,
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: getAvatarImageProvider(_avatarEmoji),
                                child: buildAvatar(_avatarEmoji, fontSize: 32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40), // Space for overlapping avatar
                      
                      // User Info inside Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        if (_pronounsController.text.isNotEmpty)
                                          TextSpan(
                                            text: ' • ${_pronounsController.text}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _usernameController.text.isEmpty ? '@username' : '@${_usernameController.text}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _bioController.text.isEmpty ? 'Write something about yourself...' : _bioController.text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              // CUSTOMIZATION FORMS
              Text('AVATAR & BANNER', style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              )),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avatar Emoji', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ['👤', '🐼', '🐱', '🦊', '🐨', '🐰', '🐯', '🐶'].map((emoji) {
                          final isSelected = _avatarEmoji == emoji;
                          return GestureDetector(
                            onTap: () => setState(() => _avatarEmoji = emoji),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.2) : theme.scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final xfile = await picker.pickImage(source: ImageSource.gallery);
                                if (xfile != null) {
                                  final bytes = await xfile.readAsBytes();
                                  final base64String = base64Encode(bytes);
                                  setState(() {
                                    _avatarEmoji = 'data:image/jpeg;base64,$base64String';
                                  });
                                }
                              },
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Upload Photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _avatarEmoji = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/200';
                                });
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Random URL'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Banner', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _BannerColorOption(id: 'default', color: theme.colorScheme.primary, isSelected: _bannerColorId == 'default', onTap: () => setState(() => _bannerColorId = 'default')),
                            _BannerColorOption(id: 'ocean', color: const Color(0xFF86A789), isSelected: _bannerColorId == 'ocean', onTap: () => setState(() => _bannerColorId = 'ocean')),
                            _BannerColorOption(id: 'sunset', color: const Color(0xFFD5A760), isSelected: _bannerColorId == 'sunset', onTap: () => setState(() => _bannerColorId = 'sunset')),
                            _BannerColorOption(id: 'christmas', color: const Color(0xFFC97B7B), isSelected: _bannerColorId == 'christmas', onTap: () => setState(() => _bannerColorId = 'christmas')),
                            _BannerColorOption(id: 'halloween', color: const Color(0xFF978FAD), isSelected: _bannerColorId == 'halloween', onTap: () => setState(() => _bannerColorId = 'halloween')),
                            _BannerColorOption(id: 'neon_glow', color: const Color(0xFF7BA1A8), isSelected: _bannerColorId == 'neon_glow', onTap: () => setState(() => _bannerColorId = 'neon_glow')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final xfile = await picker.pickImage(source: ImageSource.gallery);
                                if (xfile != null) {
                                  final bytes = await xfile.readAsBytes();
                                  final base64String = base64Encode(bytes);
                                  setState(() {
                                    _bannerColorId = 'data:image/jpeg;base64,$base64String';
                                  });
                                }
                              },
                              icon: const Icon(Icons.upload_rounded),
                              label: const Text('Upload Photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _bannerColorId = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/800/300';
                                });
                              },
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Random URL'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('ABOUT ME', style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              )),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState((){}),
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'What should we call you?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameController,
                        onChanged: (_) => setState((){}),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          hintText: 'Used for adding friends',
                          prefixText: '@',
                          errorText: _usernameController.text.isNotEmpty ? _usernameError : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: ['he/him', 'she/her', 'they/them', 'others (ask)'].contains(_pronounsController.text)
                            ? _pronounsController.text
                            : (_pronounsController.text.isNotEmpty ? 'others (ask)' : null),
                        decoration: InputDecoration(
                          labelText: 'Pronouns',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'he/him', child: Text('he/him')),
                          DropdownMenuItem(value: 'she/her', child: Text('she/her')),
                          DropdownMenuItem(value: 'they/them', child: Text('they/them')),
                          DropdownMenuItem(value: 'others (ask)', child: Text('others (ask)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _pronounsController.text = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bioController,
                        onChanged: (_) => setState((){}),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          hintText: 'A little bit about yourself...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _BannerColorOption extends StatelessWidget {
  final String id;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BannerColorOption({
    required this.id,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}
