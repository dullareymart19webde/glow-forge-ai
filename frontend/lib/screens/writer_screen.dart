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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1136),
            Color(0xFF381460),
            Color(0xFF1E1136),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('AI Writer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDropdown(
                  value: _target,
                  label: 'Output Type',
                  items: targets,
                  onChanged: (v) => setState(() => _target = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _topicCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Topic / Content',
                    labelStyle: TextStyle(color: Colors.purple[200]),
                    filled: true,
                    fillColor: Colors.black.withAlpha(50),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _tone,
                        label: 'Tone',
                        items: tones,
                        onChanged: (v) => setState(() => _tone = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdown(
                        value: _language,
                        label: 'Language',
                        items: languages,
                        onChanged: (v) => setState(() => _language = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedLength,
                  label: 'Length',
                  items: lengths,
                  onChanged: (v) => setState(() => _selectedLength = v!),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  onPressed: _isLoading ? null : _generateText,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: const Text('Forge Content', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.pinkAccent.withAlpha(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withAlpha(100),
                                blurRadius: 30,
                                spreadRadius: 10,
                              )
                            ]
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.pinkAccent,
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Forging Content...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Applying AI magic',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.pink[100],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_output != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(80), 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pinkAccent.withAlpha(50), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withAlpha(30),
                          blurRadius: 20,
                          spreadRadius: 5,
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
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 12),
                        MarkdownBody(
                          data: _output!,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
                            h1: const TextStyle(color: Colors.pinkAccent),
                            h2: const TextStyle(color: Colors.pinkAccent),
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF381460),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.purple[200]),
        filled: true,
        fillColor: Colors.black.withAlpha(50),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: onChanged,
    );
  }
}
