import 'package:equatable/equatable.dart';

class BusinessModel extends Equatable {
  final String id;
  final String slug;
  final String name;
  final String? logo;
  final String timezone;

  const BusinessModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.logo,
    required this.timezone,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) => BusinessModel(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: json['name'] as String,
        logo: json['logo'] as String?,
        timezone: json['timezone'] as String? ?? 'America/Sao_Paulo',
      );

  @override
  List<Object?> get props => [id, slug, name, logo, timezone];
}
