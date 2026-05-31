class BusinessDirectoryQueryBudgetPolicy {
  const BusinessDirectoryQueryBudgetPolicy._();

  static const int starterPageSize = 60;
  static const int starterPageCap = 300;
  static const int nearbyCollectionLimit = 120;
  static const int nearbyFallbackMinLocalResults = 8;
  static const int firestoreWhereInLimit = 10;

  static int pageSize(int requested) {
    return requested.clamp(1, starterPageSize).toInt();
  }

  static int pageCap(int requested) {
    return requested.clamp(1, starterPageCap).toInt();
  }

  static int nearbyLimit(int requested) {
    return requested.clamp(1, nearbyCollectionLimit).toInt();
  }

  static List<String> whereInPrefixes(List<String> prefixes) {
    final unique = <String>{};
    for (final prefix in prefixes) {
      final value = prefix.trim();
      if (value.isNotEmpty) {
        unique.add(value);
      }
      if (unique.length == firestoreWhereInLimit) break;
    }

    return unique.toList(growable: false);
  }
}
