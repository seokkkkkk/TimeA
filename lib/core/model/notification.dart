import 'package:timea/core/utils/format_util.dart';

class Notification {
  final String id; // 문서 ID
  final String message;
  final bool reading;
  final DateTime sendAt;
  final String title;
  final String userId;

  Notification({
    required this.id,
    required this.message,
    required this.reading,
    required this.sendAt,
    required this.title,
    required this.userId,
  });

  // JSON 데이터를 Notification 모델로 변환
  factory Notification.fromJson(String id, Map<String, dynamic> json) {
    return Notification(
      id: id,
      message: json['fields']['message']['stringValue'] ?? '',
      reading: json['fields']['reading']['booleanValue'] ?? false,
      sendAt: DateTime.parse(json['fields']['sendAt']['timestampValue']),
      title: json['fields']['title']['stringValue'] ?? '',
      userId: json['fields']['userId']['stringValue'] ?? '',
    );
  }

  // Notification 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      "message": {"stringValue": message},
      "reading": {"booleanValue": reading},
      "sendAt": {"timestampValue": FormatUtil.formatTimestamp(sendAt)},
      "title": {"stringValue": title},
      "userId": {"stringValue": userId},
    };
  }
}
