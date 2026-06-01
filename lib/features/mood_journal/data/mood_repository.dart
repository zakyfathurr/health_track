import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants.dart';
import '../domain/mood_model.dart';

/// DATA layer: CRUD mood ke Firestore. Pakai pola id konsisten
/// (`newId()` -> `set(doc(id))`) supaya model.id == doc ID Firestore.
class MoodRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.moodsCollection);

  String newId() => _col.doc().id;

  Future<void> add(MoodModel mood) => _col.doc(mood.id).set(mood.toMap());

  Future<void> update(MoodModel mood) => _col.doc(mood.id).update(mood.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  Stream<List<MoodModel>> streamByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => MoodModel.fromMap(d.data())).toList(),
      );
}
