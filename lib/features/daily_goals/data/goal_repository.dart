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

  /// Set progres untuk satu hari tertentu tanpa menyentuh hari lain.
  /// Pakai `set(..., merge:true)` dengan map bersarang, BUKAN dotted-path string
  /// `'progress.<key>'`: `dayKey` ("yyyy-MM-dd") adalah DATA, bukan field path —
  /// merge memperlakukannya sebagai key map biasa sehingga tanggal berhyphen
  /// tidak pernah di-parse sebagai segmen path. `merge` juga membuat dokumen
  /// kalau (karena suatu hal) belum ada, jadi update tak melempar NOT_FOUND.
  /// [value] sudah dipastikan >= 0 oleh use case.
  Future<void> setProgressForDay(String id, String dayKey, double value) =>
      _col.doc(id).set({
        'progress': {dayKey: value},
      }, SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Stream goals milik user. Tidak pakai `orderBy` (hindari composite index);
  /// urut terbaru-dulu dilakukan di klien — aman pada skala daftar target.
  Stream<List<GoalModel>> streamByUser(String userId) =>
      _col.where('userId', isEqualTo: userId).snapshots().map((snap) {
        final goals = snap.docs.map((d) {
          // Doc ID adalah sumber kebenaran untuk `id` — dijamin unik. Ini
          // mencegah ValueKey ganda di ListView (legacy doc bisa punya field
          // `id` kosong/duplikat → assertion sliver) sekaligus menjaga
          // invarian model.id == doc ID.
          final data = d.data();
          data['id'] = d.id;
          return GoalModel.fromMap(data);
        }).toList();
        goals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return goals;
      });
}
