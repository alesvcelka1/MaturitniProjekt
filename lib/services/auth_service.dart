import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrace uživatele s rolí (uloženou do Firestore)
  Future<String?> register(String email, String password, String role) async {
    try {
      // 1) vytvoření účtu v Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) uložení dalších údajů do Firestore (asynchronně pro rychlost)
      _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((error) {
        print('Firestore chyba (ale registrace pokračuje): $error');
      });

      // 3) Odhlásit uživatele po registraci
      await _auth.signOut();

      return null; // null = úspěch
    } on FirebaseAuthException catch (e) {
      return _getLocalizedErrorMessage(e.code);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'Nedostatečná oprávnění pro zápis do databáze (users).';
      }
      return 'Chyba databáze: ${e.message ?? e.code}';
    } catch (e) {
      return 'Neočekávaná chyba: ${e.toString()}';
    }
  }

  /// Přihlášení uživatele
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // null = úspěch
    } on FirebaseAuthException catch (e) {
      return _getLocalizedErrorMessage(e.code);
    } catch (e) {
      return 'Neočekávaná chyba: ${e.toString()}';
    }
  }

  /// Odhlášení
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Získání role aktuálně přihlášeného uživatele
  Future<String?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (!snap.exists) return null;

    return snap.data()?['role'] as String?;
  }

  /// Stream aktuálního uživatele (null pokud odhlášený)
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Lokalizované chybové zprávy
  String _getLocalizedErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'Neplatný e-mail.';
      case 'user-disabled':
        return 'Účet byl deaktivován.';
      case 'user-not-found':
        return 'Uživatel s tímto e-mailem neexistuje.';
      case 'wrong-password':
        return 'Nesprávné heslo.';
      case 'email-already-in-use':
        return 'Tento e-mail už je používán.';
      case 'weak-password':
        return 'Heslo je příliš slabé.';
      case 'operation-not-allowed':
        return 'Registrace není povolena.';
      default:
        return 'Došlo k chybě. Zkus to znovu.';
    }
  }
}
