import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});

  @override
  ConsumerState<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends ConsumerState<ResumeScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _educationCtrl = TextEditingController();
  final TextEditingController _experienceCtrl = TextEditingController();
  final TextEditingController _skillsCtrl = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _output;

  void _generateResume() async {
    if (_nameCtrl.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _output = null;
    });

    final personalInfo = {
      'name': _nameCtrl.text,
      'email': _emailCtrl.text,
    };
    final education = [_educationCtrl.text];
    final experience = [_experienceCtrl.text];
    final skills = _skillsCtrl.text.split(',').map((e) => e.trim()).toList();

    try {
      final api = ref.read(apiProvider);
      final result = await api.generateResume(personalInfo, education, experience, skills);
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    final formSide = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Info', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 16),
          const Text('Education', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _educationCtrl, 
            decoration: const InputDecoration(labelText: 'Degree & University'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          const Text('Experience', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _experienceCtrl, 
            decoration: const InputDecoration(labelText: 'Recent Job & Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _skillsCtrl, 
            decoration: const InputDecoration(labelText: 'Skills (comma separated)'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generateResume,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, padding: const EdgeInsets.all(16)),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate AI Resume', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );

    final outputSide = Container(
      width: double.infinity,
      color: Colors.black12,
      padding: const EdgeInsets.all(16),
      child: _output == null
          ? const Center(child: Text('Fill out the form and generate to see your ATS Resume Data.', textAlign: TextAlign.center))
          : SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(_output),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('AI Resume Builder')),
      body: isMobile
          ? SingleChildScrollView(
              child: Column(
                children: [
                  formSide,
                  SizedBox(height: 400, child: outputSide),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(flex: 1, child: formSide),
                Expanded(flex: 1, child: outputSide),
              ],
            ),
    );
  }
}
