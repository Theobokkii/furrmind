class DistortionResult {
  final String label;
  final double confidence;
  final bool triggered;

  const DistortionResult({
    required this.label,
    required this.confidence,
    required this.triggered,
  });

  factory DistortionResult.fromJson(Map<String, dynamic> json) {
    return DistortionResult(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      triggered: json['triggered'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'triggered': triggered,
  };

  String get displayName {
    final mapping = {
      'all_or_nothing': 'All-or-Nothing Thinking',
      'overgeneralization': 'Overgeneralization',
      'mental_filter': 'Mental Filter',
      'disqualifying_positive': 'Disqualifying the Positive',
      'jumping_to_conclusions': 'Jumping to Conclusions',
      'magnification': 'Magnification',
      'emotional_reasoning': 'Emotional Reasoning',
      'should_statements': 'Should Statements',
      'labeling': 'Labeling',
      'personalization': 'Personalization',
      'catastrophizing': 'Catastrophizing',
      'mind_reading': 'Mind Reading',
      'fortune_telling': 'Fortune Telling',
      'black_and_white': 'Black & White Thinking',
    };
    return mapping[label.toLowerCase()] ??
        label
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) {
              if (w.isEmpty) return w;
              return w[0].toUpperCase() + w.substring(1);
            })
            .join(' ');
  }

  String get description {
    final descriptions = {
      'all_or_nothing':
          'Seeing things in black-or-white categories with no middle ground.',
      'overgeneralization': 'Making broad conclusions from a single event.',
      'mental_filter':
          'Focusing exclusively on negative details while ignoring positives.',
      'disqualifying_positive':
          'Rejecting positive experiences as if they don\'t count.',
      'jumping_to_conclusions':
          'Making negative interpretations without supporting facts.',
      'magnification':
          'Exaggerating the importance of problems or shortcomings.',
      'emotional_reasoning':
          'Assuming feelings reflect reality — "I feel it, so it must be true."',
      'should_statements':
          'Using "should" or "must" statements that create pressure.',
      'labeling': 'Attaching fixed, global labels to yourself or others.',
      'personalization': 'Blaming yourself for events outside your control.',
      'catastrophizing':
          'Expecting the worst possible outcome in every situation.',
      'mind_reading': 'Assuming you know what others are thinking.',
      'fortune_telling': 'Predicting things will turn out badly.',
      'black_and_white':
          'Seeing things as either perfect or a complete failure.',
    };
    return descriptions[label.toLowerCase()] ??
        'A cognitive distortion pattern detected in your thoughts.';
  }
}

class ReframeResult {
  final String reframe;
  final String explanation;
  final List<String> sources;

  const ReframeResult({
    required this.reframe,
    required this.explanation,
    required this.sources,
  });

  factory ReframeResult.fromJson(Map<String, dynamic> json) {
    return ReframeResult(
      reframe: json['reframe'] as String,
      explanation: json['explanation'] as String,
      sources: (json['sources'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'reframe': reframe,
    'explanation': explanation,
    'sources': sources,
  };
}
