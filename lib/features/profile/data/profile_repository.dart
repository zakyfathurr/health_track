import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants.dart';
import '../../auth/domain/user_model.dart';

/// DATA layer: baca/ubah dokumen profil pengguna di Firestore.
class ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserModel?> getProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateName(String name) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'name': name,
    });
  }
}
