import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
  redirect: (context, state) async {
    // For MVP/Day 2, we simulate auth and onboarding status
    // using SharedPreferences. 
    final prefs = await SharedPreferences.getInstance();
    final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
    
    final isSplash = state.uri.path == '/splash';
    final isOnboarding = state.uri.path == '/onboarding';

    // If still in splash, let the splash screen handle its own animation and logic
    if (isSplash) return null;

    if (!hasOnboarded && !isOnboarding) {
      return '/onboarding';
    }

    if (hasOnboarded && isOnboarding) {
      return '/dashboard';
    }

    return null;
  },
);
