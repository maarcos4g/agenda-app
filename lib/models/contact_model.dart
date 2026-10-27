class ContactModel {
  final String name;
  final String email;
  final String phone;
  final bool? isFavorite;
  final String? imagePath;
  final String? notes;
  final List<String> categories;
  final List<String> groups;
  final String? birthDate; // formato: 'YYYY-MM-DD'
  final String? city;
  final String? company;
  final String? createdAt; // formato ISO 8601

  ContactModel({
    required this.name,
    required this.email,
    required this.phone,
    this.isFavorite,
    this.imagePath,
    this.notes,
    this.categories = const [],
    this.groups = const [],
    this.birthDate,
    this.city,
    this.company,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'isFavorite': isFavorite ?? false,
      'imagePath': imagePath ?? '',
      'notes': notes ?? '',
      'categories': categories,
      'groups': groups,
      'birthDate': birthDate ?? '',
      'city': city ?? '',
      'company': company ?? '',
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
      imagePath: map['imagePath'] ?? '',
      notes: map['notes'] ?? '',
      categories: map['categories'] != null
          ? List<String>.from(map['categories'])
          : [],
      groups: map['groups'] != null
          ? List<String>.from(map['groups'])
          : [],
      birthDate: map['birthDate'] ?? '',
      city: map['city'] ?? '',
      company: map['company'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }

  ContactModel copyWith({
    String? name,
    String? email,
    String? phone,
    bool? isFavorite,
    String? imagePath,
    String? notes,
    List<String>? categories,
    List<String>? groups,
    String? birthDate,
    String? city,
    String? company,
    String? createdAt,
  }) {
    return ContactModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isFavorite: isFavorite ?? this.isFavorite,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      categories: categories ?? this.categories,
      groups: groups ?? this.groups,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      company: company ?? this.company,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}