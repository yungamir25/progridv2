// models/tower.dart
class Tower {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  String progress; // Remove 'final' to make it mutable
  final String address;
  final String region;
  final String type;
  final List<Map<String, dynamic>> feedbacks;

  Tower({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.progress, // Update constructor
    required this.address,
    required this.region,
    required this.type,
    required this.feedbacks,
  });

  // Convert Tower object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'progress': progress,
      'address': address,
      'region': region,
      'type': type,
      'feedbacks': feedbacks,
    };
  }

  // Create a Tower object from a Map
  factory Tower.fromMap(Map<String, dynamic> map) {
    return Tower(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      progress: map['progress'] ?? '',
      address: map['address'] ?? '',
      region: map['region'] ?? '',
      type: map['type'] ?? '',
      feedbacks: List<Map<String, dynamic>>.from(map['feedbacks'] ?? []),
    );
  }
}