const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
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

        const { uploadedAt, canUnlockedAt, userId, title, sharedWith } =
            capsule;

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

        const batch = db.batch();
        const notifications = [];
        const recipients = [userId, ...(sharedWith || [])]; // 공유된 사용자 포함

        recipients.forEach((recipientId) => {
            // 공유 알림 (sharedWith만 해당)
            if (recipientId !== userId) {
                notifications.push({
                    sendAt: Timestamp.fromDate(new Date()), // 즉시 전송
                    userId: recipientId,
                    capsuleId: event.params.capsuleId,
                    title: "새로운 추억이 공유되었습니다!",
                    message: `📢 공유받은 캡슐을 확인해보세요! - ${title}`,
                    reading: false,
                });
            }

            // D-1 알림
            if (diffInDays > 0) {
                notifications.push({
                    sendAt: Timestamp.fromDate(dayBeforeDate),
                    userId: recipientId,
                    capsuleId: event.params.capsuleId,
                    title: "D-1, 내일 추억이 돌아옵니다!",
                    message: `두근두근 ${diffInDays}일 전 남겨진 기억이 돌아옵니다 💌`,
                    reading: false,
                });
            }

            // D-Day 알림
            notifications.push({
                sendAt: Timestamp.fromDate(canUnlockDate),
                userId: recipientId,
                capsuleId: event.params.capsuleId,
                title: "D-Day! 추억을 만나러 가볼까요?",
                message: `당신의 기억이 돌아왔습니다 🎉 - ${title} [${dayjs(
                    uploadedAt.toDate()
                ).format("YYYY-MM-DD")}]`,
                reading: false,
            });
        });

        // Firestore batch 추가
        notifications.forEach((notification) => {
            const notificationRef = db.collection("notifications").doc();
            batch.set(notificationRef, notification);
        });

        await batch.commit();
        console.log(
            `캡슐 알림 생성 완료: ${event.params.capsuleId} (대상 사용자 ${recipients.length}명)`
        );
    }
);

// Cloud Function: friendships 문서 생성 시 알림 생성
exports.onFriendRequestSent = onDocumentCreated(
    "friendships/{friendshipId}",
    async (event) => {
        const friendship = event.data.data();

        if (!friendship || friendship.status !== "pending") {
            return;
        }

        const { userId1, userId2 } = friendship;

        // 알림 문서 생성
        const notificationRef = db.collection("notifications").doc();

        const senderDoc = await db.collection("users").doc(userId1).get();
        const senderName = senderDoc.data().nickname;

        await notificationRef.set({
            sendAt: Timestamp.now(),
            userId: userId2, // 수신자
            friendshipId: event.params.friendshipId,
            title: "친구 요청 도착! 💌",
            message: `${senderName}님으로부터 친구 요청이 도착했습니다.`,
            reading: false,
        });

        // FCM 발송
        const userDoc = await db.collection("users").doc(userId2).get();
        const fcmToken = userDoc.data().fcmToken;

        if (fcmToken) {
            await getMessaging().send({
                token: fcmToken,
                notification: {
                    title: "친구 요청 도착! 💌",
                    body: `${senderName}님으로부터 친구 요청이 도착했습니다. 친구 요청을 확인해보세요!`,
                },
            });
        }
    }
);

// Cloud Function: friendships 문서 업데이트 시 알림 생성
exports.onFriendRequestAccepted = onDocumentUpdated(
    "friendships/{friendshipId}",
    async (event) => {
        const beforeData = event.data.before.data();
        const afterData = event.data.after.data();

        if (
            beforeData.status !== "accepted" &&
            afterData.status === "accepted"
        ) {
            const { userId1, userId2 } = afterData;

            const notificationRef = db.collection("notifications").doc();

            const senderDoc = await db.collection("users").doc(userId2).get();
            const senderName = senderDoc.data().nickname;

            // 알림 문서 생성
            await notificationRef.set({
                sendAt: Timestamp.now(),
                userId: userId1, // 친구 요청을 보낸 사용자에게 알림
                friendshipId: event.params.friendshipId,
                title: "친구 요청 수락됨! 🎉",
                message: `${senderName}님이 친구 요청을 수락했습니다. 친구와 함께 추억을 공유해보세요!`,
                reading: false,
            });

            // FCM 발송
            const userDoc = await db.collection("users").doc(userId1).get();
            const fcmToken = userDoc.data().fcmToken;

            if (fcmToken) {
                await getMessaging().send({
                    token: fcmToken,
                    notification: {
                        title: "친구 요청 수락됨! 🎉",
                        body: `${senderName}님이 친구 요청을 수락했습니다. 친구와 함께 추억을 공유해보세요!`,
                    },
                });
            }
        }
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
