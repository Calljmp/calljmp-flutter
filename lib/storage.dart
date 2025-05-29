import 'dart:convert';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';

/// Represents a storage bucket in the Calljmp system.
///
/// A bucket is a container for organizing files in the storage system.
/// Each bucket has a unique identifier and can contain multiple files
/// with various metadata and access controls.
///
/// ## Example
///
/// ```dart
/// final bucket = Bucket(
///   id: 123,
///   uuid: 'bucket-uuid-123',
///   name: 'user-uploads',
///   description: 'User uploaded files',
///   createdAt: DateTime.now(),
/// );
/// ```
class Bucket {
  /// The unique numeric identifier for this bucket.
  final int id;

  /// The UUID string identifier for this bucket.
  ///
  /// This is a globally unique identifier that can be used
  /// for referencing the bucket in API calls.
  final String uuid;

  /// The human-readable name of the bucket.
  final String name;

  /// Optional description of the bucket's purpose.
  final String? description;

  /// The timestamp when this bucket was created.
  final DateTime createdAt;

  /// Creates a new Bucket instance.
  ///
  /// ## Parameters
  ///
  /// - [id]: The unique numeric identifier
  /// - [uuid]: The UUID string identifier
  /// - [name]: The bucket name
  /// - [description]: Optional description
  /// - [createdAt]: Creation timestamp
  Bucket({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    required this.createdAt,
  });

  /// Creates a Bucket instance from a JSON object.
  ///
  /// Used for deserializing bucket data from the Calljmp API.
  ///
  /// ## Parameters
  ///
  /// - [json]: JSON object containing bucket data
  ///
  /// ## Returns
  ///
  /// A new Bucket instance
  factory Bucket.fromJson(Map<String, dynamic> json) {
    return Bucket(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts this Bucket instance to a JSON object.
  ///
  /// ## Returns
  ///
  /// A Map containing the bucket data in JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns a string representation of this Bucket instance.
  @override
  String toString() {
    return 'Bucket{id: $id, uuid: $uuid, name: $name, description: $description, createdAt: $createdAt}';
  }
}

/// Represents a file stored in a bucket.
///
/// A BucketFile contains metadata about a file including its location,
/// size, type, and any associated tags for organization and access control.
///
/// ## Example
///
/// ```dart
/// final file = BucketFile(
///   id: 456,
///   key: 'uploads/image.jpg',
///   description: 'User profile picture',
///   tags: ['profile', 'image'],
///   bucketId: 123,
///   type: 'image/jpeg',
///   size: 1024000,
///   createdAt: DateTime.now(),
/// );
/// ```
class BucketFile {
  /// The unique identifier for this file.
  final int id;

  /// The key (path) of the file within the bucket.
  ///
  /// This acts as the file's path or name within the bucket
  /// and is used to retrieve the file later.
  final String key;

  /// Optional description of the file.
  final String? description;

  /// List of tags associated with this file.
  ///
  /// Tags can be used for organization, access control,
  /// and categorization of files within the bucket.
  final List<String>? tags;

  /// The ID of the bucket that contains this file.
  final int bucketId;

  /// The MIME type of the file.
  ///
  /// Examples: 'image/jpeg', 'text/plain', 'application/pdf'
  final String? type;

  /// The size of the file in bytes.
  final int size;

  /// The timestamp when this file was created.
  final DateTime createdAt;

  /// Creates a new BucketFile instance.
  ///
  /// ## Parameters
  ///
  /// - [id]: The unique file identifier
  /// - [key]: The file key/path within the bucket
  /// - [description]: Optional file description
  /// - [tags]: Optional list of tags
  /// - [bucketId]: ID of the containing bucket
  /// - [type]: Optional MIME type
  /// - [size]: File size in bytes
  /// - [createdAt]: Creation timestamp
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

  /// Creates a BucketFile instance from a JSON object.
  ///
  /// Used for deserializing file data from the Calljmp API.
  ///
  /// ## Parameters
  ///
  /// - [json]: JSON object containing file data
  ///
  /// ## Returns
  ///
  /// A new BucketFile instance
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

  /// Converts this BucketFile instance to a JSON object.
  ///
  /// ## Returns
  ///
  /// A Map containing the file data in JSON format
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

  /// Returns a string representation of this BucketFile instance.
  @override
  String toString() {
    return 'BucketFile{id: $id, key: $key, description: $description, tags: $tags, bucketId: $bucketId, type: $type, size: $size, createdAt: $createdAt}';
  }
}

/// Provides file storage and management functionality.
///
/// The Storage class enables you to upload, download, and manage files
/// in organized buckets. It supports various file types and provides
/// metadata management including tags, descriptions, and content types.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Upload a file from bytes
/// final file = await calljmp.storage.upload(
///   content: fileBytes,
///   contentType: MediaType('image', 'jpeg'),
///   bucketId: 'user-uploads',
///   key: 'profile/avatar.jpg',
///   description: 'User profile picture',
///   tags: ['profile', 'avatar'],
/// );
///
/// // Upload from file path
/// final document = await calljmp.storage.upload(
///   filePath: '/path/to/document.pdf',
///   bucketId: 'documents',
///   key: 'contracts/agreement.pdf',
///   tags: ['legal', 'contract'],
/// );
///
/// // Download a file
/// final fileData = await calljmp.storage.download(
///   bucketId: 'user-uploads',
///   key: 'profile/avatar.jpg',
/// );
/// ```
class Storage {
  final Config _config;

  /// Creates a new Storage instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  Storage(this._config);

  /// Uploads a file or content to a storage bucket.
  ///
  /// This method supports uploading content from various sources including
  /// byte arrays, strings, or file paths. The uploaded file will be stored
  /// in the specified bucket with the given key and metadata.
  ///
  /// ## Parameters
  ///
  /// - [content]: The file content as bytes or string (optional if filePath provided)
  /// - [filePath]: Path to the file to upload (optional if content provided)
  /// - [contentType]: MIME type of the content
  /// - [bucketId]: ID of the target bucket (required)
  /// - [key]: Unique key/path for the file within the bucket (required)
  /// - [description]: Optional description of the file
  /// - [tags]: Optional list of tags for organization
  /// - [sha256]: Optional SHA256 hash for integrity verification
  /// - [type]: Optional custom type classification
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a BucketFile representing the uploaded file
  ///
  /// ## Throws
  ///
  /// - [Exception] if neither content nor filePath is provided
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the upload fails or bucket doesn't exist
  ///
  /// ## Examples
  ///
  /// ```dart
  /// // Upload image from bytes
  /// final imageFile = await calljmp.storage.upload(
  ///   content: imageBytes,
  ///   contentType: MediaType('image', 'png'),
  ///   bucketId: 'images',
  ///   key: 'gallery/photo1.png',
  ///   description: 'Holiday photo',
  ///   tags: ['vacation', '2023'],
  /// );
  ///
  /// // Upload document from file path
  /// final document = await calljmp.storage.upload(
  ///   filePath: '/path/to/report.pdf',
  ///   bucketId: 'documents',
  ///   key: 'reports/monthly-report.pdf',
  ///   tags: ['report', 'monthly'],
  /// );
  ///
  /// // Upload text content
  /// final textFile = await calljmp.storage.upload(
  ///   content: 'Hello, world!',
  ///   contentType: MediaType('text', 'plain'),
  ///   bucketId: 'text-files',
  ///   key: 'messages/hello.txt',
  /// );
  /// ```
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

  Future<BucketFile> peek({required String bucketId, required String key}) =>
      http
          .request('${_config.serviceUrl}/data/$bucketId/$key')
          .use(http.context(_config))
          .use(http.access())
          .params({'peek': true})
          .get()
          .json((json) => BucketFile.fromJson(json));

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

  Future<({List<BucketFile> files, int? nextOffset})> list({
    required String bucketId,
    int offset = 0,
    int? limit,
    String? orderDirection,
    String? orderField,
  }) => http
      .request('${_config.serviceUrl}/data/$bucketId/list')
      .use(http.context(_config))
      .use(http.access())
      .params({
        'offset': offset,
        if (limit != null) 'limit': limit,
        if (orderDirection != null) 'orderDirection': orderDirection,
        if (orderField != null) 'orderField': orderField,
      })
      .get()
      .json(
        (json) => (
          files: (json['files'] as List<dynamic>)
              .map((e) => BucketFile.fromJson(e as Map<String, dynamic>))
              .toList(),
          nextOffset: json['nextOffset'] as int?,
        ),
      );
}
