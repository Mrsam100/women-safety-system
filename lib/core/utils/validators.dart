abstract final class Validators {
  /// India: +91 followed by 10 digits starting with 6-9
  static final _indiaPhoneRegExp =
      RegExp(r'^\+91[6-9]\d{9}$');

  /// International E.164: + country code (1-3 digits) then
  /// 7-15 total digits including country code
  static final _intlPhoneRegExp =
      RegExp(r'^\+[1-9]\d{6,14}$');

  static final _otpRegExp = RegExp(r'^\d{6}$');

  /// Allow unicode letters, spaces, hyphens, apostrophes,
  /// 2-50 characters.
  static final _nameRegExp =
      RegExp(r"^[\p{L}\s\-']{2,50}$", unicode: true);

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = cleanPhoneNumber(value);
    if (!isValidPhone(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Returns true when [phone] (already stripped of
  /// formatting) matches India or international E.164.
  static bool isValidPhone(String phone) {
    return _indiaPhoneRegExp.hasMatch(phone) ||
        _intlPhoneRegExp.hasMatch(phone);
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!isValidOtp(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  static bool isValidOtp(String value) {
    return _otpRegExp.hasMatch(value);
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (!_nameRegExp.hasMatch(value.trim())) {
      return 'Enter a valid name (2-50 characters)';
    }
    return null;
  }

  static String? validateRequired(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Strip formatting characters (spaces, dashes,
  /// parentheses) from [phone].
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-()]'), '');
  }

  /// Normalize [phone] to E.164 format.
  ///
  /// - Strips formatting characters first.
  /// - If the result is 10 digits starting with 6-9 and has
  ///   no country code, prepends +91 (India default).
  /// - Ensures the number starts with '+'.
  static String normalizePhoneNumber(String phone) {
    final cleaned = cleanPhoneNumber(phone);

    // 10-digit Indian number without country code
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return '+91$cleaned';
    }

    // Already has '+' — return as-is
    if (cleaned.startsWith('+')) {
      return cleaned;
    }

    // Digits only without '+' — assume missing '+'
    if (RegExp(r'^[1-9]\d{6,14}$').hasMatch(cleaned)) {
      return '+$cleaned';
    }

    return cleaned;
  }
}
