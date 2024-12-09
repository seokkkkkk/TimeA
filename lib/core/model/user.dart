import 'package:timea/core/utils/format_util.dart';

class UserModel {
  final String id; // 문서 ID
  final String nickname;
  final String profileImage;
  final String fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.nickname,
    required this.profileImage,
    required this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // JSON 데이터를 User 모델로 변환
  factory UserModel.fromJson(String id, Map<String, dynamic> json) {
    return UserModel(
      id: id,
      nickname: json['fields']['nickname']['stringValue'] ?? '',
      profileImage: json['fields']['profileImage']['stringValue'] ?? '',
      fcmToken: json['fields']['fcmToken']['stringValue'] ?? '',
      createdAt: DateTime.parse(json['fields']['createdAt']['timestampValue']),
      updatedAt: DateTime.parse(json['fields']['updatedAt']['timestampValue']),
      deletedAt: json['fields']['deletedAt']['nullValue'] == null
          ? null
          : DateTime.parse(json['fields']['deletedAt']['timestampValue']),
    );
  }

  // User 객체를 JSON으로 변환 (업로드 시 사용)
  Map<String, dynamic> toJson() {
    return {
      "nickname": {"stringValue": nickname},
      "profileImage": {"stringValue": profileImage},
      "fcmToken": {"stringValue": fcmToken},
      "createdAt": {"timestampValue": FormatUtil.formatTimestamp(createdAt)},
      "updatedAt": {"timestampValue": FormatUtil.formatTimestamp(updatedAt)},
      "deletedAt": deletedAt != null
          ? {"timestampValue": FormatUtil.formatTimestamp(deletedAt!)}
          : {"nullValue": null},
    };
  }
}
