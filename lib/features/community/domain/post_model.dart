import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorName;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;
  final int commentsCount; // <-- TAMBAHAN BARU

  PostModel({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.likedBy = const [],
    this.commentsCount = 0, // <-- TAMBAHAN BARU
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorName: data['authorName'] ?? 'Anonim',
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentsCount: data['commentsCount'] ?? 0, // <-- TAMBAHAN BARU
    );
  }
}