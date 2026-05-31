part of 'business_customers_page.dart';

class BusinessCustomersPage extends StatefulWidget {
  const BusinessCustomersPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessCustomersPage> createState() => _BusinessCustomersPageState();
}

class _BusinessCustomersPageState extends State<BusinessCustomersPage> {
  final BusinessCustomerRepository _repository = BusinessCustomerRepository();
  final BusinessCustomersController _controller = BusinessCustomersController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final Stream<List<BusinessCustomerRecord>> _customerStream;

  @override
  void initState() {
    super.initState();
    _customerStream = _repository.watchCustomersForBusiness(
      businessId: widget.businessId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openManualCustomerSheet() async {
    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 560,
      builder: (_) => _ManualCustomerSheet(
        businessId: widget.businessId,
        repository: _repository,
      ),
    );
  }

  Future<void> _openClassificationSheet(BusinessCustomerRecord record) async {
    await showRxAdaptiveModal<void>(
      context: context,
      desktopMaxWidth: 520,
      builder: (_) =>
          _ClassificationSheet(record: record, repository: _repository),
    );
  }

  void _openBulkMessage(List<BusinessCustomerRecord> visibleRecords) {
    if (visibleRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu filtrede toplu mesaj hedefi yok.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final segment = BusinessCustomerSegments.byId(_controller.selectedSegmentId);
    final audience = BusinessCustomerActionPolicy.bulkAudienceLabel(
      selectedSegmentId: _controller.selectedSegmentId,
      segmentLabel: segment.label,
    );
    final linkedCustomerCount = visibleRecords
        .where(
          (record) =>
              BusinessCustomerActionPolicy.canDirectMessage(record.customerUid),
        )
        .length;

    Navigator.of(context).pushNamed(
      AppRoutes.bulkMessageCreate,
      arguments: BusinessCampaignToolRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
        initialAudience: audience,
        initialEstimatedTargetCount: visibleRecords.length,
        audienceMetadata: <String, dynamic>{
          'source': 'business_customers_page',
          'segmentId': _controller.selectedSegmentId,
          'segmentLabel': segment.label,
          'filteredCount': visibleRecords.length,
          'linkedCustomerCount': linkedCustomerCount,
        },
      ),
    );
  }

  void _openDirectMessage(BusinessCustomerRecord record) {
    if (!BusinessCustomerActionPolicy.canDirectMessage(record.customerUid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            BusinessCustomerActionPolicy.directMessageUnavailableText(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.businessCustomerDirectMessage,
      arguments: BusinessCustomerDirectMessageRouteArgs(
        businessId: widget.businessId,
        businessName: widget.businessName,
        customerUid: record.customerUid,
        customerName: record.displayName,
        customerEmail: record.email,
        customerPhone: record.phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessId = widget.businessId.trim();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RxKeyboardShortcutScope(
      onSearch: () => _searchFocusNode.requestFocus(),
      onCreate: businessId.isEmpty ? null : () => _openManualCustomerSheet(),
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Müşteri Defteri'),
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: businessId.isEmpty ? null : _openManualCustomerSheet,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Müşteri Ekle'),
      ),
      body: businessId.isEmpty
          ? const _EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: 'İşletme bağlantısı bulunamadı',
              text:
                  'Müşteri defteri için önce kurumsal hesabın işletme kimliği çözülmeli.',
            )
          : StreamBuilder<List<BusinessCustomerRecord>>(
              stream: _customerStream,
              builder: (context, snapshot) {
                final records =
                    snapshot.data ?? const <BusinessCustomerRecord>[];
                final visibleRecords = _controller.visibleRecords(records);
                final stats = BusinessCustomerStats.fromRecords(records);

                if (snapshot.connectionState == ConnectionState.waiting &&
                    records.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                  children: [
                    BusinessCustomerHeaderPanel(
                      businessName: widget.businessName,
                      total: stats.total,
                      visible: visibleRecords.length,
                      onAddCustomer: _openManualCustomerSheet,
                      onBulkMessage: () => _openBulkMessage(visibleRecords),
                    ),
                    const SizedBox(height: 12),
                    _SearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _controller.setQuery,
                    ),
                    const SizedBox(height: 12),
                    _SegmentFilterBar(
                      selectedSegmentId: _controller.selectedSegmentId,
                      stats: stats,
                      onSelected: _controller.selectSegment,
                    ),
                    const SizedBox(height: 12),
                    if (records.isEmpty)
                      const _EmptyState(
                        icon: Icons.people_alt_outlined,
                        title: 'Henüz müşteri kaydı yok',
                        text:
                            'Randevu geldikçe müşteri geçmişi otomatik oluşur. İstersen ilk müşteriyi manuel ekleyebilirsin.',
                      )
                    else if (visibleRecords.isEmpty)
                      const _EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Bu filtrede müşteri yok',
                        text:
                            'Segmenti veya arama metnini değiştirerek müşteri defterini yeniden süzebilirsin.',
                      )
                    else
                      RxResponsiveGrid(
                        itemCount: visibleRecords.length,
                        maxColumns: 2,
                        itemBuilder: (context, index) {
                          final record = visibleRecords[index];
                          return _CustomerCard(
                            record: record,
                            onClassify: () =>
                                _openClassificationSheet(record),
                            onMessage: () => _openDirectMessage(record),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
        ),
        );
      },
    );
  }
}
