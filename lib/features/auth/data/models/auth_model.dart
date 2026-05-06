enum UserRole { client, merchant, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    return UserModel(
      id: idValue?.toString() ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: _parseRole(json['role']),
    );
  }

  static UserRole _parseRole(dynamic role) {
    final roleStr = role?.toString().toUpperCase();
    switch (roleStr) {
      case 'MERCHANT':
        return UserRole.merchant;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.client;
    }
  }

  String get roleString {
    switch (role) {
      case UserRole.merchant:
        return 'MERCHANT';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.client:
        return 'CLIENT';
    }
  }

  bool get isMerchant => role == UserRole.merchant;
  bool get isClient => role == UserRole.client;
}

class AuthResponse {
  final UserModel user;
  final String accessToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] ?? {}),
      accessToken: json['access_token'] ?? '',
    );
  }
}