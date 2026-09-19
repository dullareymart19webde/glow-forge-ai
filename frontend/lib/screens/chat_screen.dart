import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../providers/providers.dart';
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
  String _sessionId = const Uuid().v4(); // Unique per session
  
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final appwrite = ref.read(appwriteProvider);
      final user = await appwrite.getCurrentUser();
      
      if (user == null) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
        return;
      }
      
      _userId = user.$id;

      final sessions = await appwrite.getUserSessions(user.$id);

      if (sessions.isNotEmpty) {
        // Appwrite creates $id for documents
        final sessionId = sessions.first.data['session_id'] as String;
        setState(() {
          _dbSessionId = sessionId;
        });

        final messages = await appwrite.getSessionMessages(sessionId);

        final loadedHistory = messages.map<Map<String, String>>((msg) => {
          'role': msg.data['sender_role'] == 'ai' ? 'assistant' : 'user',
          'content': msg.data['message_content'] as String,
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
      final appwrite = ref.read(appwriteProvider);
      
      if (_dbSessionId == null && _userId != null) {
        await appwrite.createChatSession(_sessionId, _userId!, 'Chat Session');
        _dbSessionId = _sessionId;
      }

      if (_dbSessionId != null && _userId != null) {
        await appwrite.saveChatMessage(_dbSessionId!, _userId!, 'user', text);
      }

      final api = ref.read(apiProvider);
      final activeSessionId = _dbSessionId ?? _sessionId;
      final response = await api.chat(activeSessionId, _userId ?? "test-user-id", text, _chatHistory);
      
      setState(() {
        _chatHistory = [..._chatHistory, {'role': 'assistant', 'content': response}];
      });

      if (_dbSessionId != null && _userId != null) {
        try {
          await appwrite.saveChatMessage(_dbSessionId!, _userId!, 'ai', response);
        } catch (e) {
          debugPrint('Failed to save to database, but message was received: $e');
        }
      }
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


  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      onPressed: () {
        _controller.text = text;
        _sendMessage();
      },
      backgroundColor: const Color(0xFF1E1E1E),
      side: const BorderSide(color: Color(0xFF333333)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withAlpha(77), // 0.3 * 255
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset('assets/logo.png', width: 64, height: 64),
            ),
            const SizedBox(height: 24),
            const Text(
              'GlowForge AI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How can I help you today?',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildSuggestionChip('Draft an email 📧'),
                  _buildSuggestionChip('Explain Quantum Physics ⚛️'),
                  _buildSuggestionChip('Write a story ✍️'),
                  _buildSuggestionChip('Write Python code 💻'),
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
                _sessionId = const Uuid().v4(); // Regenerate!
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isUser ? const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                                ) : null,
                                color: isUser ? null : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 20),
                                ),
                                boxShadow: isUser ? [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF).withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              child: isUser 
                                  ? Text(msg['content'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15))
                                  : MarkdownBody(
                                      data: msg['content'] ?? '',
                                      styleSheet: MarkdownStyleSheet(
                                        p: const TextStyle(fontSize: 15, color: Colors.white70),
                                        code: TextStyle(backgroundColor: Colors.black26, color: Colors.greenAccent[100]),
                                        codeblockDecoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
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
