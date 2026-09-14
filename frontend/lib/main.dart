import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/chat_screen.dart';
import 'screens/writer_screen.dart';
import 'screens/resume_screen.dart';
import 'screens/photo_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://tkvmaialvtwzibbewysy.supabase.co',
    anonKey: 'sb_publishable_0-Gk-sdAYSPC5Lh-S8xiyw_xAqWWUSL',
  );

  runApp(const ProviderScope(child: GlowForgeApp()));
}

class GlowForgeApp extends StatelessWidget {
  const GlowForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowForge AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}

// Main navigation removed, app routes directly to ChatScreen
