import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/mood_service.dart';

class MoodResultScreen extends ConsumerWidget {
  final EmotionDefinition primaryEmotion;
  
  const MoodResultScreen({
    super.key,
    required this.primaryEmotion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Generate dynamic mock fact & recommendation
    final fact = _getFact(primaryEmotion.label);
    final recommendation = _getRecommendation(primaryEmotion.label);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/dashboard'),
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    primaryEmotion.emoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              ),
              const SizedBox(height: 24),
              Text(
                'Check-in Saved!',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              Container(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '+10 XP ✨',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).scale(),
              const SizedBox(height: 48),
              
              // Fact Card
              Card(
                elevation: 0,
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Did you know?',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fact,
                        style: GoogleFonts.inter(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
              
              const SizedBox(height: 16),
              
              // Recommendation Card
              Card(
                elevation: 0,
                color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Recommendation',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation,
                        style: GoogleFonts.inter(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1),

              const Spacer(flex: 2),
              
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () => context.go('/dashboard'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }

  String _getFact(String emotion) {
    emotion = emotion.toLowerCase();
    if (emotion.contains('joy')) return "Joy releases dopamine and serotonin in your brain, actually boosting your immune system and physical health!";
    if (emotion.contains('sad')) return "Crying contains stress hormones. Shedding emotional tears literally flushes stress out of your body.";
    if (emotion.contains('ang')) return "Anger increases blood flow to your hands, an evolutionary trait preparing you to take action and defend your boundaries.";
    if (emotion.contains('fear') || emotion.contains('anxi')) return "Anxiety is your brain's alarm system. It means your body is flooded with oxygen, trying to protect you from perceived danger.";
    if (emotion.contains('surpr')) return "Surprise resets your brain! It interrupts your current thought patterns and forces you to focus entirely on the present moment.";
    if (emotion.contains('disgust')) return "Disgust evolved to protect us from pathogens and poisons, but humans also feel 'moral disgust' when our values are violated.";
    return "Emotions are data, not directives. Acknowledging how you feel reduces the intensity of the emotion by up to 50%!";
  }

  String _getRecommendation(String emotion) {
    emotion = emotion.toLowerCase();
    if (emotion.contains('joy')) return "Capitalize on this feeling! Write down three things that contributed to this joy so you can recreate it later.";
    if (emotion.contains('sad')) return "Wrap yourself in a heavy blanket and listen to some calming music. Let yourself feel it without judgment for 10 minutes.";
    if (emotion.contains('ang')) return "Channel this energy. Try intense physical movement like sprinting or pushups, or do a 'brain dump' on paper and tear it up.";
    if (emotion.contains('fear') || emotion.contains('anxi')) return "Try the 4-7-8 breathing technique: Inhale for 4s, hold for 7s, exhale slowly for 8s. Repeat 4 times to signal safety to your nervous system.";
    if (emotion.contains('surpr')) return "Take a deep breath and orient yourself. Name 5 things you can see around you to ground yourself in reality.";
    if (emotion.contains('disgust')) return "If it's moral disgust, write down exactly which of your core values felt violated. It helps clarify what's important to you.";
    return "Drink a glass of water, stretch your shoulders, and remember that this feeling is temporary.";
  }
}
