import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseAuth get auth => _auth;

  // Google 로그인
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in aborted');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // 익명 로그인
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Firestore에서 사용자 정보 조회
  Future<DocumentSnapshot> getUserFromFirestore(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc;
  }

  // Firestore에 사용자 정보 저장
  Future<void> saveUserToFirestore(
      User user, String nickname, String profileImage) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'nickname': nickname,
      'profileImage': profileImage,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deletedAt': null,
    });
  }

  // 로그아웃
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 현재 유저 가져오기
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}
