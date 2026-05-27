import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/data/staff_tasks_entry_repository.dart';

import 'staff_workspace_page.dart';

/// Staff tasks entry keeps account discovery and session sync in a repository.
class StaffTasksEntryPage extends StatelessWidget {
  const StaffTasksEntryPage({super.key});

  static final StaffTasksEntryRepository _repository =
      StaffTasksEntryRepository();

  Future<List<StaffTaskAccount>> _loadStaffAccounts() {
    return _repository.loadStaffAccounts();
  }

  Future<void> _syncSession(BuildContext context, StaffTaskAccount account) {
    return _repository.syncSession(account);
  }

  Future<void> _openTasks(
    BuildContext context,
    StaffTaskAccount account,
  ) async {
    try {
      await _syncSession(context, account);

      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StaffWorkspacePage(memberData: account.data),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görevlerim açılamadı: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Görevlerim'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: FutureBuilder<List<StaffTaskAccount>>(
        future: _loadStaffAccounts(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? <StaffTaskAccount>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.length == 1) {
            return _AutoOpenTasksRedirect(
              onOpen: () => _openTasks(context, items.first),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _TasksIntroCard(),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _NoStaffTasksCard()
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: StaffTaskAccountTile(
                      item: item,
                      onTap: () => _openTasks(context, item),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _AutoOpenTasksRedirect extends StatefulWidget {
  const _AutoOpenTasksRedirect({required this.onOpen});

  final VoidCallback onOpen;

  @override
  State<_AutoOpenTasksRedirect> createState() => _AutoOpenTasksRedirectState();
}

class _AutoOpenTasksRedirectState extends State<_AutoOpenTasksRedirect> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      _opened = true;
      widget.onOpen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'Randevu takibi açılıyor...',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasksIntroCard extends StatelessWidget {
  const _TasksIntroCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: const [
            Icon(Icons.task_alt_rounded, color: Color(0xFF10B981), size: 34),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kendine atanmış randevuları burada başlatıp bitirebilirsin. Bu akış personel performansı, tamamlanan hizmet ve ödeme takibine bağlanacak.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStaffTasksCard extends StatelessWidget {
  const _NoStaffTasksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
            SizedBox(height: 10),
            Text(
              'Personel görevi bulunamadı',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Bu hesap henüz bir kurumsal kullanıcı personeli olarak eşleşmemiş görünüyor. Personel daveti/kaydı tamamlandığında görevler burada görünecek.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffTaskAccountTile extends StatelessWidget {
  const StaffTaskAccountTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final StaffTaskAccount item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(14),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEFFBF4),
        child: Icon(
          Icons.assignment_turned_in_rounded,
          color: Color(0xFF10B981),
        ),
      ),
      title: Text(
        item.businessName,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        [
          item.staffName,
          item.role,
        ].where((value) => value.trim().isNotEmpty).join(' • '),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
