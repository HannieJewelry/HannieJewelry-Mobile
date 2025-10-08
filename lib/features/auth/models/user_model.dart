class User {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? dateOfBirth;
  final String? gender;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'avatarUrl': avatarUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    // Handle both direct mapping and API response structure
    Map<String, dynamic> userData;
    if (map.containsKey('data') && map['data'] != null && map['data']['customer'] != null) {
      // API response structure: {"data": {"customer": {...}}}
      userData = map['data']['customer'];
    } else {
      // Direct user data mapping
      userData = map;
    }

    // Combine first_name and last_name into full name
    String fullName = '';
    if (userData['first_name'] != null || userData['last_name'] != null) {
      fullName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
    }
    if (fullName.isEmpty) {
      fullName = userData['name']?.toString() ?? 'User';
    }

    // Parse birthday from ISO format to simpler format
    String? birthday;
    if (userData['birthday'] != null) {
      try {
        final dateTime = DateTime.parse(userData['birthday']);
        birthday = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } catch (e) {
        birthday = userData['birthday']?.toString();
      }
    }

    return User(
      id: userData['id']?.toString() ?? '',
      name: fullName,
      phone: userData['phone']?.toString() ?? '',
      email: userData['email']?.toString(),
      dateOfBirth: birthday ?? userData['dateOfBirth']?.toString(),
      gender: userData['gender']?.toString(),
      avatarUrl: userData['avatar_url']?.toString() ?? userData['avatarUrl']?.toString(),
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}