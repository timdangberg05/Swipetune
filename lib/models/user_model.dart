class SpotifyUser
{
  final String id;    
  final String displayName;        
  final String email;
  final String? imageUrl;
  final String country;
  final String? product;             
  final int? followerCount;
  
  SpotifyUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.imageUrl,
    required this.country,
    this.product,
    this.followerCount,
  });
  
  factory SpotifyUser.fromMap(Map<String, dynamic> map)
  {
    return SpotifyUser(
      id: map['id'] ?? '',                             
      displayName: map['display_name'] ?? 'User',     
      email: map['email'] ?? '',
      imageUrl: (map['images'] as List?)?.isNotEmpty == true 
          ? map['images'][0]['url'] 
          : null,
      country: map['country'] ?? '',
      product: map['product'],                  
      followerCount: map['followers']?['total'], 
    );
  }
}
