class AdminModerationFilterPolicy {
  const AdminModerationFilterPolicy._();

  static bool matches({
    required String id,
    required Map<String, dynamic> data,
    required String query,
    required String statusFilter,
  }) {
    final cleanStatus = statusFilter.trim().toLowerCase();
    if (cleanStatus.isNotEmpty && cleanStatus != 'all') {
      final status = _text(data['status'], _text(data['reviewStatus']))
          .toLowerCase();
      if (status != cleanStatus) return false;
    }

    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    final haystack = <String>[
      id,
      ...data.values.map((value) => value?.toString() ?? ''),
    ].join(' ').toLowerCase();

    return haystack.contains(cleanQuery);
  }

  static String _text(Object? value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
