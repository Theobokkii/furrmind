import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/api_service.dart';
import '../../core/services/gamification_service.dart';
import '../../core/theme/theme_provider.dart';
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  bool? _healthStatus;
  bool _isCheckingHealth = false;
  @override
  void initState() {
    super.initState();
    final apiService = ref.read(apiServiceProvider);
    _urlController = TextEditingController(text: apiService.baseUrl);
  }
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
  Future<void> _checkHealth() async {
    setState(() {
      _isCheckingHealth = true;
      _healthStatus = null;
    });
    final apiService = ref.read(apiServiceProvider);
    final ok = await apiService.checkHealth();
    if (mounted) {
      setState(() {
        _healthStatus = ok;
        _isCheckingHealth = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
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
        title: const Text('⚙️ Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
            'ACCOUNT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email Address',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const _ChangePasswordDialog(),
                        );
                      },
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'APPEARANCE',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Mode',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (newSelection) {
                        ref.read(themeProvider.notifier).setThemeMode(
                            newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'UNLOCKABLE THEMES',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ref.watch(userProfileProvider).when(
            data: (profile) {
              final previewTheme = ref.watch(previewThemeProvider);
              final activeTheme = previewTheme ?? profile.activeTheme;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _ThemeSelectorItem(themeId: 'default', title: 'Sage Default', requiredLevel: 1, currentLevel: profile.currentLevel, activeTheme: activeTheme, onTap: () => ref.read(previewThemeProvider.notifier).state = 'default'),
                      _ThemeSelectorItem(themeId: 'midnight', title: 'Twilight Slate', requiredLevel: 1, currentLevel: profile.currentLevel, activeTheme: activeTheme, onTap: () => ref.read(previewThemeProvider.notifier).state = 'midnight'),
                      _ThemeSelectorItem(themeId: 'blossom', title: 'Dusty Rose', requiredLevel: 2, currentLevel: profile.currentLevel, activeTheme: activeTheme, onTap: () => ref.read(previewThemeProvider.notifier).state = 'blossom'),
                      _ThemeSelectorItem(themeId: 'mint', title: 'Seafoam Glow', requiredLevel: 3, currentLevel: profile.currentLevel, activeTheme: activeTheme, onTap: () => ref.read(previewThemeProvider.notifier).state = 'mint'),
                      _ThemeSelectorItem(themeId: 'lavender', title: 'Lilac Dream', requiredLevel: 4, currentLevel: profile.currentLevel, activeTheme: activeTheme, onTap: () => ref.read(previewThemeProvider.notifier).state = 'lavender'),
                      _ThemeSelectorItem(themeId: 'crimson', title: 'Warm Terracotta', requiredLevel: 5, currentLevel: profile.currentLevel, activeTheme: activeTheme, onTap: () => ref.read(previewThemeProvider.notifier).state = 'crimson'),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),
          Text(
            'BACKEND CONNECTION',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Base URL',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Android Emulator: http://10.0.2.2:8000',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'http://127.0.0.1:8000',
                      prefixIcon: Icon(Icons.link),
                    ),
                    onSubmitted: (url) {
                      ref.read(apiServiceProvider).baseUrl = url.trim();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('API URL saved')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(apiServiceProvider).baseUrl = _urlController
                              .text
                              .trim();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API URL saved')),
                          );
                        },
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isCheckingHealth ? null : _checkHealth,
                        icon: _isCheckingHealth
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.favorite_border, size: 18),
                        label: const Text('Test Health'),
                      ),
                    ],
                  ),
                  if (_healthStatus != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _healthStatus! ? Icons.check_circle : Icons.error,
                          color: _healthStatus! ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _healthStatus!
                              ? 'Connected successfully (API healthy)'
                              : 'Could not connect to backend server',
                          style: TextStyle(
                            color: _healthStatus! ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'ABOUT FURRMIND',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🐾', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        'Furrmind v1.0.0',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'An AI-powered cognitive behavioral therapy (CBT) journaling companion that helps you detect cognitive distortions and reframe negative automatic thoughts into balanced perspectives.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomApplyBar(context, ref),
    );
  }

  Widget _buildBottomApplyBar(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final previewThemeId = ref.watch(previewThemeProvider);
    
    return profileAsync.maybeWhen(
      data: (profile) {
        if (previewThemeId == null || previewThemeId == profile.activeTheme) {
          return const SizedBox.shrink();
        }
        
        // Define required levels
        final requirements = {
          'default': 1, 'midnight': 1, 'blossom': 2, 'mint': 3, 'lavender': 4, 'crimson': 5
        };
        final requiredLevel = requirements[previewThemeId] ?? 1;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Previewing Theme',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Save changes?',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => ref.read(previewThemeProvider.notifier).state = null,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (profile.currentLevel < requiredLevel) {
                        // Show middle popup error
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Level Required 🔒'),
                            content: Text(
                              'You need to reach Level $requiredLevel to unlock this theme. Keep journaling to level up!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Okay'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Save theme
                        ref.read(gamificationProvider).updateProfile(activeTheme: previewThemeId);
                        ref.invalidate(userProfileProvider);
                        ref.read(previewThemeProvider.notifier).state = null;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Theme saved successfully ✨')),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
class _ThemeSelectorItem extends ConsumerWidget {
  final String themeId;
  final String title;
  final int requiredLevel;
  final int currentLevel;
  final String activeTheme;
  final VoidCallback onTap;

  const _ThemeSelectorItem({
    required this.themeId,
    required this.title,
    required this.requiredLevel,
    required this.currentLevel,
    required this.activeTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = currentLevel < requiredLevel;
    final isSelected = activeTheme == themeId;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isLocked 
            ? Icons.lock_outline 
            : (isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
        color: isLocked ? Colors.grey : theme.colorScheme.primary,
      ),
      title: Text(
        title, 
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isLocked ? Colors.grey : null,
        ),
      ),
      trailing: isLocked 
          ? Text('Lvl $requiredLevel', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)) 
          : null,
      onTap: onTap,
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) throw Exception('Not logged in');
      
      // Re-authenticate
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: _currentPasswordController.text
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'An error occurred';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
              obscureText: true,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
              obscureText: true,
              validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
              obscureText: true,
              validator: (v) => v != _newPasswordController.text ? 'Passwords do not match' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
