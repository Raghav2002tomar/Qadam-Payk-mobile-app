class City {
  final int id;
  final String cityName;
  final String? state;
  final String? country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  City({
    required this.id,
    required this.cityName,
    this.state,
    this.country,
    this.createdAt,
    this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      cityName: json['city_name'],
      state: json['state'],
      country: json['country'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}
