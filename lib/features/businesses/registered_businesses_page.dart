import 'package:flutter/material.dart';

import 'package:rxpro_mobile/features/accounting/data/accounting_permission_bridge.dart';

import 'business_owner_hub_page.dart';
import 'staff_workspace_page.dart';
import 'staff_tasks_entry_page.dart';

import 'package:rxpro_mobile/features/businesses/data/registered_business_gateway_repository.dart';

class RegisteredBusinessesPage extends StatefulWidget {
  const RegisteredBusinessesPage({super.key});

  @override
  State<RegisteredBusinessesPage> createState() =>
      _RegisteredBusinessesPageState();
}

class _RegisteredBusinessesPageState extends State<RegisteredBusinessesPage> {
  final RegisteredBusinessGatewayRepository _gatewayRepository =
      RegisteredBusinessGatewayRepository();
  late Future<List<_GatewayItem>> _future;
  bool _openingStaff = false;

  @override
  void initState() {
    super.initState();
    _future = _loadItems();
  }

  Future<List<_GatewayItem>> _loadItems() async {
    final repositoryItems = await _gatewayRepository.fetchGatewayItems();

    return repositoryItems.map(_fromRepositoryItem).toList(growable: false);
  }

  _GatewayItem _fromRepositoryItem(RegisteredBusinessGatewayItem item) {
    return _GatewayItem(
      id: item.id,
      title: item.title,
      subtitle: item.subtitle,
      type: item.type == RegisteredBusinessGatewayItemType.staff
          ? _GatewayItemType.staff
          : _GatewayItemType.owner,
      data: Map<String, dynamic>.from(item.data),
    );
  }

  Future<void> _syncStaffSessionCache(_GatewayItem item) async {
    final data = item.data;
    final rawPermissions = data['permissions'];
    final normalizedPermissions = AccountingPermissionBridge.normalize(
      rawPermissions is Map
          ? Map<String, dynamic>.from(rawPermissions)
          : Map<String, dynamic>.from(data),
    );

    final mergedPermissions = <String, dynamic>{
      if (rawPermissions is Map) ...Map<String, dynamic>.from(rawPermissions),
      ...normalizedPermissions,
    };

    await _gatewayRepository.syncStaffSessionCache(
      item: RegisteredBusinessGatewayItem(
        id: item.id,
        title: item.title,
        subtitle: item.subtitle,
        type: item.type == _GatewayItemType.staff
            ? RegisteredBusinessGatewayItemType.staff
            : RegisteredBusinessGatewayItemType.owner,
        data: Map<String, dynamic>.from(item.data),
      ),
      permissions: mergedPermissions,
    );
  }

  Future<void> _openTasksEntry() async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StaffTasksEntryPage()));
  }

  Future<void> _openItem(_GatewayItem item) async {
    if (item.type == _GatewayItemType.staff) {
      setState(() => _openingStaff = true);

      try {
        await _syncStaffSessionCache(item);

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StaffWorkspacePage(memberData: item.data),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personel oturumu hazırlanamadı: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) setState(() => _openingStaff = false);
      }

      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BusinessOwnerHubPage()));
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadItems();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kurumsal Yönetim Merkezi'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Görevlerim',
            onPressed: _openTasksEntry,
            icon: const Icon(Icons.task_alt_rounded),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<_GatewayItem>>(
            future: _future,
            builder: (context, snapshot) {
              final items = snapshot.data ?? <_GatewayItem>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    _GatewayHeader(count: items.length),
                    const SizedBox(height: 12),
                    _TasksGatewayShortcut(onTap: _openTasksEntry),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const _EmptyGatewayCard()
                    else
                      ...items.map(
                        (item) => _GatewayTile(
                          item: item,
                          onTap: () => _openItem(item),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (_openingStaff)
            Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Personel yetkileri hazırlanıyor...',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _GatewayItemType { owner, staff }

class _GatewayItem {
  const _GatewayItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.data,
  });

  final String id;
  final String title;
  final String subtitle;
  final _GatewayItemType type;
  final Map<String, dynamic> data;
}

class _TasksGatewayShortcut extends StatelessWidget {
  const _TasksGatewayShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEFFBF4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFBBF7D0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.task_alt_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Görevlerim',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF064E3B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Personel olarak sana atanan randevuları başlat, bitir ve iş akışını takip et.',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF047857)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GatewayHeader extends StatelessWidget {
  const _GatewayHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.storefront_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kayıtlı Kurumsal Kullanıcılar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count bağlantı bulundu',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GatewayTile extends StatelessWidget {
  const _GatewayTile({required this.item, required this.onTap});

  final _GatewayItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isStaff = item.type == _GatewayItemType.staff;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(14),
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        leading: CircleAvatar(
          backgroundColor: isStaff
              ? const Color(0xFFFFF7ED)
              : const Color(0xFFECFDF5),
          child: Icon(
            isStaff ? Icons.badge_outlined : Icons.storefront_rounded,
            color: isStaff ? const Color(0xFFC2410C) : const Color(0xFF0F766E),
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          item.subtitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _EmptyGatewayCard extends StatelessWidget {
  const _EmptyGatewayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
          SizedBox(height: 10),
          Text(
            'Kurumsal Kullanıcı bağlantısı bulunamadı',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'Bu hesabın bağlı olduğu kurumsal kullanıcı veya personel kaydı bulunamadı. Kurumsal kayıt oluşturulduğunda veya personel daveti kabul edildiğinde burada görünecek.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
