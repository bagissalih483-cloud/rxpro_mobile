import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:rxpro_mobile/features/businesses/data/business_staff_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/pages/business_staff_form_page.dart';
import 'package:rxpro_mobile/features/businesses/presentation/widgets/business_staff_manage_widgets.dart';

/// Business staff management keeps staff writes behind BusinessStaffRepository.
class BusinessStaffManagePage extends StatefulWidget {
  const BusinessStaffManagePage({
    super.key,
    required this.businessId,
    this.businessData = const <String, dynamic>{},
  });
  final String businessId;
  final Map<String, dynamic> businessData;
  @override
  State<BusinessStaffManagePage> createState() =>
      _BusinessStaffManagePageState();
}

class _BusinessStaffManagePageState extends State<BusinessStaffManagePage> {
  final BusinessStaffRepository _staffRepository = BusinessStaffRepository();
  late final Future<String> _codeFuture = _ensureBusinessAccessCode();
  Future<String> _ensureBusinessAccessCode() {
    return _staffRepository.ensureBusinessAccessCode(
      businessId: widget.businessId,
      businessData: widget.businessData,
    );
  }

  int _rank(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final active = m['isActive'] != false;
    final role = (m['role'] ?? '').toString();
    final manager = role == 'manager' || role == 'owner' || role == 'admin';
    if (manager && active) return 0;
    if (active) return 1;
    if (manager) return 2;
    return 3;
  }

  Future<void> _deleteStaff(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final name =
        (doc.data()[FirestoreFields.staffName] ??
                doc.data()[FirestoreFields.name] ??
                'Personel')
            .toString();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Personeli sil'),
        content: Text('$name personel kaydı silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) await _staffRepository.deleteStaffDocument(doc.reference);
  }

  void _openForm(
    String code, {
    String? staffId,
    Map<String, dynamic>? initialData,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffFormPage(
          businessId: widget.businessId,
          businessAccessCode: code,
          staffId: staffId,
          initialData: initialData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Personel ve Yetkiler'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final code = await _codeFuture;
          if (!context.mounted) return;
          _openForm(code);
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Personel Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          FutureBuilder<String>(
            future: _codeFuture,
            builder: (context, s) {
              final code = s.data ?? 'Hazırlanıyor...';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'İşletme Giriş Kodu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Personel uzun işletme ID yerine bu kısa kodu kullanacak.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('İşletme giriş kodu kopyalandı.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _staffRepository.watchBusinessStaff(widget.businessId),
            builder: (context, snapshot) {
              final docs =
                  [
                    ...(snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[]),
                  ]..sort((a, b) {
                    final r = _rank(a).compareTo(_rank(b));
                    if (r != 0) return r;
                    return (a.data()[FirestoreFields.staffName] ??
                            a.data()[FirestoreFields.name] ??
                            '')
                        .toString()
                        .compareTo(
                          (b.data()[FirestoreFields.staffName] ??
                                  b.data()[FirestoreFields.name] ??
                                  '')
                              .toString(),
                        );
                  });
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Henüz personel eklenmemiş.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              }
              final active = docs
                  .where((d) => d.data()['isActive'] != false)
                  .toList();
              final passive = docs
                  .where((d) => d.data()['isActive'] == false)
                  .toList();
              return FutureBuilder<String>(
                future: _codeFuture,
                builder: (context, cs) {
                  final code = cs.data ?? '';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BusinessStaffGroup(
                        title: 'Aktif Personel',
                        docs: active,
                        code: code,
                        onEdit: (doc) => _openForm(
                          code,
                          staffId: doc.id,
                          initialData: doc.data(),
                        ),
                        onDelete: _deleteStaff,
                        onToggle: (doc, isActive) =>
                            _staffRepository.setStaffActive(
                              staffId: doc.id,
                              isActive: isActive,
                            ),
                      ),
                      if (passive.isNotEmpty)
                        BusinessStaffGroup(
                          title: 'Pasif Personel',
                          docs: passive,
                          code: code,
                          onEdit: (doc) => _openForm(
                            code,
                            staffId: doc.id,
                            initialData: doc.data(),
                          ),
                          onDelete: _deleteStaff,
                          onToggle: (doc, isActive) =>
                              _staffRepository.setStaffActive(
                                staffId: doc.id,
                                isActive: isActive,
                              ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
