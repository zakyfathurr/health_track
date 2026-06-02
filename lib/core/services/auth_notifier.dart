import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;
}

final authNotifier = AuthNotifier();
