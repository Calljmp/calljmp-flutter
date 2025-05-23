import 'dart:convert';
import 'dart:developer' as developer;
import 'package:calljmp/access.dart';
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:calljmp/users/users.dart';

/// Enum representing supported email authentication providers.
enum UserAuthenticationProvider {
  /// Email and password authentication.
  emailPassword,

  /// Email magic link authentication.
  emailMagicLink,

  /// Email one-time code authentication.
  emailOneTimeCode,
}

/// Extension to get string value for [UserAuthenticationProvider].
extension UserAuthenticationProviderExtension on UserAuthenticationProvider {
  /// Returns the string value for the provider.
  String get value {
    switch (this) {
      case UserAuthenticationProvider.emailPassword:
        return "email_password";
      case UserAuthenticationProvider.emailMagicLink:
        return "email_magic_link";
      case UserAuthenticationProvider.emailOneTimeCode:
        return "email_one_time_code";
    }
  }
}

/// Enum representing authentication policy for user creation/sign-in.
enum UserAuthenticationPolicy {
  /// Only allow creating new users.
  createNewOnly,

  /// Only allow signing in existing users.
  signInExistingOnly,

  /// Allow signing in or creating new users.
  signInOrCreate,
}

/// Extension to get string value for [UserAuthenticationPolicy].
extension UserAuthenticationPolicyExtension on UserAuthenticationPolicy {
  /// Returns the string value for the policy.
  String get value {
    switch (this) {
      case UserAuthenticationPolicy.createNewOnly:
        return "createNewOnly";
      case UserAuthenticationPolicy.signInExistingOnly:
        return "signInExistingOnly";
      case UserAuthenticationPolicy.signInOrCreate:
        return "signInOrCreate";
    }
  }
}

/// Provides email-based authentication methods for users.
class Email {
  final Config _config;
  final Attestation _attestation;
  final Auth _auth;

  Email(this._config, this._attestation, this._auth);

  /// Checks if the user is currently authenticated (access token is valid).
  Future<bool> authenticated() async {
    final token = await CalljmpStore.instance.get(CalljmpStoreKey.accessToken);
    if (token != null) {
      final result = AccessToken.tryParse(token);
      if (result.data != null) {
        return result.data!.isValid;
      }
    }
    return false;
  }

  /// Initiates email verification for authentication.
  ///
  /// Returns a challenge token and whether the user exists.
  Future<({String challengeToken, bool existingUser})> verify({
    String? email,
    required UserAuthenticationProvider provider,
    bool? doNotNotify,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/verify")
      .use(http.context(_config))
      .use(http.access())
      .json({
        "email": email,
        "provider": provider.value,
        "doNotNotify": doNotNotify,
      })
      .post()
      .json(
        (json) => (
          challengeToken: json["challengeToken"],
          existingUser: json["existingUser"],
        ),
      );

  /// Confirms a verification challenge.
  ///
  /// Returns whether the user exists.
  Future<({bool existingUser})> confirm({
    String? email,
    required String challengeToken,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/confirm")
      .use(http.context(_config))
      .use(http.access())
      .json({"email": email, "token": challengeToken})
      .post()
      .json((json) => (existingUser: json["existingUser"]));

  /// Initiates password reset process.
  ///
  /// Returns a challenge token for password reset.
  Future<({String challengeToken})> forgotPassword({
    String? email,
    bool? doNotNotify,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/password")
      .use(http.context(_config))
      .use(http.access())
      .json({"email": email, "doNotNotify": doNotNotify})
      .post()
      .json((json) => (challengeToken: json["challengeToken"]));

  /// Resets the user's password using a challenge token.
  Future<void> resetPassword({
    String? email,
    required String challengeToken,
    required String password,
    bool? doNotNotify,
  }) => http
      .request("${_config.serviceUrl}/users/auth/email/password")
      .use(http.context(_config))
      .use(http.access())
      .json({
        "email": email,
        "token": challengeToken,
        "password": password,
        "doNotNotify": doNotNotify,
      })
      .put()
      .json();

  /// Authenticates a user and returns a [User] object.
  ///
  /// Throws if password is not provided for email/password authentication.
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

    final attest = await _attestation
        .attest({"token": challengeToken})
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
        .json({
          "token": challengeToken,
          "attestationToken": attestationToken,
          "email": email,
          "emailVerified": emailVerified,
          "name": name,
          "password": password,
          "tags": tags,
          "policy": policy?.value,
          "doNotNotify": doNotNotify,
        })
        .post()
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

/// Provides authentication challenge and state clearing methods.
class Auth {
  /// Email authentication handler.
  late final Email email;

  /// Constructs [Auth] with [config] and [attestation].
  Auth(Config config, Attestation attestation) {
    email = Email(config, attestation, this);
  }

  /// Requests a new authentication challenge token.
  Future<({String challengeToken})> challenge() => http
      .request("${email._config.serviceUrl}/users/auth/challenge")
      .use(http.context(email._config))
      .get()
      .json((json) => (challengeToken: json["challengeToken"]));

  /// Clears the current authentication state (removes access token).
  Future<void> clear() async {
    await CalljmpStore.instance.delete(CalljmpStoreKey.accessToken);
  }
}
