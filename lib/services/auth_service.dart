import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../core/utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registrace uživatele
  Future<String?> register(String email, String password) async {
    try {
      // 1) vytvoření účtu v Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) uložení dalších údajů do Firestore (asynchronně pro rychlost)
      _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'client', // DŮLEŽITÉ: defaultní role
      }, SetOptions(merge: true)).catchError((error) {
        AppLogger.warning('Firestore chyba při registraci (ale registrace pokračuje)', error);
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

  /// Přihlášení přes Google
  Future<String?> signInWithGoogle() async {
    try {
      AppLogger.debug('Spouštím Google Sign-In');
      UserCredential userCred;

      if (kIsWeb) {
        // Web: použít popup flow
        AppLogger.debug('Web platform detected');
        final GoogleAuthProvider provider = GoogleAuthProvider();
        provider.addScope('email');
        userCred = await _auth.signInWithPopup(provider);
      } else {
        // Mobil (Android/iOS): GoogleSignIn plugin
        AppLogger.debug('Mobile platform detected');
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          AppLogger.info('Uživatel zrušil Google přihlášení');
          return 'Přihlášení zrušeno.';
        }
        AppLogger.debug('Google účet vybrán: ${googleUser.email}');
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCred = await _auth.signInWithCredential(credential);
      }

      AppLogger.success('Firebase přihlášení úspěšné! UID: ${userCred.user!.uid}');

      // Vytvoření nebo aktualizace dokumentu v Firestore (pokud neexistuje)
      final String uid = userCred.user!.uid;
      final DocumentReference<Map<String, dynamic>> userDoc = _firestore.collection('users').doc(uid);
      final docSnap = await userDoc.get();
      if (!docSnap.exists) {
        AppLogger.debug('Vytvářím nový uživatelský dokument');
        await userDoc.set({
          'email': userCred.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'role': 'client', // DŮLEŽITÉ: defaultní role
        }, SetOptions(merge: true));
      } else {
        AppLogger.debug('Uživatelský dokument už existuje');
      }

      return null; // úspěch
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth Exception: ${e.code}', e);
      return _getLocalizedErrorMessage(e.code);
    } on PlatformException catch (e) {
      // Typicky: nepodporovaná platforma nebo špatná konfigurace Sign-In
      final code = e.code.toString();
      final message = e.message ?? '';
      AppLogger.error('Platform Exception: $code', e);
      return 'Platformní chyba: $code ${message.isNotEmpty ? '- ' + message : ''}';
    } catch (e) {
      AppLogger.error('Neočekávaná chyba při Google Sign-In', e);
      return 'Neočekávaná chyba: ${e.toString()}';
    }
  }

  /// Odhlášení
  Future<void> signOut() async {
    await _auth.signOut();
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
