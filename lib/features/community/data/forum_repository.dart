import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/post_model.dart';
import '../domain/comment_model.dart';

class ForumRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection = 'posts';

  // --- FITUR POST ---
  Future<void> createPost(String content, String authorName) async {
    if (content.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    await _db.collection(collection).add({
      'content': content,
      'authorName': authorName,
      'authorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'likedBy': [],
      'commentsCount': 0,
    });
  }

  // --- FITUR EDIT & DELETE POST ---
  Future<void> updatePost(String postId, String newContent) async {
    if (newContent.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    await _db.collection(collection).doc(postId).update({
      'content': newContent,
    });
  }

  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    // Peringatan Arsitektur: Ini cuma menghapus dokumen induk.
    // Subcollection 'comments' akan menjadi orphaned data.
    // Dimaafkan untuk skala MVP kampus.
    await _db.collection(collection).doc(postId).delete();
  }

  Stream<List<PostModel>> getPostsStream() {
    return _db
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // --- FITUR LIKE ---
  Future<void> toggleLike(String postId, List<String> currentLikes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _db.collection(collection).doc(postId);

    if (currentLikes.contains(user.uid)) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([user.uid])
      });
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  // --- FITUR KOMENTAR ---
  Future<void> addComment(String postId, String content, String authorName) async {
    if (content.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    final batch = _db.batch();

    final postRef = _db.collection(collection).doc(postId);
    final commentRef = postRef.collection('comments').doc();

    batch.set(commentRef, {
      'content': content,
      'authorName': authorName,
      'authorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(postRef, {
      'commentsCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<List<CommentModel>> getCommentsStream(String postId) {
    return _db
        .collection(collection)
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }
}