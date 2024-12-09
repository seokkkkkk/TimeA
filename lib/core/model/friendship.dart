import 'package:timea/core/utils/format_util.dart';

class Friendship {
  final String id; // 문서 ID
  final String status;
  final String userId1;
  final String userId2;
  final DateTime createdAt;
  final DateTime updatedAt;

  Friendship({
    required this.id,
    required this.status,
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON 데이터를 Friendship 모델로 변환
  factory Friendship.fromJson(String id, Map<String, dynamic> json) {
    return Friendship(
      id: id,
      status: json['fields']['status']['stringValue'] ?? '',
      userId1: json['fields']['userId1']['stringValue'] ?? '',
      userId2: json['fields']['userId2']['stringValue'] ?? '',
      createdAt: DateTime.parse(json['fields']['createdAt']['timestampValue']),
      updatedAt: DateTime.parse(json['fields']['updatedAt']['timestampValue']),
    );
  }

  // Friendship 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      "status": {"stringValue": status},
      "userId1": {"stringValue": userId1},
      "userId2": {"stringValue": userId2},
      "createdAt": {"timestampValue": FormatUtil.formatTimestamp(createdAt)},
      "updatedAt": {"timestampValue": FormatUtil.formatTimestamp(updatedAt)},
    };
  }
}
