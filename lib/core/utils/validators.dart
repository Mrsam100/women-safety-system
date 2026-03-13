abstract final class Validators {
  static final _phoneRegExp = RegExp(r'^\+?[1-9]\d{9,14}$');
  static final _otpRegExp = RegExp(r'^\d{6}$');
  static final _nameRegExp = RegExp(r'^[a-zA-Z\s]{2,50}$');

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!_phoneRegExp.hasMatch(cleaned)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!_otpRegExp.hasMatch(value.trim())) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
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

  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-()]'), '');
  }
}
