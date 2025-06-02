import 'package:calljmp/access.dart';
import 'package:calljmp/attestation.dart';
import 'package:calljmp/calljmp_store_interface.dart';
import 'package:calljmp/config.dart';
import 'package:calljmp/http.dart' as http;
import 'package:calljmp/users/email.dart';
import 'package:calljmp/users/provider.dart';

/// Enum representing supported email authentication providers.
///
/// This enum defines the different methods available for authenticating
/// users through email-based authentication systems. Each provider
/// offers different security and user experience characteristics.
enum UserAuthenticationProvider {
  /// Email and password authentication.
  ///
  /// Traditional username/password authentication where users provide
  /// their email address and a password to sign in.
  emailPassword,

  /// Email magic link authentication.
  ///
  /// Passwordless authentication where users receive a magic link
  /// via email that automatically signs them in when clicked.
  emailMagicLink,

  /// Email one-time code authentication.
  ///
  /// Passwordless authentication where users receive a temporary
  /// numeric code via email that they enter to sign in.
  emailOneTimeCode,

  /// Apple authentication.
  ///
  /// Sign in with Apple allows users to authenticate using their Apple ID.
  apple,

  /// Google authentication.
  ///
  /// Sign in with Google allows users to authenticate using their Google account.
  google,
}

/// Extension to get string value for [UserAuthenticationProvider].
///
/// This extension provides a convenient way to convert the enum values
/// to their string representations used in API calls.
extension UserAuthenticationProviderExtension on UserAuthenticationProvider {
  /// Returns the string value for the provider.
  ///
  /// This is used internally by the SDK to communicate with the Calljmp API
  /// and should match the expected values on the backend.
  String get value {
    switch (this) {
      case UserAuthenticationProvider.emailPassword:
        return "email_password";
      case UserAuthenticationProvider.emailMagicLink:
        return "email_magic_link";
      case UserAuthenticationProvider.emailOneTimeCode:
        return "email_one_time_code";
      case UserAuthenticationProvider.apple:
        return "apple";
      case UserAuthenticationProvider.google:
        return "google";
    }
  }
}

/// Enum representing authentication policy for user creation/sign-in.
///
/// This enum defines the behavior when a user attempts to authenticate.
/// It controls whether new users can be created, whether only existing
/// users can sign in, or whether both operations are allowed.
enum UserAuthenticationPolicy {
  /// Only allow creating new users.
  ///
  /// Authentication will fail if a user with the provided credentials
  /// already exists. Use this when you want to ensure only new
  /// registrations are processed.
  createNewOnly,

  /// Only allow signing in existing users.
  ///
  /// Authentication will fail if no user exists with the provided
  /// credentials. Use this when you want to prevent new user creation
  /// and only allow existing users to sign in.
  signInExistingOnly,

  /// Allow signing in or creating new users.
  ///
  /// If a user exists, they will be signed in. If no user exists,
  /// a new user will be created and signed in. This is the most
  /// flexible option for user authentication flows.
  signInOrCreate,
}

/// Extension to get string value for [UserAuthenticationPolicy].
///
/// This extension provides a convenient way to convert the enum values
/// to their string representations used in API calls.
extension UserAuthenticationPolicyExtension on UserAuthenticationPolicy {
  /// Returns the string value for the policy.
  ///
  /// This is used internally by the SDK to communicate with the Calljmp API
  /// and should match the expected values on the backend.
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
///
/// The Auth class serves as the main authentication controller for the Calljmp SDK.
/// It manages authentication challenges, coordinates with different authentication
/// providers (like email), and handles authentication state management.
///
/// ## Usage
///
/// ```dart
/// final calljmp = Calljmp();
///
/// // Get authentication challenge
/// final challenge = await calljmp.users.auth.challenge();
///
/// // Authenticate with email
/// final user = await calljmp.users.auth.email.authenticate(
///   email: 'user@example.com',
///   password: 'password',
///   policy: UserAuthenticationPolicy.signInOrCreate,
/// );
///
/// // Clear authentication state
/// await calljmp.users.auth.clear();
/// ```
class Auth {
  final Config _config;

  /// Email authentication handler.
  ///
  /// Provides access to email-based authentication methods including
  /// password authentication, magic links, and one-time codes.
  late final Email email;

  /// Apple authentication provider.
  ///
  /// Provides methods for authenticating users via their Apple ID.
  ///
  /// This provider allows users to sign in using their Apple account,
  /// leveraging Apple's secure authentication mechanisms.
  late final Provider apple;

  /// Google authentication provider.
  ///
  /// Provides methods for authenticating users via their Google account,
  /// leveraging Google's secure authentication mechanisms.
  late final Provider google;

  /// Constructs [Auth] with [config] and [attestation].
  ///
  /// This constructor is typically called internally by the Users class
  /// and should not be used directly in application code.
  ///
  /// ## Parameters
  ///
  /// - [_config]: The SDK configuration containing API endpoints and settings
  /// - [attestation]: The attestation service for device verification
  Auth(this._config, Attestation attestation) {
    email = Email(_config, attestation, this);
    apple = Provider(
      UserAuthenticationProvider.apple,
      _config,
      attestation,
      this,
    );
    google = Provider(
      UserAuthenticationProvider.google,
      _config,
      attestation,
      this,
    );
  }

  /// Checks if the user is currently authenticated (access token is valid).
  ///
  /// This method verifies whether there is a valid access token stored locally
  /// and whether that token has not expired. It does not make a network request
  /// to verify the token with the server.
  ///
  /// ## Returns
  ///
  /// A Future that resolves to true if the user is authenticated with a valid token,
  /// false otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// final isAuthenticated = await calljmp.users.auth.email.authenticated();
  /// if (isAuthenticated) {
  ///   print('User is already signed in');
  /// } else {
  ///   print('User needs to authenticate');
  /// }
  /// ```
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

  /// Requests a new authentication challenge token.
  ///
  /// Authentication challenges are used to verify the authenticity of
  /// authentication requests and prevent replay attacks. The challenge
  /// token should be used in subsequent authentication calls.
  ///
  /// ## Returns
  ///
  /// A Future that resolves to a record containing the challenge token
  ///
  /// ## Throws
  ///
  /// - [HttpException] if there's a network error
  /// - [CalljmpException] if the server returns an error
  ///
  /// ## Example
  ///
  /// ```dart
  /// final challenge = await calljmp.users.auth.challenge();
  /// print('Challenge token: ${challenge.challengeToken}');
  /// ```
  Future<({String challengeToken})> challenge() => http
      .request("${_config.serviceUrl}/users/auth/challenge")
      .use(http.context(_config))
      .get()
      .json((json) => (challengeToken: json["challengeToken"]));

  /// Clears the current authentication state (removes access token).
  ///
  /// This method signs out the current user by removing their access token
  /// from local storage. After calling this method, the user will need to
  /// authenticate again to access protected resources.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Sign out the current user
  /// await calljmp.users.auth.clear();
  /// print('User signed out successfully');
  /// ```
  Future<void> clear() async {
    await CalljmpStore.instance.delete(CalljmpStoreKey.accessToken);
  }
}
