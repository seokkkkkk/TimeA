const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// Cloud Function: Capsules 문서 생성 시 알림 생성
exports.createNotification = onDocumentCreated(
    "capsules/{capsuleId}",
    async (event) => {
        const capsule = event.data.data();

        if (!capsule) {
            console.error("해당하는 캡슐 데이터가 없습니다");
            return;
        }

        const { canUnlockedAt, userId, title } = capsule;

        if (!canUnlockedAt || !userId || !title) {
            console.error("캡슐 데이터가 올바르지 않습니다");
            console.error(capsule);
            return;
        }

        const canUnlockDate = canUnlockedAt.toDate();
        const dayBeforeDate = new Date(canUnlockDate);
        dayBeforeDate.setDate(dayBeforeDate.getDate() - 1);
        dayBeforeDate.setUTCHours(21, 0, 0, 0);

        const today = new Date();
        const diffInMs = canUnlockDate - today;
        const diffInDays = Math.ceil(diffInMs / (1000 * 60 * 60 * 24));

        const notifications = [];

        notifications.push({
            sendAt: Timestamp.fromDate(dayBeforeDate),
            userId,
            capsuleId: event.params.capsuleId,
            message: `두근두근 ${diffInDays}일 전 남겨진 당신의 기억이 돌아옵니다 💌`,
        });

        notifications.push({
            sendAt: Timestamp.fromDate(canUnlockDate),
            userId,
            capsuleId: event.params.capsuleId,
            message: `당신의 기억이 돌아왔습니다 🎉 ${title}`,
        });

        const batch = db.batch();
        notifications.forEach((notification) => {
            const notificationRef = db.collection("notifications").doc();
            batch.set(notificationRef, notification);
        });

        await batch.commit();
        console.log(
            `캡슐 알림 생성 완료: ${event.params.capsuleId} (${diffInDays}일)`
        );
    }
);

// Cloud Function: 알림 문서 생성 시 푸시 알림 발송
exports.sendNotification = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
        const notification = event.data.data();

        if (!notification) {
            console.error("해당하는 알림 데이터가 없습니다");
            return;
        }

        const { sendAt, userId, message } = notification;

        const delay = sendAt.toDate().getTime() - Date.now();

        if (delay > 0) {
            setTimeout(async () => {
                try {
                    const userDoc = await db
                        .collection("users")
                        .doc(userId)
                        .get();
                    const fcmToken = userDoc.data().fcmToken;

                    if (fcmToken) {
                        await getMessaging().send({
                            token: fcmToken,
                            notification: {
                                title: "Time& 알림",
                                body: message,
                            },
                        });
                        console.log("알림 생성 완료:", message);
                    } else {
                        console.error(
                            "해당하는 사용자의 FCM 토큰이 없습니다:",
                            userId
                        );
                    }
                } catch (error) {
                    console.error(
                        "푸시 알림 발송 중 오류 발생:",
                        error.message
                    );
                }
            }, delay);
        }
    }
);
