import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:image_picker/image_picker.dart';

class AppwriteService {
  final Client client = Client();
  late final Storage storage;
  late final Databases databases;

  late final Account account;

  final String projectId = '6aa9f963003c56fa1a88';
  final String bucketId = '6aa9f9e30014bda4a6ff';
  final String databaseId = '6aaa09da0021ae343f57';
  final String tableId = '6aaa0d9100160e81c694'; // The single table they created for everything

  AppwriteService() {
    client
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject(projectId)
      ..setSelfSigned(status: true);

    storage = Storage(client);
    databases = Databases(client);
    account = Account(client);
  }

  // --- AUTHENTICATION ---
  Future<models.User> signUp(String email, String password, String name) async {
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    await account.createEmailPasswordSession(email: email, password: password);
    return user;
  }

  Future<models.Session> signIn(String email, String password) async {
    return await account.createEmailPasswordSession(email: email, password: password);
  }

  Future<void> signOut() async {
    await account.deleteSession(sessionId: 'current');
  }

  Future<models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (e) {
      return null;
    }
  }

  // --- DATABASE ---
  
  /// Uploads an image to Appwrite Storage and returns its URL
  Future<String> uploadPhoto(XFile imageFile) async {
    try {
      final file = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );

      return 'https://cloud.appwrite.io/v1/storage/buckets/$bucketId/files/${file.$id}/view?project=$projectId';
    } catch (e) {
      throw Exception('Failed to upload photo to Appwrite: $e');
    }
  }

  /// Saves a chat session (using the single table workaround)
  Future<void> createChatSession(String sessionId, String userId, String title) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: tableId,
      documentId: sessionId, // Use session ID as document ID for easy fetching
      data: {
        'user_id': userId,
        'session_title': title,
        'session_id': sessionId,
        'sender_role': 'system', // N/A
        'message_content': 'SESSION_ROOT', // N/A
      },
    );
  }

  /// Saves a chat message
  Future<void> saveChatMessage(String sessionId, String userId, String role, String content) async {
    // Truncate to prevent Appwrite max limit crash
    final safeContent = content.length > 9900 ? content.substring(0, 9900) + '\n\n[Message truncated in database]' : content;

    await databases.createDocument(
      databaseId: databaseId,
      collectionId: tableId,
      documentId: ID.unique(),
      data: {
        'user_id': userId,
        'session_title': 'N/A', // N/A
        'session_id': sessionId,
        'sender_role': role,
        'message_content': safeContent,
      },
    );
  }

  /// Gets all sessions for a user
  Future<List<models.Document>> getUserSessions(String userId) async {
    final result = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: tableId,
      queries: [
        Query.equal('user_id', userId),
        Query.equal('message_content', 'SESSION_ROOT'), // Filter out the actual messages
        Query.orderDesc('\$createdAt')
      ],
    );
    return result.documents;
  }

  /// Gets all messages for a session
  Future<List<models.Document>> getSessionMessages(String sessionId) async {
    final result = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: tableId,
      queries: [
        Query.equal('session_id', sessionId),
        Query.notEqual('message_content', 'SESSION_ROOT'), // Filter out the session root row
        Query.orderAsc('\$createdAt')
      ],
    );
    return result.documents;
  }
}

