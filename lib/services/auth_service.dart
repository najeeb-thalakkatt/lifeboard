import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:lifeboard/core/errors/app_exceptions.dart';
import 'package:lifeboard/models/user_model.dart';

/// Wraps Firebase Auth and creates Firestore user docs on first sign-up.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  // ── Email/Password ─────────────────────────────────────────

  /// Creates a new account with email/password and a Firestore user doc.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    await _createUserDoc(credential.user!, displayName: displayName);
    return credential;
  }

  /// Signs in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ── Google Sign-In ─────────────────────────────────────────

  /// Signs in with Google. Creates Firestore doc on first login.
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    final GoogleSignInAccount account;
    try {
      account = await googleSignIn.authenticate();
    } on GoogleSignInException {
      throw const AuthCancelledException();
    }

    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final userCredential = await _auth.signInWithCredential(credential);
    await _createUserDocIfNeeded(userCredential.user!);
    return userCredential;
  }

  // ── Apple Sign-In ──────────────────────────────────────────

  /// Signs in with Apple. Creates Firestore doc on first login.
  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only returns the name on the very first sign-in.
    final appleName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((n) => n != null && n.isNotEmpty).join(' ');

    if (appleName.isNotEmpty) {
      await userCredential.user!.updateDisplayName(appleName);
    }

    await _createUserDocIfNeeded(
      userCredential.user!,
      displayName: appleName.isNotEmpty ? appleName : null,
    );
    return userCredential;
  }

  // ── Sign Out ───────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Firestore User Doc Helpers ─────────────────────────────

  /// Creates a Firestore user doc if one does not exist yet.
  Future<void> _createUserDocIfNeeded(
    User user, {
    String? displayName,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await _createUserDoc(user, displayName: displayName);
    }
  }

  /// Creates the initial Firestore user document.
  Future<void> _createUserDoc(
    User user, {
    String? displayName,
  }) async {
    final model = UserModel(
      id: user.uid,
      displayName: displayName ?? user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      spaceIds: [],
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(UserModel.toFirestore(model));
  }

  // ── Utilities ──────────────────────────────────────────────

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}