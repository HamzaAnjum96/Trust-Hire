/// A person who has posted work.
///
/// The POC has no accounts or authentication — users exist only to attribute
/// seeded jobs to a name, so the job details screen has something human to
/// show. Nothing here is authenticated or verified.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.area,
    this.avatarInitials,
  });

  final String id;
  final String name;

  /// A neighbourhood or area name, never a precise address.
  final String? area;

  final String? avatarInitials;

  /// Initials for the avatar placeholder, derived from the name when the seed
  /// data does not supply them.
  String get initials {
    final supplied = avatarInitials?.trim();
    if (supplied != null && supplied.isNotEmpty) return supplied;

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.firstLetter;
    return '${parts.first.firstLetter}${parts.last.firstLetter}';
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        area: json['area'] as String?,
        avatarInitials: json['avatarInitials'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'area': area,
        'avatarInitials': avatarInitials,
      };
}

extension on String {
  /// First character, uppercased — safe on empty strings.
  String get firstLetter =>
      isEmpty ? '' : substring(0, 1).toUpperCase();
}
