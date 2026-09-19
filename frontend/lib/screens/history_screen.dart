import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final appwrite = ref.read(appwriteProvider);
      final user = await appwrite.getCurrentUser();
      if (user == null) {
        setState(() { _isLoading = false; });
        return;
      }

      final sessions = await appwrite.getUserSessions(user.$id);

      setState(() {
        _sessions = sessions.map((doc) => {
          'id': doc.data['session_id'],
          'session_title': doc.data['session_title'],
          'created_at': doc.$createdAt,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat History')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _sessions.isEmpty
          ? const Center(child: Text('No past chat sessions found.'))
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(session['session_title'] ?? 'Session'),
                  subtitle: Text(session['created_at'].toString().split('T')[0]),
                  onTap: () {
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}
