class Address {
  final String id;
  final String address1;
  final String? address2;
  final String? city;
  final String? company;
  final String? countryCode;
  final String? districtCode;
  final String firstName;
  final bool isDefault;
  final String lastName;
  final String name;
  final String phone;
  final String? provinceCode;
  final String? wardCode;
  final String? zip;
  
  // Additional fields for full address display
  final String? _district;
  final String? _province;
  final String? _ward;

  Address({
    required this.id,
    required this.address1,
    this.address2,
    this.city,
    this.company,
    this.countryCode,
    this.districtCode,
    required this.firstName,
    required this.isDefault,
    required this.lastName,
    required this.name,
    required this.phone,
    this.provinceCode,
    this.wardCode,
    this.zip,
    String? district,
    String? province,
    String? ward,
  }) : _district = district,
       _province = province,
       _ward = ward;

  String get fullAddress {
    final addressParts = <String>[];
    if (address1.isNotEmpty) addressParts.add(address1);
    if (address2 != null && address2!.isNotEmpty) addressParts.add(address2!);
    
    // Get ward and province only (skip district)
    final locationParts = <String>[];
    if (_ward != null && _ward!.isNotEmpty) locationParts.add(_ward!);
    if (_province != null && _province!.isNotEmpty) locationParts.add(_province!);
    
    final allParts = [...addressParts, ...locationParts];
    return allParts.join(', ');
  }

  String get fullName {
    // Vietnamese name format: lastName + firstName
    final parts = <String>[];
    if (lastName.isNotEmpty) parts.add(lastName);
    if (firstName.isNotEmpty) parts.add(firstName);
    return parts.join(' ');
  }

  Address copyWith({
    String? id,
    String? address1,
    String? address2,
    String? city,
    String? company,
    String? countryCode,
    String? districtCode,
    String? firstName,
    bool? isDefault,
    String? lastName,
    String? name,
    String? phone,
    String? provinceCode,
    String? wardCode,
    String? zip,
    String? district,
    String? province,
    String? ward,
  }) {
    return Address(
      id: id ?? this.id,
      address1: address1 ?? this.address1,
      address2: address2 ?? this.address2,
      city: city ?? this.city,
      company: company ?? this.company,
      countryCode: countryCode ?? this.countryCode,
      districtCode: districtCode ?? this.districtCode,
      firstName: firstName ?? this.firstName,
      isDefault: isDefault ?? this.isDefault,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      provinceCode: provinceCode ?? this.provinceCode,
      wardCode: wardCode ?? this.wardCode,
      zip: zip ?? this.zip,
      district: district ?? _district,
      province: province ?? _province,
      ward: ward ?? _ward,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address1': address1,
      'address2': address2,
      'city': city,
      'company': company,
      'country_code': countryCode,
      'district_code': districtCode,
      'first_name': firstName,
      'default': isDefault,
      'last_name': lastName,
      'name': name,
      'phone': phone,
      'province_code': provinceCode,
      'ward_code': wardCode,
      'zip': zip,
    };
  }

  // For creating a new address
  Map<String, dynamic> toCreateMap() {
    return {
      'address': {
        'address1': address1,
        'address2': address2,
        'city': city,
        'company': company,
        'country_code': countryCode,
        'district_code': districtCode,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'province_code': provinceCode,
        'ward_code': wardCode,
        'zip': zip,
      }
    };
  }
  
  // For updating an address (same format as create)
  Map<String, dynamic> toUpdateMap() {
    return toCreateMap();
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'],
      city: map['city'],
      company: map['company'],
      countryCode: map['country_code'],
      districtCode: map['district_code'],
      firstName: map['first_name'] ?? '',
      isDefault: map['default'] ?? false,
      lastName: map['last_name'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      provinceCode: map['province_code'],
      wardCode: map['ward_code'],
      zip: map['zip'],
      district: map['district'],
      province: map['province'],
      ward: map['ward'],
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, name: $name, firstName: $firstName, lastName: $lastName, phone: $phone, address1: $address1, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
