import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/admin/data/admin_moderation_repository.dart';
import 'package:rxpro_mobile/features/admin/domain/admin_moderation_filter_policy.dart';
import 'package:rxpro_mobile/features/admin/presentation/admin_moderation_controller.dart';

part 'admin_moderation_playbook_part.dart';
part 'admin_moderation_support_part.dart';
part 'admin_moderation_queues_part.dart';
part 'admin_moderation_tiles_part.dart';
part 'admin_moderation_security_tiles_part.dart';

class AdminModerationPage extends StatefulWidget {
  AdminModerationPage({super.key, AdminModerationRepository? repository})
    : _repository = repository ?? AdminModerationRepository();

  final AdminModerationRepository _repository;

  @override
  State<AdminModerationPage> createState() => _AdminModerationPageState();
}

class _AdminModerationPageState extends State<AdminModerationPage> {
  final TextEditingController _searchController = TextEditingController();
  final AdminModerationController _controller = AdminModerationController();

  AdminModerationRepository get _repository => widget._repository;

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Moderasyon')),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
          _ModerationFilterBar(
            controller: _searchController,
            statusFilter: _controller.statusFilter,
            onQueryChanged: _controller.setQuery,
            onStatusChanged: (value) {
              if (value == null) return;
              _controller.setStatusFilter(value);
            },
          ),
          const SizedBox(height: 18),
          const _ModerationPlaybookCard(),
          const SizedBox(height: 18),
          _SectionHeader(
            icon: Icons.verified_user_outlined,
            title: 'İşletme sahiplenme kuyruğu',
          ),
          _ClaimRequestList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'İçerik şikayetleri',
          ),
          _PostReportList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.rate_review_outlined,
            title: 'Yorum şikayetleri',
          ),
          _ReviewReportList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.local_offer_outlined,
            title: 'Kampanya şikayetleri',
          ),
          _CampaignReportList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.policy_outlined, title: 'Abuse log'),
          _AbuseLogList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(icon: Icons.history_rounded, title: 'Admin audit log'),
          _AdminAuditLogList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.block_outlined,
            title: 'Engelleme kayitlari',
          ),
          _ModerationBlockList(
            repository: _repository,
            query: _controller.query,
            statusFilter: _controller.statusFilter,
          ),
            ],
          );
        },
      ),
    );
  }
}
