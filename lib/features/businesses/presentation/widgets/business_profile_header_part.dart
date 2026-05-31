part of '../../business_profile_page.dart';

class _BusinessHeroCard extends StatelessWidget {
  const _BusinessHeroCard({
    required this.businessId,
    required this.businessName,
    required this.category,
  });

  final String businessId;
  final String businessName;
  final String category;
  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: BusinessProfileRepository().watchBusinessProfile(
        businessId: businessId,
        includeMetadataChanges: true,
      ),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final coverUrl = data[FirestoreFields.coverUrl]?.toString() ?? '';
        final logoUrl = _firstNonEmpty([
          data[FirestoreFields.logoUrl],
          data[FirestoreFields.photoUrl],
          data[FirestoreFields.imageUrl],
        ]);
        final resolvedBusinessName = _firstNonEmpty([
          data[FirestoreFields.businessName],
          data[FirestoreFields.name],
          data[FirestoreFields.companyName],
          data[FirestoreFields.displayName],
          businessName,
        ]);
        final resolvedCategory = _firstNonEmpty([
          data[FirestoreFields.categoryLabel],
          data[FirestoreFields.category],
          data[FirestoreFields.businessCategory],
          category,
        ]);
        final description = data[FirestoreFields.description]?.toString() ?? '';
        final followerCount = _toInt(data[FirestoreFields.followerCount]);
        final ratingAvg = _toDouble(data[FirestoreFields.ratingAvg]);
        final ratingCount = _toInt(data[FirestoreFields.ratingCount]);
        final canEdit = _canEditBusinessProfile(data);

        return _BusinessHeroContent(
          businessId: businessId,
          businessName: resolvedBusinessName,
          category: resolvedCategory,
          coverUrl: coverUrl,
          logoUrl: logoUrl,
          description: description,
          followerCount: followerCount,
          ratingAvg: ratingAvg,
          ratingCount: ratingCount,
          canEdit: canEdit,
        );
      },
    );
  }
  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}
