import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';

class BusinessStaffGroup extends StatelessWidget {
  const BusinessStaffGroup({
    super.key,
    required this.title,
    required this.docs,
    required this.code,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });
  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String code;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) onEdit;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) onDelete;
  final Future<void> Function(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    bool isActive,
  )
  onToggle;
  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        ...docs.map((doc) {
          final data = doc.data();
          final name =
              (data[FirestoreFields.staffName] ??
                      data[FirestoreFields.name] ??
                      'Personel')
                  .toString();
          final email =
              (data[FirestoreFields.staffEmail] ??
                      data[FirestoreFields.email] ??
                      '')
                  .toString();
          final role = (data[FirestoreFields.role] ?? 'staff').toString();
          final invite = (data[FirestoreFields.inviteCode] ?? '').toString();
          final linked =
              ((data[FirestoreFields.linkedUid] ??
                      data[FirestoreFields.staffUid] ??
                      data[FirestoreFields.userUid] ??
                      '')
                  .toString()
                  .trim()
                  .isNotEmpty);
          final linkStatus =
              (data[FirestoreFields.staffLinkStatus] ??
                      (linked ? 'linked' : 'pending'))
                  .toString();
          final workStatus =
              (data[FirestoreFields.staffWorkStatus] ?? 'inactive').toString();
          final rawServiceIdsForBadge =
              data[FirestoreFields.serviceIds] ??
              data[FirestoreFields.staffServiceIds] ??
              data[FirestoreFields.allowedServiceIds];
          final serviceMatchCount = rawServiceIdsForBadge is Iterable
              ? rawServiceIdsForBadge
                    .map((e) => e.toString().trim())
                    .where((e) => e.isNotEmpty)
                    .length
              : 0;
          final serviceMatchMissing = serviceMatchCount == 0;
          final manager =
              role == 'manager' || role == 'owner' || role == 'admin';
          final active = data[FirestoreFields.isActive] != false;
          final color = active
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626);
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  manager
                      ? Icons.workspace_premium_outlined
                      : Icons.badge_outlined,
                  color: color,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (serviceMatchMissing)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Hizmet eksik',
                        style: TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (manager)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Yönetici',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '$email\n${active ? 'Aktif' : 'Pasif'} • Rol: $role'
                '${invite.isEmpty ? '' : '\nDavet kodu: $invite'}'
                '\nHizmet eşleşmesi: ${serviceMatchMissing ? 'Eksik' : '$serviceMatchCount hizmet'}'
                '\nBağlantı: ${linkStatus == 'linked' ? 'Bağlandı' : 'Bekliyor'} • Çalışma: ${workStatus == 'active' ? 'Aktif' : 'Pasif'}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'copyInvite' && invite.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: invite));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$name davet kodu kopyalandı: $invite'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                  if (v == 'toggle') {
                    await onToggle(doc, !active);
                  }
                  if (v == 'edit') onEdit(doc);
                  if (v == 'delete') onDelete(doc);
                },
                itemBuilder: (_) => [
                  if (invite.isNotEmpty)
                    const PopupMenuItem(
                      value: 'copyInvite',
                      child: Text('Davet kodunu kopyala'),
                    ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(active ? 'Pasif Yap' : 'Aktif Yap'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  const PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class BusinessStaffCard extends StatelessWidget {
  const BusinessStaffCard({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
