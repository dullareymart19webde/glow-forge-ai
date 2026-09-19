import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/providers.dart';

class WriterScreen extends ConsumerStatefulWidget {
  const WriterScreen({super.key});

  @override
  ConsumerState<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends ConsumerState<WriterScreen> {
  final TextEditingController _topicCtrl = TextEditingController();
  
  String _tone = 'Professional';
  String _target = 'Email';
  String _language = 'English';
  String _selectedLength = 'Medium';
  
  bool _isLoading = false;
  String? _output;

  final List<String> targets = ['Essay', 'Email', 'Script', 'Social Caption', 'Translation'];
  final List<String> tones = ['Professional', 'Casual', 'Humorous', 'Persuasive'];
  final List<String> languages = ['English', 'Spanish', 'French', 'Tagalog'];
  final List<String> lengths = ['Short', 'Medium', 'Long'];

  void _generateText() async {
    if (_topicCtrl.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _output = null;
    });

    try {
      final api = ref.read(apiProvider);
      final result = await api.generateText(
        _target,
        _topicCtrl.text,
        _tone,
        _language,
        _selectedLength,
      );
      setState(() {
        _output = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Writer & Translator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _target,
              decoration: const InputDecoration(labelText: 'Output Type'),
              items: targets.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _target = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicCtrl,
              decoration: const InputDecoration(
                labelText: 'Topic / Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tone,
                    decoration: const InputDecoration(labelText: 'Tone'),
                    items: tones.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _tone = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: languages.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _language = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedLength,
              decoration: const InputDecoration(labelText: 'Length'),
              items: lengths.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedLength = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                onPressed: _isLoading ? null : _generateText,
                label: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Generate Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
            if (_output != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), 
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF333333)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withAlpha(25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Generated Output', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20, color: Colors.white54),
                          onPressed: () {
                            if (_output != null) {
                              Clipboard.setData(ClipboardData(text: _output!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied to clipboard!')),
                              );
                            }
                          },
                        )
                      ],
                    ),
                    const Divider(color: Color(0xFF333333)),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: _output!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16, height: 1.5),
                        h1: const TextStyle(color: Color(0xFF6C63FF)),
                        h2: const TextStyle(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}
