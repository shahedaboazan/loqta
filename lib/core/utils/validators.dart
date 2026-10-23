/// Pure form validation helpers shared by the authentication screens.
///
/// Length rules follow the approved designs: sign-up and reset both specify a
/// minimum of 8 characters ("At least 8 characters" on 06, "Min. 8 chars" and
/// "Must be at least 8 characters" on 09), while sign-in only requires the
/// field to be filled — existing accounts created before that rule must still
/// be able to sign in.
class AppValidators {
  AppValidators._();

  /// Minimum password length mandated by the approved screens.
  static const int passwordMinLength = 8;

  static const _emailRegex =
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final email = value.trim();
    if (!RegExp(_emailRegex).hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// A password being *set* (sign-up, reset): requires [passwordMinLength].
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < passwordMinLength) {
      return 'Password must be at least $passwordMinLength characters.';
    }
    return null;
  }

  /// A password being *entered to sign in*: only needs to be present.
  static String? passwordRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? name(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    if (value.trim().length < 2) {
      return '$field must be at least 2 characters.';
    }
    return null;
  }

  static String? otpCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the 6-digit code.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'The code must be 6 digits.';
    }
    return null;
  }
}
