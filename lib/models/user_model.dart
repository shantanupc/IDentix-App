class UserModel {
  final String userId;
  final String username;
  final String name;
  final int age;
  final String idType;
  final String idNumber;
  final Map<String, dynamic>? additionalAttributes;
  final String role;

  UserModel({
    required this.userId,
    required this.username,
    required this.name,
    required this.age,
    required this.idType,
    required this.idNumber,
    this.additionalAttributes,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      idType: json['id_type'] ?? '',
      idNumber: json['id_number'] ?? '',
      additionalAttributes: json['additional_attributes'],
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'name': name,
      'age': age,
      'id_type': idType,
      'id_number': idNumber,
      'additional_attributes': additionalAttributes,
      'role': role,
    };
  }
}
