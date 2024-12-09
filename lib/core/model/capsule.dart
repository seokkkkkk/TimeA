import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timea/core/utils/format_util.dart';

class Capsule {
  final String id; // 문서 ID
  final String title;
  final String content;
  final String? imageUrl;
  final List<String> sharedWith;
  final DateTime canUnlockedAt;
  final DateTime? unlockedAt;
  final DateTime uploadedAt;
  final String userId;
  final GeoPoint location;

  Capsule({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.sharedWith,
    required this.canUnlockedAt,
    this.unlockedAt,
    required this.uploadedAt,
    required this.userId,
    required this.location,
  });

  // JSON 데이터를 모델로 변환
  factory Capsule.fromJson(String id, Map<String, dynamic> json) {
    return Capsule(
      id: id,
      title: json['fields']['title']?['stringValue'] ?? '',
      content: json['fields']['content']?['stringValue'] ?? '',
      imageUrl: json['fields']['imageUrl']?['stringValue'],
      sharedWith: (json['fields']['sharedWith']?['arrayValue']?['values'] ?? [])
          .map<String>((item) => item['stringValue'] as String)
          .toList(),
      canUnlockedAt: json['fields']['canUnlockedAt']?['timestampValue'] != null
          ? DateTime.parse(json['fields']['canUnlockedAt']['timestampValue'])
              .toUtc()
          : DateTime.now().toUtc(),
      unlockedAt: json['fields']['unlockedAt']?['timestampValue'] != null
          ? DateTime.parse(json['fields']['unlockedAt']['timestampValue'])
              .toUtc()
          : null,
      uploadedAt: json['fields']['uploadedAt']?['timestampValue'] != null
          ? DateTime.parse(json['fields']['uploadedAt']['timestampValue'])
              .toUtc()
          : DateTime.now().toUtc(),
      userId: json['fields']['userId']?['stringValue'] ?? '',
      location: GeoPoint(
        json['fields']['location']?['geoPointValue']?['latitude'] as double? ??
            0.0,
        json['fields']['location']?['geoPointValue']?['longitude'] as double? ??
            0.0,
      ),
    );
  }

  // 모델을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      "title": {"stringValue": title},
      "content": {"stringValue": content},
      "imageUrl":
          imageUrl != null ? {"stringValue": imageUrl} : {"nullValue": null},
      "sharedWith": {
        "arrayValue": {
          "values": sharedWith.map((item) => {"stringValue": item}).toList(),
        },
      },
      "canUnlockedAt": {
        "timestampValue": FormatUtil.formatTimestamp(canUnlockedAt)
      },
      "unlockedAt": unlockedAt != null
          ? {"timestampValue": FormatUtil.formatTimestamp(unlockedAt!)}
          : {"nullValue": null},
      "uploadedAt": {"timestampValue": FormatUtil.formatTimestamp(uploadedAt)},
      "userId": {"stringValue": userId},
      "location": {
        "geoPointValue": {
          "latitude": location.latitude,
          "longitude": location.longitude,
        },
      },
    };
  }
}
