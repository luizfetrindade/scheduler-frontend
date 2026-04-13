import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((r) => (r as Map<String, dynamic>)['name'] as String)
            .toList(),
      );

  static const _sentinel = Object();

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    Object? phone = _sentinel,
    List<String>? roles,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone == _sentinel ? this.phone : phone as String?,
        roles: roles ?? this.roles,
      );

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => [id, name, email, phone, roles];
}
