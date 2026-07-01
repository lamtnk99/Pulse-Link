class DateMath {
  const DateMath._();

  static int daysLeftUntil({
    required DateTime target,
    required DateTime now,
  }) {
    final diff = target.difference(DateTime(now.year, now.month, now.day));
    return diff.inDays.clamp(0, 9999).toInt();
  }
}
