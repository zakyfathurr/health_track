import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants.dart';
import '../domain/goal_model.dart';

/// DATA layer: CRUD goals ke Firestore.
class GoalRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.goalsCollection);

  String newId() => _col.doc().id;

  Future<void> add(GoalModel goal) => _col.doc(goal.id).set(goal.toMap());

  Future<void> update(GoalModel goal) => _col.doc(goal.id).update(goal.toMap());

  Future<void> updateProgress(String id, double currentProgress) =>
      _col.doc(id).update({'currentProgress': currentProgress});

  Future<void> delete(String id) => _col.doc(id).delete();

  Stream<List<GoalModel>> streamByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => GoalModel.fromMap(d.data())).toList(),
      );
}
