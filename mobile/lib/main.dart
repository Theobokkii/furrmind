import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/journal_entry.dart';
import 'core/models/user_profile.dart';
import 'core/models/mood_entry.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/mock_data_service.dart';
import 'core/services/gamification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(MoodEntryAdapter());
  await MockDataService.seedIfNeeded();
  runApp(
    const ProviderScope(
      child: FurrmindApp(),
    ),
  );
}
class FurrmindApp extends ConsumerWidget {
  const FurrmindApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final previewTheme = ref.watch(previewThemeProvider);
    final activeTheme = previewTheme ?? profileAsync.value?.activeTheme ?? 'default';
    return MaterialApp.router(
      title: 'FurrMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(activeTheme, brightness: Brightness.light),
      darkTheme: AppTheme.getTheme(activeTheme, brightness: Brightness.dark),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
