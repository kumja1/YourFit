import 'dart:async';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/people/v1.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthResponse;
import 'package:yourfit/src/models/auth/auth_response.dart';
import 'package:yourfit/src/models/auth/new_user_auth_response.dart';
import 'package:yourfit/src/models/index.dart';
import 'package:yourfit/src/services/user_service.dart';
import 'package:yourfit/src/utils/index.dart' hide Supabase;
import 'package:rxget/rxget.dart';

class AuthService {
  final UserService _userService = Get.find<UserService>();
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final Rx<UserData?> currentUser = Rx<UserData?>(null);

  /// Returns true if the user is signed in.
  bool get isSignedIn => currentUser.value != null;

  void init() {
    _auth.onAuthStateChange.listen((event) async {
      try {
        switch (event.event) {
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.signedIn:
            currentUser.value = await _userService.getUser(
              event.session!.user.id,
            );
            break;
          case AuthChangeEvent.passwordRecovery:
          case AuthChangeEvent.signedOut:
            currentUser.value = null;
            break;
          default:
            break;
        }
      } catch (e) {
        logger.severe("Error in _authStateChange", e);
      }
    });
  }

  Future<AuthResponse> signInWithPassword(
    String email,
    String password,
  ) async => await _tryCatch(
    () async {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResponse(
          code: AuthCode.error,
          message: AuthError.userNotFound,
        );
      }

      return AuthResponse(
        code: AuthCode.success,
        message: null,
        supabaseUser: response.user,
      );
    },
    onError: (e) async {
      await _auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: Uri.base.toString(),
      );

      return AuthResponse(code: AuthCode.error, message: e.message);
    },
  );

  Future<AuthResponse> signUpWithPassword(
    String email,
    String password,
  ) async => await _tryCatch(() async {
    final response = await _auth.signUp(email: email, password: password);
    if (response.user == null) {
      return AuthResponse(
        code: AuthCode.error,
        message: AuthError.userNotFound,
      );
    }

    return AuthResponse(
      code: AuthCode.success,
      message: null,
      supabaseUser: response.user,
    );
  });

  Future<AuthResponse> signOut() async => await _tryCatch(() async {
    await _auth.signOut();
    return AuthResponse(code: AuthCode.success, message: null);
  });

  Future<AuthResponse> sendPasswordReset(
    String email, {
    String? redirectTo,
  }) async => await _tryCatch(() async {
    await _auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    return AuthResponse(code: AuthCode.success, message: null);
  });

  Future<AuthResponse> resetPassword(String newPassword) async =>
      await _tryCatch(() async {
        await _auth.updateUser(UserAttributes(password: newPassword));
        return AuthResponse(code: AuthCode.success, message: null);
      });

  Future<AuthResponse> refreshSession() async => await _tryCatch(() async {
    final session = await _auth.refreshSession();
    if (session.user == null) {
      return AuthResponse(
        code: AuthCode.error,
        message: AuthError.userNotFound,
      );
    }
    return AuthResponse(code: AuthCode.success, message: null);
  });

  Future<AuthResponse> _signInWithWebOAuth(OAuthProvider provider) async =>
      await _tryCatch(() async {
        final success = await _auth.signInWithOAuth(
          provider,
          redirectTo: null,
          queryParams: const {'prompt': 'consent'},
        );

        if (!success) {
          return AuthResponse(
            code: AuthCode.error,
            message: AuthError.userNotFound,
          );
        }

        return AuthResponse(code: AuthCode.success, message: null);
      });

  Future<AuthResponse> signInWithOAuth(OAuthProvider provider) async => kIsWeb
      ? _signInWithWebOAuth(provider)
      : switch (provider) {
          (OAuthProvider.google) => await _signInWithGoogleOAuth(),
          _ => AuthResponse(
            code: AuthCode.error,
            message: AuthError.invalidOAuthProvider,
          ),
        };

  Future<AuthResponse> _signInWithGoogleOAuth() async => await _tryCatch(
    () async {
      final scopes = const [
        PeopleServiceApi.userGenderReadScope,
        PeopleServiceApi.userinfoProfileScope,
        PeopleServiceApi.userBirthdayReadScope,
      ];

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: scopes,
      );

      final authentication = account.authentication;
      final authorization = await GoogleSignIn.instance.authorizationClient
          .authorizationForScopes(scopes);

      if (authorization == null) {
        return AuthResponse(
          code: AuthCode.error,
          message: AuthError.googleOAuthSignInError,
        );
      }
      if (authentication.idToken == null) {
        return AuthResponse(
          code: AuthCode.error,
          message: AuthError.googleOAuthSignInError,
        );
      }

      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: authentication.idToken!,
        accessToken: authorization.accessToken,
      );

      if (response.user == null) {
        return AuthResponse(
          code: AuthCode.error,
          message: "An unknown error occured",
        );
      }

      final existingUser = await _userService.getUser(response.user!.id);
      final bool isNewUser = existingUser == null;

      if (isNewUser) {
        final peopleApi = PeopleServiceApi(
          authorization.authClient(scopes: scopes),
        );

        final Person person = await peopleApi.people.get(
          'people/me',
          personFields: 'birthdays,genders,names',
        );

        final name = person.names?.first;
        final gender = person.genders?.first;
        final dob = person.birthdays?.first;

        if (name == null || gender == null || dob == null) {
          return AuthResponse(
            code: AuthCode.error,
            message: AuthError.googleOAuthSignInError,
          );
        }

        final dobDateTime = DateTime.parse(dob.date.toString());
        return NewUserAuthResponse(
          newUser: UserData(
            id: response.user!.id,
            createdAt: DateTime.now(),
            firstName: name.givenName ?? '',
            lastName: name.familyName ?? '',
            gender: UserGender.fromValue(gender.value ?? 'male'),
            dob: dobDateTime,
            height: 0,
            weight: 0,
            physicalFitness: UserPhysicalFitness.minimal,
            stats: UserStats(),
          ),
          supabaseUser: response.user,
        );
      }

      return AuthResponse(code: AuthCode.success, supabaseUser: response.user);
    },
  );

  Future<AuthResponse> _tryCatch(
    Future<AuthResponse> Function() callback, {
    Future<AuthResponse> Function(AuthException)? onError,
  }) async {
    try {
      return await callback();
    } on AuthException catch (e) {
      if (onError == null) {
        return AuthResponse(code: AuthCode.error, message: e.message);
      }

      return await onError(e);
    }
  }

  void dispose() => _auth.dispose();
}
