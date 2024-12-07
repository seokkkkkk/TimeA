const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const dayjs = require("dayjs");

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

        const { uploadedAt, canUnlockedAt, userId, title } = capsule;

        if (!uploadedAt || !canUnlockedAt || !userId || !title) {
            console.error("캡슐 데이터가 올바르지 않습니다");
            console.error(capsule);
            return;
        }

        const canUnlockDate = canUnlockedAt.toDate();
        const dayBeforeDate = new Date(canUnlockDate);
        dayBeforeDate.setDate(dayBeforeDate.getDate() - 1);
        dayBeforeDate.setUTCHours(21, 0, 0, 0);

        const now = new Date();
        const uploaded = uploadedAt.toDate();
        const start = new Date(
            now.getFullYear(),
            now.getMonth(),
            now.getDate()
        );
        const end = new Date(
            uploaded.getFullYear(),
            uploaded.getMonth(),
            uploaded.getDate()
        );

        const diffInDays = Math.ceil((start - end) / (1000 * 60 * 60 * 24));

        const notifications = [];

        if (diffInDays > 0) {
            notifications.push({
                sendAt: Timestamp.fromDate(dayBeforeDate),
                userId,
                capsuleId: event.params.capsuleId,
                title: "D-1, 내일 추억이 돌아옵니다!",
                message: `두근두근 ${diffInDays}일 전 남겨진 당신의 기억이 돌아옵니다 💌`,
                reading: false,
            });
        }

        notifications.push({
            sendAt: Timestamp.fromDate(canUnlockDate),
            userId,
            capsuleId: event.params.capsuleId,
            title: "D-Day! 추억을 만나러 가볼까요?",
            message: `당신의 기억이 돌아왔습니다 🎉 추억의 장소에 방문하여 기억 캡슐을 열어보세요! - ${title} [${dayjs(
                uploadedAt.toDate()
            ).format("YYYY-MM-DD")}]`,
            reading: false,
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

        const { sendAt, userId, title, message } = notification;

        const delay = sendAt.toDate().getTime() - Date.now();

        if (delay > 0) {
            console.log("푸시 알림 발송 예정:", delay);
            setTimeout(async () => {
                try {
                    const userDoc = await db
                        .collection("users")
                        .doc(userId)
                        .get();
                    const fcmToken = userDoc.data().fcmToken;

                    console.log("fcmToken:", fcmToken);

                    if (fcmToken) {
                        await getMessaging().send({
                            token: fcmToken,
                            notification: {
                                title: title,
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
