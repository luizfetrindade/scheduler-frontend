import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((r) => (r as Map<String, dynamic>)['name'] as String)
            .toList(),
      );

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => [id, name, email, roles];
}
