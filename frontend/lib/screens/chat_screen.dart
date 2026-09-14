import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/providers.dart';
import 'writer_screen.dart';
import 'resume_screen.dart';
import 'photo_screen.dart';
import 'auth_screen.dart';
import 'history_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _dbSessionId;
  final String _sessionId = const Uuid().v4(); // Unique per session
  
  String? get _userId {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uId = _userId;
    if (uId == null) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      return;
    }

    try {
      final sessions = await Supabase.instance.client
          .from('chat_sessions')
          .select('id, created_at')
          .eq('user_id', uId)
          .order('created_at', ascending: false)
          .limit(1);

      if (sessions.isNotEmpty) {
        final sessionId = sessions.first['id'] as String;
        setState(() {
          _dbSessionId = sessionId;
        });

        final messages = await Supabase.instance.client
            .from('chat_messages')
            .select('sender_role, message_content, created_at')
            .eq('session_id', sessionId)
            .order('created_at', ascending: true);

        final loadedHistory = messages.map<Map<String, String>>((msg) => {
          'role': msg['sender_role'] == 'ai' ? 'assistant' : 'user',
          'content': msg['message_content'] as String,
        }).toList();

        setState(() {
          _chatHistory = loadedHistory;
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatHistory = [..._chatHistory, {'role': 'user', 'content': text}];
      _isLoading = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      if (_dbSessionId == null && _userId != null) {
        final sessionResponse = await Supabase.instance.client.from('chat_sessions').insert({
          'user_id': _userId!,
          'session_title': 'Chat Session',
        }).select('id').single();
        _dbSessionId = sessionResponse['id'] as String;
      }

      if (_dbSessionId != null) {
        await Supabase.instance.client.from('chat_messages').insert({
          'session_id': _dbSessionId,
          'sender_role': 'user',
          'message_content': text,
        });
      }

      final api = ref.read(apiProvider);
      final response = await api.chat(_sessionId, _userId ?? "test-user-id", text, _chatHistory);
      
      if (_dbSessionId != null) {
        await Supabase.instance.client.from('chat_messages').insert({
          'session_id': _dbSessionId,
          'sender_role': 'ai',
          'message_content': response,
        });
      }

      setState(() {
        _chatHistory = [..._chatHistory, {'role': 'assistant', 'content': response}];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _showFeatureMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                const Text('Features', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.edit_document, color: Colors.deepPurpleAccent),
                  title: const Text('AI Writer'),
                  subtitle: const Text('Draft emails, essays, and stories'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WriterScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.work, color: Colors.deepPurpleAccent),
                  title: const Text('Resume Builder'),
                  subtitle: const Text('Generate an ATS-friendly resume'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_filter, color: Colors.deepPurpleAccent),
                  title: const Text('Photo Enhancer'),
                  subtitle: const Text('Remove backgrounds and enhance images'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PhotoScreen()));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _controller.text = text;
        _sendMessage();
      },
      backgroundColor: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('assets/logo.png'),
            radius: 16,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                BouncingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 100, height: 100),
            const SizedBox(height: 16),
            const Text('GlowForge AI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSuggestionChip('Draft a professional email'),
                  _buildSuggestionChip('Explain Quantum Physics'),
                  _buildSuggestionChip('Tell me a programming joke'),
                  _buildSuggestionChip('Write a sci-fi short story'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GlowForge AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _chatHistory = [];
                _dbSessionId = null;
              });
            },
          )
        ],
      ),
      body: _isInitializing 
        ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
        : Column(
        children: [
          Expanded(
            child: _chatHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _chatHistory.length) {
                        return _buildTypingIndicator();
                      }

                      final msg = _chatHistory[index];
                      final isUser = msg['role'] == 'user';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              const CircleAvatar(
                                backgroundColor: Colors.transparent,
                                backgroundImage: AssetImage('assets/logo.png'),
                                radius: 16,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.deepPurple : Colors.grey[800],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 16),
                                ),
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              child: isUser 
                                  ? Text(msg['content'] ?? '', style: const TextStyle(color: Colors.white))
                                  : MarkdownBody(data: msg['content'] ?? ''),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.grey, size: 28),
                  onPressed: _showFeatureMenu,
                  tooltip: 'Features',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Message GlowForge...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.deepPurpleAccent),
                  onPressed: _sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class BouncingDots extends StatefulWidget {
  const BouncingDots({super.key});

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            var value = (_controller.value - delay) % 1.0;
            if (value < 0) value += 1.0;
            final offset = (value < 0.5) ? -math.sin(value * math.pi * 2) * 4 : 0.0;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: Colors.grey[400], shape: BoxShape.circle),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
