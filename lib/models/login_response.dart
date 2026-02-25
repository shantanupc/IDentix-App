class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String role;
  final String? userId;
  final String? verifierId;
  final String name;

  LoginData({
    required this.role,
    this.userId,
    this.verifierId,
    required this.name,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      role: json['role'] ?? '',
      userId: json['user_id'],
      verifierId: json['verifier_id'],
      name: json['name'] ?? '',
    );
  }

  String get id => userId ?? verifierId ?? '';
}
