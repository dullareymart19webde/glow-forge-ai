import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('chat_sessions')
          .select('id, session_title, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _sessions = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading sessions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
