import 'dart:convert';
import 'dart:developer' as developer;
import 'package:crypto/crypto.dart';
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:calljmp/users/auth.dart';
import 'package:calljmp/users/users.dart';

/// Provides email-based authentication methods for users.
///
/// The Email class handles all email-related authentication operations including
/// email verification, password authentication, magic link authentication,
/// and password reset functionality. It integrates with device attestation
/// to ensure secure authentication flows.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Check if user is authenticated
/// final isAuth = await calljmp.users.auth.email.authenticated();
///
/// // Authenticate with email and password
/// final user = await calljmp.users.auth.email.authenticate(
///   email: 'user@example.com',
///   password: 'secure_password',
///   policy: UserAuthenticationPolicy.signInOrCreate,
/// );
///
/// // Reset password
/// final challenge = await calljmp.users.auth.email.forgotPassword(
///   email: 'user@example.com',
/// );
/// await calljmp.users.auth.email.resetPassword(
///   email: 'user@example.com',
///   challengeToken: challenge.challengeToken,
///   password: 'new_password',
/// );
/// ```
class Email {
  final Config _config;
  final Attestation _attestation;
  final Auth _auth;

  /// Creates a new Email authentication handler.
  ///
  /// This constructor is typically called internally by the Auth class
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [_attestation]: The attestation service for device verification
  /// - [_auth]: The parent Auth instance for accessing authentication utilities
  Email(this._config, this._attestation, this._auth);

  /// Initiates email verification for authentication.
  ///
  /// This method starts the email verification process for various authentication
  /// providers including password, magic link, and one-time code authentication.
  /// It sends a verification email to the user and returns a challenge token
  /// that will be used in subsequent authentication steps.
  ///
  /// ## Parameters
  ///
  /// - [email]: The email address to verify (optional for some flows)
  /// - [provider]: The authentication provider to use
  /// - [doNotNotify]: If true, suppresses sending the verification email
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing:
  /// - `challengeToken`: Token to use for subsequent authentication
  /// - `existingUser`: Whether a user with this email already exists
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the server returns an error
  ///
  /// ## Example
  ///
  /// ```dart
  /// final verification = await calljmp.users.auth.email.verify(
  ///   email: 'user@example.com',
  ///   provider: UserAuthenticationProvider.emailPassword,
  /// );
  ///
  /// if (verification.existingUser) {
  ///   print('User exists, can sign in');
  /// } else {
  ///   print('New user, will be created');
  /// }
  /// ```
  Future<({String challengeToken, bool existingUser})> verify({
    String? email,
    required UserAuthenticationProvider provider,
    bool? doNotNotify,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/verify")
      .use(http.context(_config))
      .use(http.access())
      .post({
        "email": email,
        "provider": provider.value,
        "doNotNotify": doNotNotify,
      })
      .json(
        (json) => (
          challengeToken: json["challengeToken"],
          existingUser: json["existingUser"],
        ),
      );

  /// Confirms a verification challenge.
  ///
  /// This method is used to confirm email verification challenges such as
  /// magic links or one-time codes. It validates the challenge token
  /// received from the verification process.
  ///
  /// ## Parameters
  ///
  /// - [email]: The email address being verified (optional)
  /// - [challengeToken]: The challenge token from the verification process
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing:
  /// - `existingUser`: Whether a user with this email already exists
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the challenge token is invalid
  ///
  /// ## Example
  ///
  /// ```dart
  /// final confirmation = await calljmp.users.auth.email.confirm(
  ///   email: 'user@example.com',
  ///   challengeToken: 'token-from-email',
  /// );
  ///
  /// print('User exists: ${confirmation.existingUser}');
  /// ```
  Future<({bool existingUser})> confirm({
    String? email,
    required String challengeToken,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/confirm")
      .use(http.context(_config))
      .use(http.access())
      .post({"email": email, "token": challengeToken})
      .json((json) => (existingUser: json["existingUser"]));

  /// Initiates password reset process.
  ///
  /// This method starts the password reset flow by sending a password reset
  /// email to the user. The email will contain a challenge token that can
  /// be used to actually reset the password using the [resetPassword] method.
  ///
  /// ## Parameters
  ///
  /// - [email]: The email address of the user requesting password reset
  /// - [doNotNotify]: If true, suppresses sending the password reset email
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing:
  /// - `challengeToken`: Token to use for resetting the password
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the email is not found or invalid
  ///
  /// ## Example
  ///
  /// ```dart
  /// final reset = await calljmp.users.auth.email.forgotPassword(
  ///   email: 'user@example.com',
  /// );
  ///
  /// // User will receive an email with the challenge token
  /// print('Password reset initiated: ${reset.challengeToken}');
  /// ```
  Future<({String challengeToken})> forgotPassword({
    String? email,
    bool? doNotNotify,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/password")
      .use(http.context(_config))
      .use(http.access())
      .post({"email": email, "doNotNotify": doNotNotify})
      .json((json) => (challengeToken: json["challengeToken"]));

  /// Resets the user's password using a challenge token.
  ///
  /// This method completes the password reset process by setting a new password
  /// for the user. It requires a valid challenge token obtained from the
  /// [forgotPassword] method.
  ///
  /// ## Parameters
  ///
  /// - [email]: The email address of the user
  /// - [challengeToken]: The challenge token from the password reset email
  /// - [password]: The new password to set for the user
  /// - [doNotNotify]: If true, suppresses sending a confirmation email
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the challenge token is invalid or expired
  ///
  /// ## Example
  ///
  /// ```dart
  /// await calljmp.users.auth.email.resetPassword(
  ///   email: 'user@example.com',
  ///   challengeToken: 'token-from-email',
  ///   password: 'new_secure_password',
  /// );
  ///
  /// print('Password reset successfully');
  /// ```
  Future<void> resetPassword({
    String? email,
    required String challengeToken,
    required String password,
    bool? doNotNotify,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/password")
      .use(http.context(_config))
      .use(http.access())
      .put({
        "email": email,
        "token": challengeToken,
        "password": password,
        "doNotNotify": doNotNotify,
      })
      .json();

  /// Authenticates a user and returns a [User] object.
  ///
  /// This is the main authentication method that handles email/password
  /// authentication. It creates a new user if they don't exist (based on
  /// the policy) or signs in an existing user. The method integrates with
  /// device attestation for enhanced security.
  ///
  /// ## Parameters
  ///
  /// - [challengeToken]: Optional challenge token (will be generated if not provided)
  /// - [email]: The user's email address (required)
  /// - [emailVerified]: Whether the email is already verified
  /// - [name]: The user's display name (for new users)
  /// - [password]: The user's password (required for email/password auth)
  /// - [tags]: List of tags to assign to the user (for new users)
  /// - [policy]: Authentication policy controlling user creation/sign-in behavior
  /// - [doNotNotify]: If true, suppresses sending welcome/notification emails
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a User object representing the authenticated user
  ///
  /// ## Throws
  ///
  /// - [Exception] if password is not provided for email/password authentication
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if authentication fails or policy restrictions apply
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Sign in existing user or create new user
  /// final user = await calljmp.users.auth.email.authenticate(
  ///   email: 'user@example.com',
  ///   password: 'secure_password',
  ///   name: 'John Doe',
  ///   tags: ['role:member', 'plan:free'],
  ///   policy: UserAuthenticationPolicy.signInOrCreate,
  /// );
  ///
  /// print('Authenticated user: ${user.name} (${user.email})');
  /// ```
  Future<User> authenticate({
    String? challengeToken,
    required String email,
    bool? emailVerified,
    String? name,
    String? password,
    List<String>? tags,
    UserAuthenticationPolicy? policy,
    bool? doNotNotify,
  }) async {
    if (password == null) {
      throw Exception("Password is required for email/password authentication");
    }

    if (challengeToken == null) {
      final result = await _auth.challenge();
      challengeToken = result.challengeToken;
    }

    final attestationHash = base64.encode(
      sha256.convert(utf8.encode("$email:$challengeToken")).bytes,
    );
    final attest = await _attestation
        .attest({"hash": attestationHash})
        .catchError((error) {
          developer.log(
            "Failed to attest, this is fatal error unless it is in debug mode",
            name: "calljmp",
            error: error,
          );
          return Null;
        });
    final attestationToken = base64.encode(utf8.encode(jsonEncode(attest)));

    final result = await http
        .request("${_config.serviceUrl}/users/auth/email")
        .use(http.context(_config))
        .use(http.access())
        .post({
          "token": challengeToken,
          "attestationToken": attestationToken,
          "email": email,
          "password": password,
          if (emailVerified != null) "emailVerified": emailVerified,
          if (name != null) "name": name,
          if (tags != null) "tags": tags,
          if (policy != null) "policy": policy.value,
          "doNotNotify": doNotNotify ?? false,
        })
        .json(
          (json) => (
            accessToken: json["accessToken"],
            user: User.fromJson(json["user"]),
          ),
        );

    await CalljmpStore.instance.put(
      CalljmpStoreKey.accessToken,
      result.accessToken,
    );

    return result.user;
  }
}
