extension DateTimeExtensions on DateTime {
  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/'
        '${month.toString().padLeft(2, '0')}/'
        '$year';
  }

  String get formattedTime {
    final h = hour > 12 ? hour - 12 : hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:'
        '${minute.toString().padLeft(2, '0')} '
        '$period';
  }

  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    }
    return formattedDate;
  }

  bool get isNightTime {
    return hour >= 20 || hour < 6;
  }

  String get durationFromNow {
    final diff = DateTime.now().difference(this).abs();
    if (diff.inMinutes < 1) return '${diff.inSeconds}s';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}

extension DurationExtensions on Duration {
  String get formatted {
    final h = inHours;
    final m = inMinutes % 60;
    final s = inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}
