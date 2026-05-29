import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import 'legal_document.dart';
import 'legal_documents_repository.dart';

class LegalDocumentsPage extends StatelessWidget {
  const LegalDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = const LegalDocumentsRepository().list();

    return Scaffold(
      appBar: AppBar(title: const Text('Yasal Metinler')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: documents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final document = documents[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: Text(
                document.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(document.summary),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.legalDocumentDetail,
                arguments: LegalDocumentDetailRouteArgs(document: document),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LegalDocumentDetailPage extends StatelessWidget {
  const LegalDocumentDetailPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final updated =
        '${document.lastUpdated.day.toString().padLeft(2, '0')}.'
        '${document.lastUpdated.month.toString().padLeft(2, '0')}.'
        '${document.lastUpdated.year}';

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Text(
            document.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Sürüm ${document.version} • Son güncelleme $updated',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Text(
            document.summary,
            style: const TextStyle(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bu metin taslak bilgilendirme niteliğindedir; yayın öncesinde nihai şirket bilgileri ve uzman hukuk kontrolüyle güncellenmelidir.',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          for (final section in document.sections) ...[
            Text(
              section.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(section.body, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
