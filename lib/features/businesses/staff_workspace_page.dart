import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:flutter/material.dart';

import 'package:rxpro_mobile/core/appointments/appointment_status.dart';
import 'package:rxpro_mobile/core/appointments/appointment_status_mapper.dart';
import 'package:rxpro_mobile/core/tasks/task_status_filter.dart';

import 'package:rxpro_mobile/features/businesses/registered_businesses_page.dart';
import 'package:rxpro_mobile/features/businesses/business_customers_page.dart';
import 'package:rxpro_mobile/features/businesses/data/staff_workspace_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/pages/business_finance_page.dart';
import 'package:rxpro_mobile/features/campaigns/business_campaigns_page.dart';
import 'package:rxpro_mobile/features/finance/services/finance_record_service.dart';
import 'package:rxpro_mobile/features/stories/business_story_create_page.dart';

part 'presentation/widgets/staff_workspace_permissions_part.dart';
part 'presentation/widgets/staff_workspace_actions_part.dart';
part 'presentation/widgets/staff_workspace_widgets_part.dart';

enum _StaffTaskTab { queue, completed, cancelled }

/// Staff workspace keeps appointment and expense writes behind a repository.
class StaffWorkspacePage extends StatefulWidget {
  const StaffWorkspacePage({super.key, required this.memberData});

  final Map<String, dynamic> memberData;

  @override
  State<StaffWorkspacePage> createState() => _StaffWorkspacePageState();
}

class _StaffWorkspacePageState extends State<StaffWorkspacePage> {
  // Canli personel masraf yazma su an guvenli modda kapali tutulur.
  static const bool _staffExpenseLiveWriteEnabled = false;
  final Set<int> _expanded = <int>{0};
  final StaffWorkspaceRepository _workspaceRepository =
      StaffWorkspaceRepository();

  static const Map<String, String> _permissionLabels = {
    'viewAppointments': 'Randevuları görüntüleme',
    'createAppointments': 'Randevu oluşturma',
    'updateAppointments': 'Randevu düzenleme',
    'cancelAppointments': 'Randevu iptal etme',
    'completeAssignedAppointments': 'Kendi işlemini bitirme',
    'completeAnyAppointments': 'Tüm işlemleri tamamlama',
    'manageServices': 'Hizmetleri yönetme',
    'manageStaff': 'Çalışanları yönetme',
    'manageCampaigns': 'Kampanya oluşturma',
    'createPosts': 'Paylaşım / reklam yapma',
    'enterExpenses': 'Masraf girme',
    'viewFinance': 'Finans raporlarını görme',
    'financeRead': 'Muhasebe görüntüleme',
    'financeWrite': 'Satış ve tahsilat işlemleri',
    'canViewFinance': 'Muhasebe görüntüleme',
    'canManageFinance': 'Satış ve tahsilat işlemleri',
    'receivableManage': 'Alacak ve vade yönetimi',
    'canManageReceivables': 'Alacak ve vade yönetimi',
    'reportExport': 'Rapor/PDF dışa aktarma',
    'canExportReports': 'Rapor/PDF dışa aktarma',
    'viewCustomers': 'Bireysel kullanıcı listesini görme',
    'addCustomerNotes': 'Bireysel kullanıcı notu ekleme',
    'managePermissions': 'Rol ve yetki verme',
  };

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessName =
        (widget.memberData[FirestoreFields.businessName] ??
                'Kurumsal Kullanıcı')
            .toString();
    final businessLogoUrl =
        (widget.memberData['logoUrl'] ?? widget.memberData['photoUrl'] ?? '')
            .toString();
    final businessCategory =
        (widget.memberData[FirestoreFields.category] ?? 'Genel').toString();
    final staffName =
        (widget.memberData[FirestoreFields.staffName] ??
                _currentEmail ??
                'Personel')
            .toString();
    final roleLabel = (widget.memberData['roleLabel'] ?? 'Personel').toString();

    final hasFinanceAccess =
        _can('viewFinance') ||
        _can('manageFinance') ||
        _can('enterExpenses') ||
        _can('manageReceivables') ||
        _can('exportReports');

    final hasQuickActions =
        hasFinanceAccess ||
        _can('manageCampaigns') ||
        _can('createPosts') ||
        _can('viewCustomers');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Görevlerim'),
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _StaffPanelHeader(
            businessName: businessName,
            staffName: staffName,
            roleLabel: roleLabel,
          ),
          const SizedBox(height: 12),
          _StaffAccordion(
            title: 'Atanmış Randevular',
            subtitle: 'Yetkili olduğun işlemleri buradan tamamla',
            icon: Icons.event_available_outlined,
            expanded: _expanded.contains(0),
            onTap: () => _toggle(0),
            child: DefaultTabController(
              length: 3,
              child:
                  StreamBuilder<
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>
                  >(
                    stream: _assignedAppointmentsStream(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data ?? [];

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!_can('viewAppointments')) {
                        return const _InfoBox(
                          text:
                              'Randevuları görüntüleme yetkin yok. Kurumsal yetkiliden rol/yetki isteyebilirsin.',
                        );
                      }

                      final queueDocs = _taskDocsForTab(
                        docs,
                        _StaffTaskTab.queue,
                      );
                      final completedDocs = _taskDocsForTab(
                        docs,
                        _StaffTaskTab.completed,
                      );
                      final cancelledDocs = _taskDocsForTab(
                        docs,
                        _StaffTaskTab.cancelled,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: TabBar(
                              labelColor: const Color(0xFF0F172A),
                              unselectedLabelColor: const Color(0xFF64748B),
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: [
                                Tab(text: 'İş Kuyruğu (${queueDocs.length})'),
                                Tab(text: 'Biten (${completedDocs.length})'),
                                Tab(text: 'İptal (${cancelledDocs.length})'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 460,
                            child: TabBarView(
                              children: [
                                _buildTaskList(
                                  docs: queueDocs,
                                  tab: _StaffTaskTab.queue,
                                ),
                                _buildTaskList(
                                  docs: completedDocs,
                                  tab: _StaffTaskTab.completed,
                                ),
                                _buildTaskList(
                                  docs: cancelledDocs,
                                  tab: _StaffTaskTab.cancelled,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
            ),
          ),
          if (hasQuickActions)
            _StaffAccordion(
              title: hasFinanceAccess
                  ? 'Mali İşler ve Yetkili Hızlı İşlemler'
                  : 'Yetkili Hızlı İşlemler',
              subtitle: 'Bu personel hesabında açık olan işlem alanları',
              icon: Icons.flash_on_outlined,
              expanded: _expanded.contains(1),
              onTap: () => _toggle(1),
              child: Column(
                children: [
                  rxproManagementCenterQuickAction35K(context),
                  if (_can('enterExpenses'))
                    _QuickActionTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Masraf Gir',
                      subtitle:
                          'Malzeme, reklam, komisyon veya diğer giderleri kaydet.',
                      onTap: _openExpenseSheet,
                    ),
                  if (_can('manageCampaigns') || _can('createPosts'))
                    _QuickActionTile(
                      icon: Icons.campaign_outlined,
                      title: 'Kampanya / Paylaşım',
                      subtitle:
                          'Yetkine göre kampanya yönetimini veya hikaye paylaşımını aç.',
                      onTap: () {
                        if (_businessId.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İşletme bağlantısı bulunamadı.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _can('manageCampaigns')
                                ? BusinessCampaignsPage(
                                    businessId: _businessId,
                                    businessName: businessName,
                                  )
                                : BusinessStoryCreatePage(
                                    businessId: _businessId,
                                    businessName: businessName,
                                    businessLogoUrl: businessLogoUrl,
                                    category: businessCategory,
                                  ),
                          ),
                        );
                      },
                    ),
                  if (_can('viewCustomers'))
                    _QuickActionTile(
                      icon: Icons.people_alt_outlined,
                      title: 'Müşteri Defteri',
                      subtitle:
                          'Randevu geçmişi, manuel müşteri kayıtları ve müşteri notlarını görüntüle.',
                      onTap: () {
                        if (_businessId.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İşletme bağlantısı bulunamadı.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BusinessCustomersPage(
                              businessId: _businessId,
                              businessName: businessName,
                            ),
                          ),
                        );
                      },
                    ),
                  if (_can('viewFinance'))
                    _QuickActionTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Finans Görüntüleme',
                      subtitle: 'Gelir, gider ve dönem özetlerini görüntüle.',
                      onTap: () {
                        if (_businessId.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('İşletme bağlantısı bulunamadı.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BusinessFinancePage(
                              businessId: _businessId,
                              businessName: businessName,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          _StaffAccordion(
            title: 'Yetkilerim',
            subtitle: 'Bu hesapta açık olan işlem izinleri',
            icon: Icons.admin_panel_settings_outlined,
            expanded: _expanded.contains(2),
            onTap: () => _toggle(2),
            child: Column(
              children: _permissions.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Icon(
                        entry.value
                            ? Icons.check_circle_rounded
                            : Icons.cancel_outlined,
                        color: entry.value
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _permissionLabels[entry.key] ?? entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
