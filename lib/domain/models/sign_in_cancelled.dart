/// The user dismissed a sign-in sheet.
///
/// Not a failure — nothing went wrong and there is nothing to retry — but the
/// data layer has to raise *something* for the call to unwind. Each provider
/// signals a cancellation in its own way (Google as a `PlatformException`,
/// Apple as a `SignInWithAppleAuthorizationException`), so the data layer
/// translates those into this one type and the UI layer stays free of
/// provider SDK imports.
class SignInCancelled implements Exception {
  const SignInCancelled();

  @override
  String toString() => 'SignInCancelled';
}
