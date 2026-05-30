import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants.dart';
import '../domain/workout_model.dart';

/// DATA layer: CRUD workout ke Firestore.
class WorkoutRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.workoutsCollection);

  String newId() => _col.doc().id;

  Future<void> add(WorkoutModel workout) =>
      _col.doc(workout.id).set(workout.toMap());

  Future<void> update(WorkoutModel workout) =>
      _col.doc(workout.id).update(workout.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  Stream<List<WorkoutModel>> streamByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('date', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs.map((d) => WorkoutModel.fromMap(d.data())).toList(),
      );
}
