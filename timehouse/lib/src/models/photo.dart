class Photo {
  final String id;
  final String userId;
  final String url;
  final String thumbnailUrl;
  final String fileName;
  final int size;
  final String contentType;
  final String? hash;
  final DateTime takenAt;
  final DateTime uploadedAt;
  final String location;
  final List<String> tags;

  Photo({
    required this.id,
    required this.userId,
    required this.url,
    required this.thumbnailUrl,
    required this.fileName,
    required this.size,
    required this.contentType,
    this.hash,
    required this.takenAt,
    required this.uploadedAt,
    required this.location,
    required this.tags,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      userId: json['userId'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
      fileName: json['fileName'],
      size: json['size'],
      contentType: json['contentType'],
      hash: json['hash'],
      takenAt: DateTime.parse(json['takenAt']),
      uploadedAt: DateTime.parse(json['createdAt']),
      location: json['location'],
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'size': size,
      'contentType': contentType,
      'hash': hash,
      'takenAt': takenAt.toIso8601String(),
      'uploadedAt': uploadedAt.toIso8601String(),
      'location': location,
      'tags': tags,
    };
  }
}
