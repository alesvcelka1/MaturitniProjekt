import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrace uživatele s rolí
  Future<String?> register(String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
      });

      return null; // null = úspěch
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Přihlášení uživatele
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // null = úspěch
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  /// Odhlášení
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Získání role přihlášeného uživatele
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _firestore.collection('users').doc(user.uid).get();
    return snap['role'] as String?;
  }

  /// Stream přihlášeného uživatele
  Stream<User?> get userStream => _auth.authStateChanges();
}
