import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:calljmp/users/email.dart';

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

/// Provides authentication challenge and state clearing methods.
class Auth {
  final Config _config;

  /// Email authentication handler.
  late final Email email;

  /// Constructs [Auth] with [config] and [attestation].
  Auth(this._config, Attestation attestation) {
    email = Email(_config, attestation, this);
  }

  /// Requests a new authentication challenge token.
  Future<({String challengeToken})> challenge() => http
      .request("${_config.serviceUrl}/users/auth/challenge")
      .use(http.context(_config))
      .get()
      .json((json) => (challengeToken: json["challengeToken"]));

  /// Clears the current authentication state (removes access token).
  Future<void> clear() async {
    await CalljmpStore.instance.delete(CalljmpStoreKey.accessToken);
  }
}
