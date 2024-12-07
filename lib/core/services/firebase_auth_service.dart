import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:timea/core/services/FCM_service.dart';

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

    final userCredential = await _auth.signInWithCredential(credential);

    // FCM 토큰 업데이트
    await updateFCMToken(userCredential.user!.uid);

    return userCredential;
  }

  // 익명 로그인
  Future<UserCredential> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();

    // FCM 토큰 업데이트
    await updateFCMToken(userCredential.user!.uid);

    return userCredential;
  }

  // Firestore에서 사용자 정보 조회
  Future<DocumentSnapshot> getUserFromFirestore(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc;
  }

  // Firestore에 사용자 정보 저장
  static Future<void> saveUserToFirestore(
      User user, String nickname, String profileImage) async {
    String? token = await FCMService().getToken();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'nickname': nickname,
      'profileImage': profileImage,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deletedAt': null,
      'fcmToken': token,
    });
  }

  // 로그아웃
  Future<void> logout() async {
    final user = _auth.currentUser;

    if (user != null) {
      // Firestore에서 FCM 토큰 제거
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': null});
    }

    await _auth.signOut();
  }

  // 현재 유저 가져오기
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Firestore에 FCM 토큰 업데이트
  Future<void> updateFCMToken(String userId) async {
    final newToken = await FCMService().getToken();
    if (newToken == null) {
      return;
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      final currentToken = userSnapshot.data()?['fcmToken'];

      if (currentToken != newToken) {
        await userDoc.update({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {}
    } else {}
  }
}
