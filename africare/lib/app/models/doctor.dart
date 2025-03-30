class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String experience;
  final String about;
  final List<String> availableDays;
  final double consultationFee;
  final bool isAvailableForOnline;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.about,
    required this.availableDays,
    required this.consultationFee,
    required this.isAvailableForOnline,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      name: json['name'] as String,
      specialization: json['specialization'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      experience: json['experience'] as String,
      about: json['about'] as String,
      availableDays: List<String>.from(json['availableDays']),
      consultationFee: (json['consultationFee'] as num).toDouble(),
      isAvailableForOnline: json['isAvailableForOnline'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'experience': experience,
      'about': about,
      'availableDays': availableDays,
      'consultationFee': consultationFee,
      'isAvailableForOnline': isAvailableForOnline,
    };
  }
}
