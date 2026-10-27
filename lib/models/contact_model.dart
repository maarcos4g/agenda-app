class ContactModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool? isFavorite;
  final String? imagePath;

  ContactModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.isFavorite,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isFavorite': isFavorite ?? false,
      'imagePath': imagePath ?? '',
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      imagePath: map['imagePath'] ?? '',
    );
  }

  ContactModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? isFavorite,
    String? imagePath,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}