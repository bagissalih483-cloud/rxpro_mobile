import 'package:flutter/material.dart';

enum LegalAudience { customer, business, staff, all }

@immutable
class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.version,
    required this.lastUpdated,
    required this.audience,
    required this.summary,
    required this.sections,
  });

  final String id;
  final String title;
  final String version;
  final DateTime lastUpdated;
  final LegalAudience audience;
  final String summary;
  final List<LegalSection> sections;
}

@immutable
class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}
