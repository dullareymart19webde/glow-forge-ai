import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/appwrite_service.dart';

// Provides a singleton-like instance of the ApiService
final apiProvider = Provider<ApiService>((ref) => ApiService());

// Provides a singleton-like instance of the AppwriteService
final appwriteProvider = Provider<AppwriteService>((ref) => AppwriteService());
