import 'package:equatable/equatable.dart';

class RoadIncident extends Equatable {
  final String id;
  final String type;
  final String title;
  final String authorEmail;
  final double lat;
  final double lng;
  final String routeName;
  final DateTime createdAt;

  const RoadIncident({
    required this.id,
    required this.type,
    required this.title,
    required this.authorEmail,
    required this.lat,
    required this.lng,
    required this.routeName,
    required this.createdAt,
  });

  factory RoadIncident.fromMap(Map<String, dynamic> map, String docId) {
    return RoadIncident(
      id: docId,
      type: map['type'] ?? 'hazard',
      title: map['title'] ?? 'Yol Olayı',
      authorEmail: map['authorEmail'] ?? 'Anonim',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      routeName: map['routeName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'authorEmail': authorEmail,
      'lat': lat,
      'lng': lng,
      'routeName': routeName,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        authorEmail,
        lat,
        lng,
        routeName,
        createdAt,
      ];
}
