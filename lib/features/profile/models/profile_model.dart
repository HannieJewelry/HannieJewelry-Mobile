import '../../auth/models/user_model.dart';

class Profile {
  final String? id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? birthday;
  final String? gender;
  final String? avatarUrl;
  final String? phone;
  final int points;
  final List<String>? addresses;

  Profile({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.birthday,
    this.gender,
    this.avatarUrl,
    this.phone,
    this.points = 0,
    this.addresses,
  });

  // Helper getter for full name
  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  // Helper getter for display name
  String get displayName => fullName.isNotEmpty ? fullName : email ?? 'User';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'birthday': birthday,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'points': points,
      'addresses': addresses,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    // Handle both single 'name' field and separate first_name/last_name fields
    String? fullName = map['name']?.toString();
    String? firstName = map['first_name']?.toString() ?? map['firstName']?.toString();
    String? lastName = map['last_name']?.toString() ?? map['lastName']?.toString();
    
    // If we have a single name field, split it
    if (fullName != null && fullName.isNotEmpty && firstName == null && lastName == null) {
      List<String> nameParts = fullName.split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : null;
      lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : null;
    }
    
    return Profile(
      id: map['id']?.toString(),
      email: map['email']?.toString(),
      firstName: firstName,
      lastName: lastName,
      birthday: map['birthday']?.toString() ?? map['date_of_birth']?.toString(),
      gender: map['gender']?.toString(),
      avatarUrl: map['avatar_url']?.toString() ?? map['avatarUrl']?.toString() ?? map['avatar']?.toString(),
      phone: map['phone']?.toString(),
      points: map['points']?.toInt() ?? 0,
      addresses: map['addresses'] != null 
          ? List<String>.from(map['addresses']) 
          : null,
    );
  }

  factory Profile.fromUser(User user) {
    return Profile(
      id: user.id,
      email: user.email,
      firstName: user.name?.split(' ').first,
      lastName: user.name?.split(' ').skip(1).join(' '),
      phone: user.phone,
      birthday: user.dateOfBirth,
      gender: user.gender,
      avatarUrl: user.avatarUrl,
    );
  }

  User toUser() {
    return User(
      id: id ?? '',
      name: fullName,
      phone: phone ?? '',
      email: email,
      dateOfBirth: birthday,
      gender: gender,
      avatarUrl: avatarUrl,
    );
  }
}
