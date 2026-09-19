import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Widget _buildResumeView() {
    final info = _output!['personal_info'] ?? {};
    final summary = _output!['summary'] ?? '';
    final edu = _output!['education'] as List<dynamic>? ?? [];
    final exp = _output!['experience'] as List<dynamic>? ?? [];
    final skills = _output!['skills'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          info['name'] ?? 'John Doe',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          info['email'] ?? 'email@example.com',
                          style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.black54),
                    tooltip: 'Copy Resume Text',
                    onPressed: () {
                      final sb = StringBuffer();
                      sb.writeln(info['name'] ?? 'John Doe');
                      sb.writeln(info['email'] ?? 'email@example.com');
                      sb.writeln();
                      if (summary.isNotEmpty) {
                        sb.writeln('PROFESSIONAL SUMMARY');
                        sb.writeln(summary);
                        sb.writeln();
                      }
                      if (exp.isNotEmpty) {
                        sb.writeln('EXPERIENCE');
                        for (var e in exp) {
                          sb.writeln('• $e');
                        }
                        sb.writeln();
                      }
                      if (edu.isNotEmpty) {
                        sb.writeln('EDUCATION');
                        for (var e in edu) {
                          sb.writeln('• $e');
                        }
                        sb.writeln();
                      }
                      if (skills.isNotEmpty) {
                        sb.writeln('SKILLS');
                        sb.writeln(skills.join(', '));
                      }
                      
                      Clipboard.setData(ClipboardData(text: sb.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resume text copied!')),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 32, thickness: 2),

              // Summary
              if (summary.isNotEmpty) ...[
                const Text('PROFESSIONAL SUMMARY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(summary, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                const SizedBox(height: 24),
              ],

              // Experience
              if (exp.isNotEmpty) ...[
                const Text('EXPERIENCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...exp.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16, color: Colors.black87)),
                      Expanded(
                        child: Text(e.toString(), style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Education
              if (edu.isNotEmpty) ...[
                const Text('EDUCATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...edu.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16, color: Colors.black87)),
                      Expanded(
                        child: Text(e.toString(), style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              // Skills
              if (skills.isNotEmpty) ...[
                const Text('SKILLS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!)
                    ),
                    child: Text(s.toString(), style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
              child: ElevatedButton.icon(
                icon: const Icon(Icons.document_scanner),
                onPressed: _isLoading ? null : _generateResume,
                label: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Generate Resume', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );

    final outputSide = Container(
      width: double.infinity,
      color: Colors.grey[900], // Dark background to make white paper pop
      padding: const EdgeInsets.all(16),
      child: _output == null
          ? const Center(child: Text('Fill out the form and generate to see your ATS Resume Data.', textAlign: TextAlign.center))
          : _buildResumeView(),
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
