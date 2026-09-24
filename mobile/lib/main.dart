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
    return MaterialApp.router(
      title: 'FurrMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
