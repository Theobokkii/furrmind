import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class CatoChatScreen extends StatefulWidget {
  const CatoChatScreen({super.key});

  @override
  State<CatoChatScreen> createState() => _CatoChatScreenState();
}

class _CatoChatScreenState extends State<CatoChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      "text": "Meow! I'm Cato, your soft-hearted companion. How are you feeling today?",
      "isUser": false,
      "isCato": true,
    },
  ];
  bool _isTyping = false;

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Mock Cato CBT response
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        
        String response = "";
        final lowerText = text.toLowerCase();
        
        if (lowerText.contains("sad") || lowerText.contains("depress") || lowerText.contains("down")) {
          response = "I'm sorry you're feeling this way. It's completely valid to feel sad sometimes. In CBT, we call this a wave. Instead of fighting it, what if we just observe it for a moment? What physical sensations are you feeling right now?";
        } else if (lowerText.contains("anxious") || lowerText.contains("worry") || lowerText.contains("scared") || lowerText.contains("overwhelmed")) {
          response = "That sounds really overwhelming. Anxiety often tells us that we have to have everything figured out right now. Can we try a simple grounding exercise? Name 3 things you can see around you.";
        } else if (lowerText.contains("angry") || lowerText.contains("mad") || lowerText.contains("frustrat")) {
          response = "Your frustration makes total sense. Anger is usually a protective emotion. Let's take a deep breath. Is there a boundary of yours that felt crossed today?";
        } else if (lowerText.contains("hate") || lowerText.contains("always") || lowerText.contains("never")) {
          response = "I hear you. It sounds like you might be experiencing some 'All-or-Nothing' thinking right now. Let's try to find a softer perspective together. What's one small piece of nuance we might be missing?";
        } else {
          response = "Thank you for sharing that with me. Every thought you put into words is a step toward understanding yourself better. Would you like to explore this feeling deeper, or would you prefer a distraction?";
        }

        _messages.add({
          "text": response,
          "isUser": false,
          "isCato": true,
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: theme.colorScheme.surface.withValues(alpha: 0.7)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🐱', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cato', 
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isTyping ? 'Cato is typing...' : 'Always here to listen', 
                  style: TextStyle(
                    fontSize: 12, 
                    color: _isTyping ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.tertiary.withValues(alpha: 0.2),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["isUser"] as bool;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          child: Text('🐱', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: isUser 
                                    ? theme.colorScheme.primary.withValues(alpha: 0.75) 
                                    : theme.brightness == Brightness.dark 
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.white.withValues(alpha: 0.6),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                msg["text"] as String,
                                style: GoogleFonts.inter(
                                  color: isUser 
                                      ? theme.colorScheme.onPrimary 
                                      : theme.colorScheme.onSurface,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Text('🐱', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingIndicator(delay: 0.ms),
                          const SizedBox(width: 4),
                          _TypingIndicator(delay: 150.ms),
                          const SizedBox(width: 4),
                          _TypingIndicator(delay: 300.ms),
                        ],
                      ),
                    ).animate().fadeIn(),
                  ],
                ),
              ),
            ),
          // TextField Area
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.6),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Share what\'s on your mind...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                            ),
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark 
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Duration delay;
  const _TypingIndicator({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
     .scale(
       delay: delay,
       duration: 600.ms,
       begin: const Offset(0.8, 0.8),
       end: const Offset(1.5, 1.5),
       curve: Curves.easeInOut,
     )
     .then(duration: 600.ms)
     .scale(
       begin: const Offset(1.5, 1.5),
       end: const Offset(0.8, 0.8),
       curve: Curves.easeInOut,
     );
  }
}
