import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../main.dart';

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
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
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
                        ref.read(themeModeProvider.notifier).state =
                            newSelection.first;
                      },
                    ),
                  ),
                ],
              ),
            ),
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
                    'Android Emulator: http://10.0.2.2:8000\nLocal / Web / Desktop: http://127.0.0.1:8000',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'http://10.0.2.2:8000',
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
    );
  }
}
