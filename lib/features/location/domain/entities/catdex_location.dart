class CatDexLocation {
  const CatDexLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.region,
    this.country,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? region;
  final String? country;

  bool get hasPlaceDetails {
    return city != null || region != null || country != null;
  }

  String get displayLabel {
    final parts = [city, region, country]
        .where((part) => part != null && part.trim().isNotEmpty)
        .cast<String>()
        .toList();

    if (parts.isEmpty) {
      return 'Coordinates only';
    }

    return parts.join(', ');
  }
}
