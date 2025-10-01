import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream aktuálního uživatele
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Získání aktuálního uživatele
  User? get currentUser => _auth.currentUser;

  /// Přihlášení přes Google
  Future<User?> signInWithGoogle() async {
    try {
      // Spuštění Google přihlášení
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Uživatel zrušil přihlášení
        return null;
      }

      // Získání autentizačních údajů
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Vytvoření Firebase credentials
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Přihlášení do Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      return userCredential.user;
    } catch (e) {
      throw Exception('Chyba při přihlášení přes Google: $e');
    }
  }

  /// Odhlášení
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Chyba při odhlášení: $e');
    }
  }
}
