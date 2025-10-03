class ItemModel {
  final int id;
  final String title;
  final String description;
  final double pricePerDay;
  final String pickupLocation;
  final List<String> imageUrls;
  final String category;
  final double latitude;
  final double longitude;
  final double securityDeposit;
  final String ownerName;
  final DateTime createdAt;
  final String condition;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pricePerDay,
    required this.category,
    required this.pickupLocation,
    required this.imageUrls,
    required this.securityDeposit,
    required this.latitude,
    required this.longitude,
    required this.ownerName,
    required this.createdAt,
    required this.condition,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];

    if (json['imageUrls'] != null) {
      if (json['imageUrls'] is String) {
        parsedImages = (json['imageUrls'] as String)
            .split(',')
            .map((e) => e.trim().replaceAll('\\', '/'))
            .toList();
      } else if (json['imageUrls'] is List) {
        parsedImages = List<String>.from(json['imageUrls'])
            .map((e) => e.replaceAll('\\', '/'))
            .toList();
      }
    }

    // ✅ Match the exact JSON key from backend
    String ownerName = '';
    if (json['OwnerName'] != null) {
      ownerName = json['OwnerName'];
    } else if (json['owner'] != null) {
      ownerName = json['owner']['name'] ?? '';
    }

    return ItemModel(
      id: json['id'] as int,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      securityDeposit: (json['securityDeposit'] as num?)?.toDouble() ?? 0.0,
      pickupLocation: json['pickupLocation'] ?? '',
      ownerName: ownerName,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrls: parsedImages,
    );
  }
}
