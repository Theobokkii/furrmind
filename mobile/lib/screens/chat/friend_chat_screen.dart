import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gamification_service.dart';
import '../../core/services/firestore_service.dart';
import '../profile/friend_profile_screen.dart';

class FriendChatScreen extends ConsumerStatefulWidget {
  final String friendName;
  const FriendChatScreen({super.key, required this.friendName});
  @override
  ConsumerState<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends ConsumerState<FriendChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _amITyping = false;
  String get _currentUsername => ref.read(userProfileProvider).value?.username ?? '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_currentUsername.isEmpty) return;
    
    if (_controller.text.isNotEmpty && !_amITyping) {
      _amITyping = true;
      ref.read(firestoreServiceProvider).updateTypingStatus(_currentUsername, widget.friendName, true);
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_amITyping && mounted) {
        _amITyping = false;
        ref.read(firestoreServiceProvider).updateTypingStatus(_currentUsername, widget.friendName, false);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUsername.isEmpty) return;
    
    _controller.clear();
    if (_amITyping) {
      _amITyping = false;
      ref.read(firestoreServiceProvider).updateTypingStatus(_currentUsername, widget.friendName, false);
    }
    
    await ref.read(firestoreServiceProvider).sendFriendMessage(_currentUsername, widget.friendName, text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestore = ref.watch(firestoreServiceProvider);
    final friendProfileAsync = ref.watch(friendProfileProvider(widget.friendName));
    
    if (_currentUsername.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final displayName = friendProfileAsync.value?.name ?? widget.friendName;
    final pronouns = friendProfileAsync.value?.pronouns ?? '';
    final avatarEmoji = friendProfileAsync.value?.avatarEmoji ?? '🐾';
    final nameDisplay = pronouns.isNotEmpty ? '$displayName ($pronouns)' : displayName;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: getAvatarImageProvider(avatarEmoji),
              child: buildAvatar(avatarEmoji, fontSize: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nameDisplay, style: const TextStyle(fontSize: 16)),
                const Text(
                  'Online', 
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.green,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.getFriendChatMessagesStream(_currentUsername, widget.friendName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg["senderId"] == _currentUsername;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                        ),
                        child: Text(
                          msg["text"] as String,
                          style: TextStyle(
                            color: isUser 
                                ? theme.colorScheme.onPrimary 
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    );
                  },
                );
              }
            ),
          ),
          StreamBuilder<bool>(
            stream: firestore.getTypingStatusStream(_currentUsername, widget.friendName),
            builder: (context, snapshot) {
              final isTyping = snapshot.data ?? false;
              if (!isTyping) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: getAvatarImageProvider(avatarEmoji),
                        child: buildAvatar(avatarEmoji, fontSize: 12),
                      ),
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
                            Text(
                              '$displayName is typing',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
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
              );
            }
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message $displayName...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
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

