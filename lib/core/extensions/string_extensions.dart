import '../utils/validators.dart';

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
    final words = trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
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
    return Validators.normalizePhoneNumber(this);
  }

  bool get isValidPhone {
    final cleaned = Validators.cleanPhoneNumber(this);
    return Validators.isValidPhone(cleaned);
  }

  bool get isValidOtp {
    return Validators.isValidOtp(trim());
  }
}
