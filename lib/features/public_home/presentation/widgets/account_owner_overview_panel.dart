import 'package:flutter/material.dart';

import '../../../../core/theme/rx_ui.dart';
import '../../domain/account_owner_overview_model.dart';
import '../models/account_entry_context.dart';

class AccountOwnerOverviewPanel extends StatelessWidget {
  const AccountOwnerOverviewPanel({
    super.key,
    required this.account,
    required this.onAppointments,
    required this.onBulkMessage,
    required this.onCampaigns,
    required this.onProfile,
    required this.onFinance,
  });

  final AccountEntryContext account;
  final VoidCallback onAppointments;
  final VoidCallback onBulkMessage;
  final VoidCallback onCampaigns;
  final VoidCallback onProfile;
  final VoidCallback onFinance;

  @override
  Widget build(BuildContext context) {
    final business = account.business;
    final overview = AccountOwnerOverviewModel.fromBusinessData(
      business?.data ?? const <String, dynamic>{},
    );
    final businessName = (business?.name.trim().isNotEmpty ?? false)
        ? business!.name
        : 'Kurumsal özet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RxColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: RxColors.premium.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: RxColors.premium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RxColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Bugünün yönetim özeti ve hızlı işlemleri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RxText.tiny,
                    ),
                  ],
                ),
              ),
              RxStatusChip(
                label: overview.statusLabel,
                icon: overview.isActive
                    ? Icons.verified_outlined
                    : Icons.info_outline,
                color: overview.isActive ? RxColors.success : RxColors.warning,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _MetricTile(
                icon: Icons.calendar_month_outlined,
                title: 'Randevu',
                value: 'Bugün',
                subtitle: 'Takvimi yönet',
                color: RxColors.success,
                onTap: onAppointments,
              ),
              _MetricTile(
                icon: Icons.groups_outlined,
                title: 'Müşteri',
                value: 'CRM',
                subtitle: 'Segment ve mesaj',
                color: RxColors.primary,
                onTap: onBulkMessage,
              ),
              _MetricTile(
                icon: Icons.campaign_outlined,
                title: 'Kampanya',
                value: 'AI',
                subtitle: 'Yayınla ve duyur',
                color: RxColors.premium,
                onTap: onCampaigns,
              ),
              _MetricTile(
                icon: Icons.storefront_outlined,
                title: 'Profil',
                value: '%${overview.profileCompletionPercent}',
                subtitle: 'Tamamlanma',
                color: overview.profileCompletionPercent >= 75
                    ? RxColors.success
                    : RxColors.warning,
                onTap: onProfile,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAppointments,
                  icon: const Icon(Icons.add_task_outlined, size: 18),
                  label: const Text('Randevu'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBulkMessage,
                  icon: const Icon(Icons.sms_outlined, size: 18),
                  label: const Text('Toplu mesaj'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onFinance,
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              label: const Text('Finans ve operasyon detaylarına git'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: color, size: 18),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(title, style: RxText.cardTitle),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RxText.tiny,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
