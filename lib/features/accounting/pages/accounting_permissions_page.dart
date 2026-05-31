import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';

import '../data/accounting_permission_bridge.dart';
import '../data/accounting_permissions.dart';
import '../data/accounting_permission_repository.dart';

class AccountingPermissionsPage extends StatelessWidget {
  const AccountingPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      _PermissionRowData(
        keyName: AccountingPermissionKeys.financeRead,
        description:
            'Muhasebe ekran\u0131n\u0131 ve rapor \u00f6zetlerini g\u00f6r\u00fcnt\u00fcler.',
        roleHint: 'Owner + yetkili personel',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.financeWrite,
        description:
            'Geçiş dönemi uyumluluk anahtarıdır; yeni adisyon ve tahsilat yetkileriyle birlikte değerlendirilir.',
        roleHint: 'Kasa / y\u00f6netici',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.saleProcess,
        description:
            'Bekleyen adisyonu işler; ödendi, kısmi, açık hesap, taksitli veya ücretsiz sonucu seçer.',
        roleHint: 'Kasa / yönetici',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.paymentCollect,
        description:
            'Adisyon veya alacak üzerinden tahsilat alır; kasa hareketi oluşturur.',
        roleHint: 'Kasa',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.saleCancel,
        description:
            'Tahsilat alınmamış bekleyen adisyonu gerekçesiyle iptal eder.',
        roleHint: 'Yönetici',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.paymentRefund,
        description:
            'Tahsilatı olan adisyonda iade/düzeltme işlemi yapar.',
        roleHint: 'Owner / yönetici',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.reportsRead,
        description: 'Finans raporlarını ve kasa özetlerini görüntüler.',
        roleHint: 'Owner / muhasebe',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.expenseWrite,
        description:
            'Gider giri\u015fi ve gider d\u00fczenleme i\u015flemi yapar.',
        roleHint: 'Muhasebe / y\u00f6netici',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.receivableManage,
        description:
            'Alacak, vade, geciken \u00f6deme ve hat\u0131rlatma i\u015flemlerini y\u00f6netir.',
        roleHint: 'Muhasebe / y\u00f6netici',
      ),
      _PermissionRowData(
        keyName: AccountingPermissionKeys.reportExport,
        description:
            'PDF / Excel rapor d\u0131\u015fa aktarma i\u015flemi yapar.',
        roleHint: 'Owner / y\u00f6netici',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _PermissionsHeader(),
        const SizedBox(height: 12),
        const _CurrentSessionPermissionCard(),
        const SizedBox(height: 12),
        const _CurrentStatusCard(),
        const SizedBox(height: 12),
        const _PermissionPresetCard(),
        const SizedBox(height: 12),
        const _SectionTitle('Yetki anahtarlar\u0131'),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PermissionCard(data: row),
          ),
        const SizedBox(height: 12),
        const _IntegrationNoteCard(),
      ],
    );
  }
}

class _CurrentSessionPermissionCard extends StatelessWidget {
  const _CurrentSessionPermissionCard();

  static final AccountingPermissionRepository _permissionRepository =
      AccountingPermissionRepository();
  static final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return const _InfoCard(
        icon: Icons.person_off_rounded,
        title: 'Aktif oturum yok',
        body:
            'Yetki senkronizasyonu i\u00e7in giri\u015f yap\u0131lm\u0131\u015f kullan\u0131c\u0131 gerekir.',
      );
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: _permissionRepository.watchUserPermissionData(uid),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final rawPermissions = data['permissions'];
        final normalized = AccountingPermissionBridge.normalize(
          rawPermissions is Map
              ? Map<String, dynamic>.from(rawPermissions)
              : const <String, dynamic>{},
        );

        final activeBusinessId =
            (data['activeBusinessId'] ??
                    data['selectedBusinessId'] ??
                    data['staffBusinessId'] ??
                    data['businessId'] ??
                    '')
                .toString();

        final role =
            (data['role'] ?? data['accountType'] ?? data['userType'] ?? '-')
                .toString();

        final enabled = AccountingPermissionKeys.all
            .where((key) => normalized[key] == true)
            .toList();

        return Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Aktif oturum yetki durumu'),
                const SizedBox(height: 10),
                _MiniInfoRow(label: 'Rol', value: role),
                _MiniInfoRow(
                  label: '\u0130\u015fletme',
                  value: activeBusinessId.isEmpty
                      ? 'Ba\u011fl\u0131 i\u015fletme yok'
                      : activeBusinessId,
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 3)
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  const Text(
                    'Bu kullanıcı için muhasebe yetki kaydı henüz görünmüyor.',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  )
                else if (enabled.isEmpty)
                  const Text(
                    'Bu oturumda aktif muhasebe yetkisi g\u00f6r\u00fcnm\u00fcyor.',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in enabled)
                        Chip(
                          label: Text(
                            AccountingPermissionLabels.labels[key] ?? key,
                          ),
                          labelStyle: const TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFEFFBF4),
                          side: const BorderSide(color: Color(0xFFBBF7D0)),
                        ),
                    ],
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Bu kart aktif oturumun muhasebe modülünde hangi işlemleri yapabileceğini gösterir.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionsHeader extends StatelessWidget {
  const _PermissionsHeader();

  @override
  Widget build(BuildContext context) {
    return const _WhiteInfoCard(
      icon: Icons.admin_panel_settings_rounded,
      body:
          'Muhasebe modülünde görüntüleme, satış, gider, alacak ve rapor yetkileri ayrı ayrı yönetilir.',
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard();

  @override
  Widget build(BuildContext context) {
    return const _InfoCard(
      icon: Icons.lock_outline_rounded,
      title: 'Yetki güvenliği',
      body:
          'Her finansal işlem işletme rolü ve personel yetkisiyle kontrol edilir.',
    );
  }
}

class _PermissionPresetCard extends StatelessWidget {
  const _PermissionPresetCard();

  @override
  Widget build(BuildContext context) {
    final presets = <_PresetData>[
      _PresetData('Owner', AccountingPermissionBridge.ownerDefaults()),
      _PresetData('Kasa', AccountingPermissionBridge.cashierDefaults()),
      _PresetData('Muhasebe', AccountingPermissionBridge.accountingDefaults()),
      _PresetData(
        'Sadece g\u00f6r\u00fcnt\u00fcleme',
        AccountingPermissionBridge.viewOnlyDefaults(),
      ),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Haz\u0131r yetki presetleri'),
            const SizedBox(height: 10),
            for (final preset in presets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PresetRow(preset: preset),
              ),
            const SizedBox(height: 6),
            const Text(
              'Bu presetler personel formundaki switch gruplar\u0131yla ayn\u0131 yetki setlerini temsil eder.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.preset});

  final _PresetData preset;

  @override
  Widget build(BuildContext context) {
    final enabled = preset.permissions.entries
        .where((entry) => entry.value)
        .map(
          (entry) => AccountingPermissionLabels.labels[entry.key] ?? entry.key,
        )
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.manage_accounts_rounded, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  enabled.isEmpty ? 'Yetki yok' : enabled,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.25,
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.data});

  final _PermissionRowData data;

  @override
  Widget build(BuildContext context) {
    final label =
        AccountingPermissionLabels.labels[data.keyName] ?? data.keyName;

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEFFBF4),
              child: Icon(Icons.check_rounded, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.keyName,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    data.description,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.roleHint,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntegrationNoteCard extends StatelessWidget {
  const _IntegrationNoteCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('Ba\u011flant\u0131 plan\u0131'),
            SizedBox(height: 10),
            _Bullet(
              'Owner t\u00fcm muhasebe yetkilerine sahip say\u0131l\u0131r.',
            ),
            _Bullet(
              'Personel için permissions map içinde financeRead, saleProcess, paymentCollect, saleCancel, paymentRefund, expenseWrite, receivableManage, reportsRead ve reportExport tutulur.',
            ),
            _Bullet(
              'Personel paneli açılırken işletme yetkileri aktif oturuma güvenli şekilde taşınır.',
            ),
            _Bullet(
              'Sunucu tarafı her finansal işlemde gerekli yetki anahtarını kontrol eder.',
            ),
            _Bullet(
              'UI kaydetme butonlar\u0131 ger\u00e7ek function deploy/test tamamlanmadan a\u00e7\u0131lmayacak.',
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteInfoCard extends StatelessWidget {
  const _WhiteInfoCard({required this.icon, required this.body});

  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF10B981), size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                body,
                style: const TextStyle(
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFEFFBF4),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF10B981)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right_rounded, color: Color(0xFF10B981)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        fontSize: 15,
      ),
    );
  }
}

class _PermissionRowData {
  const _PermissionRowData({
    required this.keyName,
    required this.description,
    required this.roleHint,
  });

  final String keyName;
  final String description;
  final String roleHint;
}

class _PresetData {
  const _PresetData(this.title, this.permissions);

  final String title;
  final Map<String, bool> permissions;
}
