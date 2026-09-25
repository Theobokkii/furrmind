import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/firestore_service.dart';
import '../../core/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final _nameController = TextEditingController();
  final Set<String> _selectedGoals = {};
  
  final List<String> _goalsList = [
    "Journaling", "Anxiety", "Self-awareness", "Better mood", "Understanding myself"
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage == 1 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tell us your name to continue.')),
      );
      return;
    }

    if (_currentPage == 2 && _selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one goal.')),
      );
      return;
    }

    if (_currentPage == 2) {
      final name = _nameController.text.trim();
      
      // Save to SharedPreferences for fast local lookup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_onboarded', true);
      await prefs.setString('user_name', name);
      
      // Save to Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.saveUserProfile(
        UserProfile(
          username: name,
          avatarEmoji: '🐱',
          bio: 'Goals: ${_selectedGoals.join(", ")}',
        )
      );

      if (mounted) context.go('/dashboard');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7C9A7E) : const Color(0xFFD4C8B8),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildButton(String text) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C9A7E),
          foregroundColor: const Color(0xFFFAF7F2),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            "Hi, I'm Cato.",
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "I'll be here while you journal, and we'll get to know your mind together.",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 1.6,
              color: const Color(0xFF6B5D4F),
            ),
          ),
          const Spacer(),
          _buildButton('Nice to meet you'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🤔', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            "What should I call you?",
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: const Color(0xFF3D3229),
            ),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: GoogleFonts.nunito(color: const Color(0xFF9B8B7A)),
              filled: true,
              fillColor: const Color(0xFFF2EDE4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          _buildButton('Continue'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👂', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          Text(
            "What brings you here?",
            style: GoogleFonts.fraunces(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D3229),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _goalsList.map((goal) {
              final isSelected = _selectedGoals.contains(goal);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedGoals.remove(goal);
                    } else {
                      _selectedGoals.add(goal);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C9A7E) : const Color(0xFFF2EDE4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    goal,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFFAF7F2) : const Color(0xFF6B5D4F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          _buildButton('Begin'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Warm cream
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildDotIndicator(),
            const SizedBox(height: 48),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to force button use
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
