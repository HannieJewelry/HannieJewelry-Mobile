class ProductType {
  final String id;
  final String name;
  final String? handle;
  final String? image;

  ProductType({
    required this.id,
    required this.name,
    this.handle,
    this.image,
  });

  factory ProductType.fromMap(Map<String, dynamic> map) {
    return ProductType(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      handle: map['handle']?.toString(),
      image: map['image']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'image': image,
    };
  }

  @override
  String toString() {
    return 'ProductType(id: $id, name: $name, handle: $handle, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductType &&
        other.id == id &&
        other.name == name &&
        other.handle == handle &&
        other.image == image;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ handle.hashCode ^ image.hashCode;
  }
}
