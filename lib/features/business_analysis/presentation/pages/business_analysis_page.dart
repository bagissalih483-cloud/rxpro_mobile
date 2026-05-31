import 'package:flutter/material.dart';

import 'package:rxpro_mobile/app/app_routes.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/business_analysis_controller.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/models/business_analysis_view_models.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/widgets/business_analysis_widgets.dart';
import 'package:rxpro_mobile/features/business_analysis/services/business_analysis_ai_service.dart';
import 'package:rxpro_mobile/features/business_analysis/services/business_analysis_computation_service.dart';
import 'package:rxpro_mobile/features/business_analysis/data/business_analysis_repository.dart';

class BusinessAnalysisPage extends StatefulWidget {
  const BusinessAnalysisPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  @override
  State<BusinessAnalysisPage> createState() => _BusinessAnalysisPageState();
}

class _BusinessAnalysisPageState extends State<BusinessAnalysisPage> {
  final BusinessAnalysisRepository _analysisRepository =
      BusinessAnalysisRepository();
  final BusinessAnalysisAiService _aiService = BusinessAnalysisAiService();
  final BusinessAnalysisComputationService _computation =
      BusinessAnalysisComputationService();
  late final BusinessAnalysisController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BusinessAnalysisController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime get rangeStart => _controller.rangeStart;

  DateTime get rangeEndExclusive => _controller.rangeEndExclusive;

  String get periodLabel => _controller.periodLabel;

  String get periodTitle {
    if (_controller.periodMode == 0) return _computation.dateText(rangeStart);

    if (_controller.periodMode == 1) {
      final endInclusive = rangeEndExclusive.subtract(const Duration(days: 1));
      return '${_computation.dateText(rangeStart)} - ${_computation.dateText(endInclusive)}';
    }

    return _computation.monthTitle(_controller.anchorDate);
  }

  void _previousPeriod() => _controller.previousPeriod();

  void _nextPeriod() => _controller.nextPeriod();

  Future<BusinessAnalysisData> _load() async {
    final appointmentRows = await _analysisRepository
        .fetchAppointmentDocumentsForAnalysis(businessId: widget.businessId);

    final productSaleRows = await _analysisRepository
        .safeFetchProductSaleDocumentsForAnalysis(
          businessId: widget.businessId,
        );

    final productPurchaseRows = await _analysisRepository
        .safeFetchProductPurchaseDocumentsForAnalysis(
          businessId: widget.businessId,
        );

    return _computation.buildPeriodData(
      appointmentRows: appointmentRows,
      productSaleRows: productSaleRows,
      productPurchaseRows: productPurchaseRows,
      start: rangeStart,
      endExclusive: rangeEndExclusive,
    );
  }

  String _money(double value) => _computation.money(value);

  Future<void> _requestAiAnalysis(
    BusinessAnalysisData data,
    ComputedBusinessAnalysis computed,
  ) async {
    if (_controller.aiLoading) return;

    _controller.setAiLoading(true);

    try {
      var report = await _aiService.generateReport(
        _computation.aiPayload(
          businessId: widget.businessId,
          periodLabel: periodLabel,
          rangeStart: rangeStart,
          rangeEndExclusive: rangeEndExclusive,
          periodTitle: periodTitle,
          data: data,
          computed: computed,
        ),
      );

      if (report.isEmpty) {
        report = _computation.localAiReport(
          data,
          computed,
          periodLabel: periodLabel,
          periodMode: _controller.periodMode,
          anchorDate: _controller.anchorDate,
        );
      }

      if (!mounted) return;

      _controller.setAiReport(report);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI analizi alındı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _controller.setAiReport('\n\nAI bağlantı notu: ');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI bağlantısı kurulamadı. Yerel analiz gösterildi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) _controller.setAiLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FutureBuilder<BusinessAnalysisData>(
          future: _load(),
          builder: (context, snapshot) {
        final data = snapshot.data ?? const BusinessAnalysisData.empty();
        final computed = _computation.compute(data);
        final totalRevenue = computed.serviceRevenue + computed.productRevenue;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        final activeReport = _controller.aiReport.trim().isEmpty
            ? _computation.localAiReport(
                data,
                computed,
                periodLabel: periodLabel,
                periodMode: _controller.periodMode,
                anchorDate: _controller.anchorDate,
              )
            : _controller.aiReport.trim();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const Text(
                  'Kurumsal Kullanıcı Analizi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hizmet, ürün, hasılat ve bireysel kullanıcı hareketleri',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (loading) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 14),
                Center(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Günlük'),
                        icon: Icon(Icons.today_outlined),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Haftalık'),
                        icon: Icon(Icons.date_range_outlined),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: Text('Aylık'),
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                    selected: {_controller.periodMode},
                    onSelectionChanged: (value) {
                      _controller.selectPeriod(value.first);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                BusinessAnalysisPeriodSelector(
                  title: periodTitle,
                  onPrevious: _previousPeriod,
                  onNext: _nextPeriod,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.businessProductMovement,
                        arguments: BusinessProductMovementRouteArgs(
                          businessId: widget.businessId,
                          businessName: widget.businessName,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Ürün Satış / Alım Kaydı'),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    BusinessAnalysisMetricCard(
                      title: 'Hizmet',
                      value: '${data.services.length}',
                      subtitle: 'yapılan hizmet',
                      icon: Icons.spa_outlined,
                    ),
                    BusinessAnalysisMetricCard(
                      title: 'Ürün Satışı',
                      value: '${computed.soldProductCount}',
                      subtitle: 'satılan ürün',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    BusinessAnalysisMetricCard(
                      title: 'Ürün Alımı',
                      value: '${computed.purchasedProductCount}',
                      subtitle: 'alınan ürün',
                      icon: Icons.inventory_2_outlined,
                    ),
                    BusinessAnalysisMetricCard(
                      title: 'Hasılat',
                      value: _money(totalRevenue),
                      subtitle: 'hizmet + ürün',
                      icon: Icons.payments_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                BusinessAnalysisAiInsightCard(
                  text: activeReport,
                  loading: _controller.aiLoading,
                  onRefresh: loading
                      ? null
                      : () => _requestAiAnalysis(data, computed),
                ),
                const SizedBox(height: 14),
                BusinessAnalysisRevenueSplitCard(
                  serviceRevenue: computed.serviceRevenue,
                  productRevenue: computed.productRevenue,
                  totalRevenue: totalRevenue,
                  money: _money,
                ),
                const SizedBox(height: 14),
                BusinessAnalysisSection(
                  title: 'Hasılat / İşlem Saatleri',
                  emptyText: 'Bu dönem için saat verisi yok.',
                  entries: computed.topHours,
                  icon: Icons.schedule_outlined,
                ),
                const SizedBox(height: 14),
                BusinessAnalysisSection(
                  title: 'Hizmet Talebi',
                  emptyText: 'Bu dönem için hizmet verisi yok.',
                  entries: computed.topServices,
                  icon: Icons.spa_outlined,
                ),
                const SizedBox(height: 14),
                BusinessAnalysisSection(
                  title: 'Ürün Satışı',
                  emptyText: 'Bu dönem için ürün satışı verisi yok.',
                  entries: computed.topProducts,
                  icon: Icons.shopping_bag_outlined,
                ),
                const SizedBox(height: 14),
                BusinessAnalysisSection(
                  title: 'Personel Yoğunluğu',
                  emptyText: 'Bu dönem için personel verisi yok.',
                  entries: computed.topStaff,
                  icon: Icons.groups_outlined,
                ),
                const SizedBox(height: 14),
                BusinessAnalysisSection(
                  title: 'Bireysel Kullanıcı Profili',
                  emptyText:
                      'Bu dönem için bireysel kullanıcı profili verisi yok.',
                  entries: computed.topProfiles,
                  icon: Icons.person_search_outlined,
                ),
                const SizedBox(height: 14),
                BusinessAnalysisSuggestionCard(
                  title: 'Tahmini Beklenti',
                  body: totalRevenue <= 0
                      ? 'Bu dönem ödeme tutarı görünmüyor. Ciro tahmini için hizmet ve ürün satışlarında fiyat/tutar alanlarının düzenli kaydedilmesi gerekir.'
                      : 'Bu dönem toplam hasılat ${_money(totalRevenue)}. Benzer yoğunluk korunursa bir sonraki eş dönem için beklenen hasılat yaklaşık ${_money(totalRevenue)} seviyesinde kabul edilebilir.',
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }
}
