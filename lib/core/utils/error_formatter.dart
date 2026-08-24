/// Converts technical exceptions, Supabase AuthApiExceptions, and network errors
/// into clear, user-friendly language without technical jargon or stack trace syntax.
class ErrorFormatter {
  ErrorFormatter._();

  static String formatAuthError(dynamic error) {
    if (error == null) return 'An error occurred. Please try again.';
    final text = error.toString();
    final lower = text.toLowerCase();

    // 1. Rate limits & throttling
    if (lower.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('rate_limit') ||
        lower.contains('too many requests') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('rate_limit_exceeded') ||
        lower.contains('over_request_rate_limit') ||
        lower.contains('request limit')) {
      return 'Please wait a moment before trying again.';
    }

    // 2. Invalid credentials
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials') ||
        lower.contains('invalid_grant') ||
        lower.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }

    // 3. User already registered / exists
    if (lower.contains('user already registered') ||
        lower.contains('already registered') ||
        lower.contains('user_already_exists') ||
        lower.contains('email already exists') ||
        lower.contains('unique constraint')) {
      return 'An account with this email already exists. Please log in instead.';
    }

    // 4. Email not verified / confirmed
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'Please verify your email address to continue.';
    }

    // 5. Invalid / Expired OTP or Token
    if (lower.contains('token has expired') ||
        lower.contains('invalid token') ||
        lower.contains('token is invalid') ||
        lower.contains('token not found') ||
        lower.contains('otp_expired') ||
        lower.contains('invalid code')) {
      return 'The verification code is invalid or has expired.';
    }

    // 6. Network and Connection issues
    if (lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('offline') ||
        lower.contains('clientexception')) {
      return 'Network connection issue. Please check your internet connection.';
    }

    // 7. Password requirements
    if (lower.contains('password should be') ||
        lower.contains('weak password') ||
        lower.contains('password is too short')) {
      return 'Password is too weak. Please fulfill all password requirements.';
    }

    // 8. Clean up raw exception syntax (e.g. AuthApiException(message: ..., statusCode: 400))
    final messageMatch = RegExp(r'message:\s*([^,\)]+)', caseSensitive: false).firstMatch(text);
    if (messageMatch != null) {
      final msg = messageMatch.group(1)?.trim();
      if (msg != null && msg.isNotEmpty && !msg.contains('Exception')) {
        return _humanizeSentence(msg);
      }
    }

    // 9. Remove exception prefixes like "AuthException:", "Exception:", "StateError:"
    var cleaned = text
        .replaceAll(RegExp(r'^(AuthApiException|AuthException|Exception|StateError|FormatException):\s*', caseSensitive: false), '')
        .trim();

    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    return cleaned.isNotEmpty ? _humanizeSentence(cleaned) : 'An unexpected error occurred. Please try again.';
  }

  static String _humanizeSentence(String s) {
    if (s.isEmpty) return s;
    final first = s[0].toUpperCase();
    final rest = s.substring(1);
    var result = '$first$rest';
    if (!result.endsWith('.') && !result.endsWith('!') && !result.endsWith('?')) {
      result += '.';
    }
    return result;
  }
}
