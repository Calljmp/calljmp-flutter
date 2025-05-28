import 'dart:convert';

import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

class Bucket {
  final int id;
  final String uuid;
  final String name;
  final String? description;
  final DateTime createdAt;

  Bucket({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Bucket.fromJson(Map<String, dynamic> json) {
    return Bucket(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Bucket{id: $id, uuid: $uuid, name: $name, description: $description, createdAt: $createdAt}';
  }
}

class BucketFile {
  final int id;
  final String key;
  final String? description;
  final List<String>? tags;
  final int bucketId;
  final String? type;
  final int size;
  final DateTime createdAt;

  BucketFile({
    required this.id,
    required this.key,
    this.description,
    this.tags,
    required this.bucketId,
    this.type,
    required this.size,
    required this.createdAt,
  });

  factory BucketFile.fromJson(Map<String, dynamic> json) {
    return BucketFile(
      id: json['id'] as int,
      key: json['key'] as String,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      bucketId: json['bucketId'] as int,
      type: json['type'] as String?,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'description': description,
      'tags': tags,
      'bucketId': bucketId,
      'type': type,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BucketFile{id: $id, key: $key, description: $description, tags: $tags, bucketId: $bucketId, type: $type, size: $size, createdAt: $createdAt}';
  }
}

class Storage {
  final Config _config;

  Storage(this._config);

  /// Uploads a file or content to a storage bucket.
  Future<BucketFile> upload({
    dynamic content,
    String? filePath,
    MediaType? contentType,
    required String bucketId,
    required String key,
    String? description,
    List<String>? tags,
    String? sha256,
    String? type,
  }) async {
    final formData = http.FormData();
    formData.addField(
      "metadata",
      jsonEncode({
        'sha256': sha256,
        'type': type,
        'description': description,
        'tags': tags,
      }),
    );

    if (content is String) {
      formData.addFile(
        http.MultipartFile.fromString(
          'content',
          content,
          contentType: contentType,
        ),
      );
    } else if (content is List<int>) {
      formData.addFile(
        http.MultipartFile.fromBytes(
          'content',
          content,
          contentType: contentType,
        ),
      );
    } else if (filePath != null) {
      formData.addFile(
        await http.MultipartFile.fromPath(
          'content',
          filePath,
          contentType: contentType,
        ),
      );
    } else {
      throw ArgumentError(
        'Content must be a String or List<int>, or filePath must be provided',
      );
    }

    return http
        .request('${_config.serviceUrl}/data/$bucketId/$key')
        .use(http.context(_config))
        .use(http.access())
        .post(formData)
        .json((json) => BucketFile.fromJson(json));
  }

  /// Retrieves a file or its content from a storage bucket.
  Future<ByteStream> retrieve({
    required String bucketId,
    required String key,
    int? offset,
    int? length,
  }) => http
      .request('${_config.serviceUrl}/data/$bucketId/$key')
      .use(http.context(_config))
      .use(http.access())
      .params({
        if (offset != null) 'offset': offset,
        if (length != null) 'length': length,
      })
      .get()
      .stream();

  /// Updates the metadata (description, tags) of a file in a storage bucket.
  Future<BucketFile> update({
    required String bucketId,
    required String key,
    String? description,
    List<String>? tags,
  }) => http
      .request('${_config.serviceUrl}/data/$bucketId/$key')
      .use(http.context(_config))
      .use(http.access())
      .put({'description': description, 'tags': tags})
      .json((json) => BucketFile.fromJson(json));

  /// Deletes a file from a storage bucket.
  Future<void> delete({required String bucketId, required String key}) async {
    await http
        .request('${_config.serviceUrl}/data/$bucketId/$key')
        .use(http.context(_config))
        .use(http.access())
        .delete()
        .json();
  }
}
