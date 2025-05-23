import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/users/auth.dart';
import 'package:calljmp/http.dart' as http;

class User {
  final int id;
  final String? email;
  final String? name;
  final String? avatar;
  final List<String>? tags;
  final DateTime createdAt;

  User({
    required this.id,
    this.email,
    this.name,
    this.avatar,
    this.tags,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String?,
      name: json['name'] as String?,
      avatar: json['avatar'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, avatar: $avatar, tags: $tags, createdAt: $createdAt}';
  }
}

class Users {
  final Config _config;
  final Auth auth;

  Users(this._config, Attestation attestation)
    : auth = Auth(_config, attestation);

  Future<User> retrieve() => http
      .request("${_config.serviceUrl}/users")
      .use(http.context(_config))
      .use(http.access())
      .get()
      .json((json) => User.fromJson(json));
}
