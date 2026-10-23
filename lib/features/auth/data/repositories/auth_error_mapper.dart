import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase [AuthException] codes to user-facing English messages.
class AuthErrorMapper {
  AuthErrorMapper._();

  static String map(AuthException exception) {
    final code = exception.code;
    final message = exception.message.trim();

    switch (code) {
      case 'email_exists':
      case 'user_already_exists':
        return 'An account with this email already exists. Please sign in.';
      case 'invalid_credentials':
      case 'invalid_grant':
        return 'Incorrect email or password.';
      case 'email_not_confirmed':
        return 'Please verify your email address before signing in.';
      case 'otp_expired':
        return 'The code has expired. Please request a new one.';
      case 'otp_disabled':
        return 'Email codes are not enabled for this project.';
      case 'weak_password':
        final reasons = exception is AuthWeakPasswordException
            ? exception.reasons.join(' ')
            : '';
        return 'Password is too weak. $reasons'.trim();
      case 'same_password':
        return 'The new password must be different from the current one.';
      case 'over_request_rate_limit':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'over_email_send_rate_limit':
        return 'Too many emails sent. Please wait a minute and try again.';
      case 'signup_disabled':
        return 'New sign-ups are currently disabled.';
      case 'user_not_found':
        return 'No account found for this email address.';
      case 'validation_failed':
        return message.isNotEmpty
            ? message
            : 'Some fields are invalid. Please check your input.';
      case 'flow_state_expired':
        return 'The code has expired. Please request a new one.';
      default:
        if (message.isNotEmpty) return message;
        return 'Something went wrong. Please try again.';
    }
  }

  static String mapUnknown(Object error) {
    if (error is SocketException) {
      return 'Network error. Please check your connection and try again.';
    }
    if (error is AuthException) return map(error);
    return 'Something went wrong. Please try again.';
  }
}
