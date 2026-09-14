import 'package:flutter/material.dart';
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
  final TextEditingController _lengthCtrl = TextEditingController(text: '300');
  
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
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, 
                  padding: const EdgeInsets.all(16)
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Generate Content', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            if (_output != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12, 
                  borderRadius: BorderRadius.circular(8)
                ),
                child: MarkdownBody(data: _output!),
              )
          ],
        ),
      ),
    );
  }
}
