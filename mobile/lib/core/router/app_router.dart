import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/journal/journal_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/chat/friend_chat_screen.dart';
import '../../screens/chat/cato_chat_screen.dart';
import '../../screens/profile/friend_profile_screen.dart';
import '../../screens/mood/mood_checkin_screen.dart';
import '../../screens/mood/mood_result_screen.dart';
import '../../core/services/mood_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/dashboard',
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/journal',
      builder: (context, state) => const JournalScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/friend-chat',
      builder: (context, state) => FriendChatScreen(
        friendName: state.extra as String? ?? 'Friend',
      ),
    ),
    GoRoute(
      path: '/friend-profile',
      builder: (context, state) => FriendProfileScreen(
        friendName: state.extra as String? ?? 'Friend',
      ),
    ),
    GoRoute(
      path: '/cato-chat',
      builder: (context, state) => const CatoChatScreen(),
    ),
    GoRoute(
      path: '/mood-checkin',
      builder: (context, state) => const MoodCheckInScreen(),
    ),
    GoRoute(
      path: '/mood-result',
      builder: (context, state) {
        final emotion = state.extra as EmotionDefinition?;
        return MoodResultScreen(
          primaryEmotion: emotion ?? kBasicEmotions.first,
        );
      },
    ),
  ],
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    final isSplash = state.uri.path == '/splash';
    final isOnboarding = state.uri.path == '/onboarding';
    final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/register';
    
    if (isSplash) return null;
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    
    if (!isAuthenticated) {
      return isAuthRoute ? null : '/login';
    }

    if (isAuthRoute) {
      return hasOnboarded ? '/dashboard' : '/onboarding';
    }

    if (!hasOnboarded && !isOnboarding) {
      return '/onboarding';
    }
    if (hasOnboarded && isOnboarding) {
      return '/dashboard';
    }
    return null;
  },
);
