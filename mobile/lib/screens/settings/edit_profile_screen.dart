import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gamification_service.dart';
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _pronounsController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedEmoji = '👤';
  String _selectedBanner = 'default';
  bool _isLoading = false;
  final List<String> _avatars = [
    '👤', '🦊', '🐱', '🐶', '🐼', '🐨', '🐯', '🦁', '🐻', '🐰',
    '🐹', '🦋', '🦉', '🦄', '🌟', '🌱', '🌵', '🌻', '🌸', '🍁'
  ];
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  Future<void> _loadProfile() async {
    final gamification = ref.read(gamificationProvider);
    final profile = await gamification.getProfile();
    setState(() {
      _usernameController.text = profile.username;
      _pronounsController.text = profile.pronouns;
      _bioController.text = profile.bio;
      _selectedEmoji = profile.avatarEmoji;
      _selectedBanner = profile.bannerUrl;
      if (!_avatars.contains(_selectedEmoji)) {
        _avatars.insert(0, _selectedEmoji);
      }
    });
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;
    setState(() => _isLoading = true);
    final gamification = ref.read(gamificationProvider);
    await gamification.updateProfile(
      username: username,
      avatarEmoji: _selectedEmoji,
      pronouns: _pronounsController.text.trim(),
      bio: _bioController.text.trim(),
      bannerUrl: _selectedBanner,
    );
    ref.invalidate(userProfileProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully! ✨')),
      );
      Navigator.of(context).pop();
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Username',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'Enter your username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pronouns',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pronounsController,
              decoration: InputDecoration(
                hintText: 'e.g., they/them, she/her',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bio',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Tell others a bit about yourself...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Choose Avatar',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map((emoji) {
                final isSelected = _selectedEmoji == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected 
                        ? theme.colorScheme.primaryContainer 
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: isSelected 
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Text(
              'Profile Banner',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['default', 'ocean', 'sunset', 'christmas', 'halloween', 'neon_glow'].map((bannerId) {
                  final isSelected = _selectedBanner == bannerId;
                  Color getBannerColor() {
                    switch (bannerId) {
                      case 'ocean': return const Color(0xFF0284C7);
                      case 'sunset': return const Color(0xFFF97316);
                      case 'christmas': return const Color(0xFFDC2626);
                      case 'halloween': return const Color(0xFF9C27B0);
                      case 'neon_glow': return const Color(0xFF00E5FF);
                      default: return const Color(0xFF818CF8);
                    }
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBanner = bannerId),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: getBannerColor().withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                      child: Center(
                        child: Text(
                          bannerId.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
