import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final notifications = <Map<String, dynamic>>[].obs;
  var notificationCount = 0.obs; // 읽지 않은 알림 수

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    _getUnreadNotificationCount();
  }

  void fetchNotifications() {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      notifications.value = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // 문서 ID 추가
        return data;
      }).toList();
    });
  }

  // 알림 읽음 상태로 변경
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'reading': true});
  }

  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  void _getUnreadNotificationCount() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('reading', isEqualTo: false) // 읽지 않은 알림만
        .snapshots()
        .listen((snapshot) {
      notificationCount.value = snapshot.docs.length;
    });
  }
}
