extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.capitalize)
        .join(' ');
  }

  String get initials {
    if (isEmpty) return '';
    final words = trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words.last[0]}'.toUpperCase();
  }

  String get masked {
    if (length <= 4) return this;
    final visible = substring(length - 4);
    final masked = '*' * (length - 4);
    return '$masked$visible';
  }

  String get cleanPhoneNumber {
    return replaceAll(RegExp(r'[\s\-()]'), '');
  }

  bool get isValidPhone {
    final cleaned = cleanPhoneNumber;
    return RegExp(r'^\+?[1-9]\d{9,14}$').hasMatch(cleaned);
  }

  bool get isValidOtp {
    return RegExp(r'^\d{6}$').hasMatch(trim());
  }
}
