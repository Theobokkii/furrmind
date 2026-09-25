import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/mood_service.dart';

class MoodCheckInScreen extends ConsumerStatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  ConsumerState<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends ConsumerState<MoodCheckInScreen> {
  EmotionDefinition? _primary;
  double _intensity = 3;
  final List<EmotionDefinition> _secondary = [];
  final List<String> _tags = [];
  String _note = '';

  final _contextCategories = {
    'People': ['Family', 'Friends', 'Partner', 'Colleagues', 'Strangers'],
    'Work': ['Work', 'Study', 'Deadline', 'Meeting', 'Presentation'],
    'Health': ['Sleep', 'Exercise', 'Food', 'Energy', 'Body'],
    'Life': ['Home', 'Money', 'Future', 'Past', 'Self'],
    'Activities': ['Social', 'Alone', 'Creative', 'Rest', 'Outdoors'],
  };

  bool _isSaving = false;

  Future<void> _handleSave() async {
    if (_primary == null) return;
    setState(() => _isSaving = true);

    await ref.read(moodServiceProvider).saveMoodCheckIn(
      primary: _primary!,
      intensity: _intensity.toInt(),
      secondary: _secondary,
      contextTags: _tags,
      note: _note,
      gamification: ref.read(gamificationProvider),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in saved! +10 XP ✨')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'How are you feeling?',
                    style: GoogleFonts.fraunces(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Text('🐾', style: TextStyle(fontSize: 28)), // Cato listening pose
                ],
              ),
              const SizedBox(height: 24),

              // Step 1: Primary Emotion
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: kBasicEmotions.length,
                itemBuilder: (context, index) {
                  final emotion = kBasicEmotions[index];
                  final isSelected = _primary?.id == emotion.id;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _primary = emotion),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(emotion.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            emotion.label,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ).animate(target: isSelected ? 1 : 0)
                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Step 2: Intensity
              if (_primary != null) ...[
                Text(
                  'How strong is this feeling?',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _intensity,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: theme.colorScheme.primary,
                  label: ['A little', 'Somewhat', 'Moderately', 'Strongly', 'Very strongly'][_intensity.toInt() - 1],
                  onChanged: (val) => setState(() => _intensity = val),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('A little', style: GoogleFonts.nunito(fontSize: 12, color: theme.hintColor)),
                    Text('Very strongly', style: GoogleFonts.nunito(fontSize: 12, color: theme.hintColor)),
                  ],
                ),
                const SizedBox(height: 32),

                // Step 3: Secondary
                Text(
                  'Anything else you\'re feeling?',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kBasicEmotions.where((e) => e.id != _primary?.id).map((emotion) {
                    final isSelected = _secondary.contains(emotion);
                    return FilterChip(
                      label: Text('${emotion.emoji} ${emotion.label}'),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val && _secondary.length < 3) {
                            _secondary.add(emotion);
                          } else {
                            _secondary.remove(emotion);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Step 4: Context
                Text(
                  'What\'s connected to this?',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._contextCategories.entries.map((cat) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.key, style: GoogleFonts.nunito(fontSize: 14, color: theme.hintColor)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: cat.value.map((tag) {
                          final isSelected = _tags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val && _tags.length < 5) _tags.add(tag);
                                else _tags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
                const SizedBox(height: 16),

                // Step 5: Note
                Text(
                  'Want to add a note?',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLength: 200,
                  maxLines: 3,
                  onChanged: (val) => _note = val,
                  decoration: InputDecoration(
                    hintText: 'What happened?',
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Step 6: Save
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Save check-in', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
