class AlbumImages 
{
  final String large;
  final String medium;
  final String small;

  AlbumImages({
    required this.large,
    required this.medium,
    required this.small,
  });

  factory AlbumImages.fromMap(Map<String, dynamic> map) 
  {
    return AlbumImages(
      large: map['large'] as String? ?? '',
      medium: map['medium'] as String? ?? '',
      small: map['small'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() 
  {
    return {
      'large': large,
      'medium': medium,
      'small': small,
    };
  }

  String get primary => large.isNotEmpty ? large : (medium.isNotEmpty ? medium : small);
}
