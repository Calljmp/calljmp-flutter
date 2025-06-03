import 'package:calljmp/attestation.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/users/auth.dart';
import 'package:calljmp/http.dart' as http;

/// Represents a user in the Calljmp system.
///
/// The User class contains all the essential information about a user,
/// including their identification, profile details, permissions, and metadata.
/// Users are created and managed through the authentication system and can
/// have various tags assigned for role-based access control.
///
/// ## Example
///
/// ```dart
/// final user = User(
///   id: 123,
///   email: 'user@example.com',
///   name: 'John Doe',
///   avatar: 'https://example.com/avatar.jpg',
///   tags: ['role:member', 'team:developers'],
///   createdAt: DateTime.now(),
/// );
/// ```
class User {
  /// The unique identifier for this user.
  ///
  /// This ID is automatically assigned by the system when the user is created
  /// and remains constant throughout the user's lifecycle.
  final int id;

  /// The user's email address.
  ///
  /// This is optional as users can be created through different authentication
  /// methods that may not require an email address.
  final String? email;

  /// The user's display name.
  ///
  /// This is the name that will be shown in the application interface.
  /// It's optional and can be updated by the user or application.
  final String? name;

  /// URL to the user's avatar image.
  ///
  /// This is optional and can point to any accessible image URL.
  /// The application can use this to display the user's profile picture.
  final String? avatar;

  /// List of tags assigned to this user.
  ///
  /// Tags are used for role-based access control and can include roles,
  /// permissions, team memberships, or any other categorization system.
  /// Common examples include 'role:admin', 'team:developers', 'plan:premium'.
  final List<String>? tags;

  /// The timestamp when this user was created.
  ///
  /// This is automatically set by the system when the user account is created
  /// and cannot be modified.
  final DateTime createdAt;

  /// Creates a new User instance.
  ///
  /// ## Parameters
  ///
  /// - [id]: The unique user identifier (required)
  /// - [email]: The user's email address (optional)
  /// - [name]: The user's display name (optional)
  /// - [avatar]: URL to the user's avatar image (optional)
  /// - [tags]: List of tags for role-based access control (optional)
  /// - [createdAt]: The user creation timestamp (required)
  User({
    required this.id,
    this.email,
    this.name,
    this.avatar,
    this.tags,
    required this.createdAt,
  });

  /// Creates a User instance from a JSON object.
  ///
  /// This factory constructor is used to deserialize user data received
  /// from the Calljmp API. It handles the conversion of JSON data types
  /// to the appropriate Dart types.
  ///
  /// ## Parameters
  ///
  /// - [json]: A Map containing the user data from the API
  ///
  /// ## Returns
  ///
  /// A new User instance populated with the JSON data
  ///
  /// ## Example
  ///
  /// ```dart
  /// final userData = {
  ///   'id': 123,
  ///   'email': 'user@example.com',
  ///   'name': 'John Doe',
  ///   'tags': ['role:member'],
  ///   'createdAt': '2023-01-01T00:00:00Z',
  /// };
  /// final user = User.fromJson(userData);
  /// ```
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

  /// Converts this User instance to a JSON object.
  ///
  /// This method is used to serialize user data for API requests or
  /// local storage. It converts all the user properties to JSON-compatible types.
  ///
  /// ## Returns
  ///
  /// A Map containing the user data in JSON format
  ///
  /// ## Example
  ///
  /// ```dart
  /// final user = User(id: 123, email: 'user@example.com', createdAt: DateTime.now());
  /// final json = user.toJson();
  /// print(json); // {'id': 123, 'email': 'user@example.com', ...}
  /// ```
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

  /// Returns a string representation of this User instance.
  ///
  /// This method provides a human-readable representation of the user
  /// that includes all the user's properties. Useful for debugging and logging.
  ///
  /// ## Returns
  ///
  /// A string containing all user properties
  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, avatar: $avatar, tags: $tags, createdAt: $createdAt}';
  }
}

/// Provides user management and authentication functionality.
///
/// The Users class is the main interface for all user-related operations
/// in the Calljmp SDK. It provides access to authentication methods and
/// user profile management through the Auth subsystem.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Authenticate a user
/// final user = await calljmp.users.auth.email.authenticate(
///   email: 'user@example.com',
///   password: 'password',
///   policy: UserAuthenticationPolicy.signInOrCreate,
/// );
///
/// // Retrieve current user information
/// final currentUser = await calljmp.users.retrieve();
/// ```
class Users {
  final Config _config;

  /// Provides authentication functionality for users.
  ///
  /// The auth property gives access to various authentication methods
  /// including email/password authentication, social logins, and other
  /// authentication providers supported by Calljmp.
  final Auth auth;

  /// Creates a new Users instance.
  ///
  /// This constructor is typically called internally by the Calljmp client
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [attestation]: The attestation service for device verification
  Users(this._config, Attestation attestation)
    : auth = Auth(_config, attestation);

  /// Retrieves the current authenticated user's information.
  ///
  /// This method fetches the complete user profile for the currently
  /// authenticated user, including their ID, email, name, avatar, tags,
  /// and creation timestamp.
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a User object containing the current user's information
  ///
  /// ## Throws
  ///
  /// - [CalljmpException] if the user is not authenticated
  /// - [HttpException] if there's a network error
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final user = await calljmp.users.retrieve();
  ///   print('Current user: ${user.name} (${user.email})');
  /// } catch (e) {
  ///   print('Failed to retrieve user: $e');
  /// }
  /// ```
  Future<User> retrieve() => http
      .request("${_config.serviceUrl}/users")
      .use(http.context(_config))
      .use(http.access())
      .get()
      .json((json) => User.fromJson(json));

  /// Updates the current user's profile information.
  ///
  /// This method allows updating the user's name, avatar URL, and tags.
  /// It can be used to modify the user's display name, profile picture,
  /// or role-based tags.
  ///
  /// ## Parameters
  ///
  /// - [name]: The new display name for the user (optional)
  /// - [avatar]: The new avatar URL for the user (optional)
  /// - [tags]: A list of new tags to assign to the user (optional)
  ///
  /// ## Returns
  ///
  /// A Future that resolves to the updated User object
  ///
  /// ## Throws
  ///
  /// - [CalljmpException] if the user is not authenticated
  /// - [HttpException] if there's a network error
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final updatedUser = await calljmp.users.update(
  ///     name: 'Jane Doe',
  ///     avatar: 'https://example.com/new-avatar.jpg',
  ///     tags: ['role:admin'],
  ///   );
  ///   print('User updated: ${updatedUser.name} (${updatedUser.avatar})');
  /// } catch (e) {
  ///   print('Failed to update user: $e');
  /// }
  /// ```
  Future<User> update({String? name, String? avatar, List<String>? tags}) =>
      http
          .request("${_config.serviceUrl}/users")
          .use(http.context(_config))
          .use(http.access())
          .put({
            if (name != null) 'name': name,
            if (avatar != null) 'avatar': avatar,
            if (tags != null) 'tags': tags,
          })
          .json((json) => User.fromJson(json));
}
