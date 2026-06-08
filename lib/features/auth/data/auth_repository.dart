import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../core/constants.dart';
import '../domain/user_model.dart';

/// DATA layer: semua logika Firebase untuk autentikasi.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(username);

      final uid = credential.user!.uid;
      final user = UserModel(
        uid: uid,
        name: name,
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toMap());

      await FirebaseCrashlytics.instance.setUserIdentifier(uid);
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseCrashlytics.instance.setUserIdentifier(
        credential.user!.uid,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  Future<void> logout() async {
    await FirebaseCrashlytics.instance.setUserIdentifier('');
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah';
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti';
      case 'network-request-failed':
        return 'Gagal terhubung ke server';
      default:
        return e.message ?? 'Terjadi kesalahan, coba lagi';
    }
  }
}
