import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'chat_screen.dart';
import 'writer_screen.dart';
import 'resume_screen.dart';
import 'photo_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(77), width: 1.5), // 0.3
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(25), // 0.1
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(38), // 0.15
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('GLOWFORGE AI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final appwrite = ref.read(appwriteProvider);
                await appwrite.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout error: $e')));
                }
              }
            },
          )
        ],
      ),
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What would you like to forge today?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.purple[200],
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.0 : 0.85,
                    children: [
                      _buildFeatureCard(
                        context,
                        title: 'AI Chat',
                        subtitle: 'Converse, learn, and explore ideas.',
                        icon: Icons.chat_bubble_outline,
                        color: Colors.purpleAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                      ),
                      _buildFeatureCard(
                        context,
                        title: 'AI Writer',
                        subtitle: 'Draft emails, essays, and stories.',
                        icon: Icons.edit_document,
                        color: Colors.pinkAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WriterScreen())),
                      ),
                      _buildFeatureCard(
                        context,
                        title: 'Resume AI',
                        subtitle: 'Generate ATS-friendly resumes.',
                        icon: Icons.work_outline,
                        color: Colors.tealAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeScreen())),
                      ),
                      _buildFeatureCard(
                        context,
                        title: 'Photo Studio',
                        subtitle: 'Enhance, sketch, and remove BGs.',
                        icon: Icons.photo_filter,
                        color: Colors.amberAccent,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoScreen())),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

