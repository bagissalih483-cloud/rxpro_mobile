import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/features/business_analysis/presentation/models/business_analysis_view_models.dart';

class BusinessAnalysisComputationService {
  BusinessAnalysisData buildPeriodData({
    required List<Map<String, dynamic>> appointmentRows,
    required List<Map<String, dynamic>> productSaleRows,
    required List<Map<String, dynamic>> productPurchaseRows,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final services = <Map<String, dynamic>>[];
    final productSales = <Map<String, dynamic>>[];
    final productPurchases = <Map<String, dynamic>>[];

    for (final data in appointmentRows) {
      if (_isCancelledOrPassive(data)) continue;

      final dt = _dateOf(data);
      if (dt == null) continue;
      if (dt.isBefore(start) || !dt.isBefore(endExclusive)) continue;

      services.add(data);
    }

    for (final data in productSaleRows) {
      final dt = _dateOf(data);
      if (dt == null) continue;
      if (dt.isBefore(start) || !dt.isBefore(endExclusive)) continue;

      productSales.add(data);
    }

    for (final data in productPurchaseRows) {
      final dt = _dateOf(data);
      if (dt == null) continue;
      if (dt.isBefore(start) || !dt.isBefore(endExclusive)) continue;

      productPurchases.add(data);
    }

    return BusinessAnalysisData(
      services: services,
      productSales: productSales,
      productPurchases: productPurchases,
    );
  }

  DateTime? _dateOf(Map<String, dynamic> data) {
    for (final key in const [
      'startAt',
      'createdAt',
      'saleDate',
      'purchaseDate',
      'date',
      'expenseDate',
      'updatedAt',
    ]) {
      final raw = data[key];
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
    }

    for (final key in const [
      'startAtIso',
      'createdAtLocalIso',
      'saleDateIso',
      'purchaseDateIso',
      'appointmentDateIso',
      'dateIso',
    ]) {
      final raw = data[key]?.toString().trim() ?? '';
      if (raw.isEmpty) continue;

      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }

    final dateText =
        (data['appointmentDate'] ??
                data['dateText'] ??
                data['saleDateText'] ??
                data['purchaseDateText'] ??
                '')
            .toString();

    final timeText = (data['appointmentTime'] ?? data['timeText'] ?? '09:00')
        .toString();

    final parsedDate = _parseDate(dateText);
    if (parsedDate == null) return null;

    final parts = timeText.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, h, m);
  }

  DateTime? _parseDate(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final iso = DateTime.tryParse(clean);
    if (iso != null) return iso;

    final match = RegExp(
      r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})',
    ).firstMatch(clean);
    if (match == null) return null;

    final d = int.tryParse(match.group(1) ?? '');
    final m = int.tryParse(match.group(2) ?? '');
    final y = int.tryParse(match.group(3) ?? '');
    if (d == null || m == null || y == null) return null;

    return DateTime(y, m, d);
  }

  String _clean(dynamic value) => value?.toString().trim() ?? '';

  bool _isCancelledOrPassive(Map<String, dynamic> data) {
    final status = _clean(
      data['status'] ??
          data['appointmentStatus'] ??
          data['state'] ??
          data['bookingStatus'],
    ).toLowerCase();

    return data['isCancelled'] == true ||
        status.contains('cancel') ||
        status.contains('iptal') ||
        status.contains('passive') ||
        status.contains('pasif');
  }

  double _amountOf(Map<String, dynamic> data) {
    for (final key in const [
      'paidAmount',
      'amount',
      'price',
      'servicePrice',
      'totalPrice',
      'saleAmount',
      'totalAmount',
      'revenue',
      'income',
    ]) {
      final raw = data[key];

      if (raw is num) return raw.toDouble();

      final parsed = double.tryParse(
        raw?.toString().replaceAll(',', '.') ?? '',
      );
      if (parsed != null) return parsed;
    }

    return 0;
  }

  int _quantityOf(Map<String, dynamic> data) {
    for (final key in const [
      'quantity',
      'count',
      'piece',
      'pieces',
      'adet',
      'unitCount',
    ]) {
      final raw = data[key];

      if (raw is num) return raw.toInt();

      final parsed = int.tryParse(raw?.toString() ?? '');
      if (parsed != null) return parsed;
    }

    return 1;
  }

  String _serviceOf(Map<String, dynamic> data) {
    final value = _clean(
      data['serviceName'] ?? data['service'] ?? data['title'],
    );
    return value.isEmpty ? 'Belirtilmemiş Hizmet' : value;
  }

  String _productOf(Map<String, dynamic> data) {
    final value = _clean(
      data['productName'] ??
          data['name'] ??
          data['title'] ??
          data['itemName'] ??
          data['stockName'],
    );
    return value.isEmpty ? 'Belirtilmemiş Ürün' : value;
  }

  String _staffOf(Map<String, dynamic> data) {
    final value = _clean(
      data['staffName'] ??
          data['employeeName'] ??
          data['personnelName'] ??
          data['workerName'],
    );
    return value.isEmpty ? 'Genel' : value;
  }

  String _customerProfileOf(Map<String, dynamic> data) {
    final raw = _clean(
      data['customerType'] ??
          data['clientType'] ??
          data['segment'] ??
          data['customerSegment'],
    );

    if (raw.isNotEmpty) return raw;

    final isNew = data['isNewCustomer'] == true || data['newCustomer'] == true;
    if (isNew) return 'Yeni bireysel kullanıcı';

    final isReturning =
        data['isReturningCustomer'] == true ||
        data['returningCustomer'] == true;
    if (isReturning) return 'Tekrar gelen bireysel kullanıcı';

    return 'Genel bireysel kullanıcı';
  }

  String _hourOf(Map<String, dynamic> data) {
    final dt = _dateOf(data);
    if (dt == null) return 'Bilinmiyor';
    return '${dt.hour.toString().padLeft(2, '0')}:00';
  }

  List<MapEntry<String, int>> _topEntries(
    Map<String, int> map, {
    int limit = 5,
  }) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  String dateText(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  String monthTitle(DateTime value) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return '${months[value.month - 1]} ${value.year}';
  }

  String money(double value) {
    final rounded = value.round();
    final raw = rounded.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} TL';
  }

  ComputedBusinessAnalysis compute(BusinessAnalysisData data) {
    double serviceRevenue = 0;
    double productRevenue = 0;

    int soldProductCount = 0;
    int purchasedProductCount = 0;

    final serviceCounts = <String, int>{};
    final productCounts = <String, int>{};
    final staffCounts = <String, int>{};
    final hourCounts = <String, int>{};
    final customerProfiles = <String, int>{};

    for (final item in data.services) {
      serviceRevenue += _amountOf(item);

      final service = _serviceOf(item);
      final staff = _staffOf(item);
      final hour = _hourOf(item);
      final profile = _customerProfileOf(item);

      serviceCounts[service] = (serviceCounts[service] ?? 0) + 1;
      staffCounts[staff] = (staffCounts[staff] ?? 0) + 1;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      customerProfiles[profile] = (customerProfiles[profile] ?? 0) + 1;
    }

    for (final item in data.productSales) {
      final qty = _quantityOf(item);
      soldProductCount += qty;
      productRevenue += _amountOf(item);

      final product = _productOf(item);
      final hour = _hourOf(item);
      final profile = _customerProfileOf(item);

      productCounts[product] = (productCounts[product] ?? 0) + qty;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      customerProfiles[profile] = (customerProfiles[profile] ?? 0) + 1;
    }

    for (final item in data.productPurchases) {
      purchasedProductCount += _quantityOf(item);
    }

    return ComputedBusinessAnalysis(
      serviceRevenue: serviceRevenue,
      productRevenue: productRevenue,
      soldProductCount: soldProductCount,
      purchasedProductCount: purchasedProductCount,
      topHours: _topEntries(hourCounts),
      topServices: _topEntries(serviceCounts),
      topProducts: _topEntries(productCounts),
      topStaff: _topEntries(staffCounts),
      topProfiles: _topEntries(customerProfiles),
    );
  }

  Map<String, dynamic> aiPayload({
    required String businessId,
    required String periodLabel,
    required DateTime rangeStart,
    required DateTime rangeEndExclusive,
    required String periodTitle,
    required BusinessAnalysisData data,
    required ComputedBusinessAnalysis computed,
  }) {
    final totalRevenue = computed.serviceRevenue + computed.productRevenue;

    return {
      'businessId': businessId,
      'periodType': periodLabel,
      'periodStart': rangeStart.toIso8601String(),
      'periodEndExclusive': rangeEndExclusive.toIso8601String(),
      'periodTitle': periodTitle,
      'summary': {
        'serviceCount': data.services.length,
        'productSoldQuantity': computed.soldProductCount,
        'productPurchasedQuantity': computed.purchasedProductCount,
        'serviceRevenue': computed.serviceRevenue,
        'productRevenue': computed.productRevenue,
        'totalRevenue': totalRevenue,
        'averageRevenuePerService': data.services.isEmpty
            ? 0
            : computed.serviceRevenue / math.max(1, data.services.length),
      },
      'topHours': computed.topHours
          .map((e) => {'label': e.key, 'count': e.value})
          .toList(),
      'topServices': computed.topServices
          .map((e) => {'label': e.key, 'count': e.value})
          .toList(),
      'topProducts': computed.topProducts
          .map((e) => {'label': e.key, 'count': e.value})
          .toList(),
      'topStaff': computed.topStaff
          .map((e) => {'label': e.key, 'count': e.value})
          .toList(),
      'customerProfiles': computed.topProfiles
          .map((e) => {'label': e.key, 'count': e.value})
          .toList(),
    };
  }

  String localAiReport(
    BusinessAnalysisData data,
    ComputedBusinessAnalysis computed, {
    required String periodLabel,
    required int periodMode,
    required DateTime anchorDate,
  }) {
    final totalRevenue = computed.serviceRevenue + computed.productRevenue;

    if (data.services.isEmpty &&
        computed.soldProductCount == 0 &&
        computed.purchasedProductCount == 0) {
      return '$periodLabel dönem için henüz analiz üretmeye yetecek veri yok. İlk hedef, hizmet ve ürün hareketlerini düzenli kaydetmek olmalı.';
    }

    final bestHour = computed.topHours.isEmpty
        ? null
        : computed.topHours.first.key;
    final bestService = computed.topServices.isEmpty
        ? null
        : computed.topServices.first.key;
    final bestProduct = computed.topProducts.isEmpty
        ? null
        : computed.topProducts.first.key;
    final profile = computed.topProfiles.isEmpty
        ? null
        : computed.topProfiles.first.key;

    final expectedDaily = periodMode == 0
        ? totalRevenue
        : periodMode == 1
        ? totalRevenue / 7
        : totalRevenue /
              math.max(
                1,
                _daysInMonth(anchorDate),
              );

    final parts = <String>[
      '$periodLabel analizde ${data.services.length} hizmet işlemi, ${computed.soldProductCount} ürün satışı ve ${computed.purchasedProductCount} ürün alımı görünüyor.',
      'Toplam tahmini hasılat ${money(totalRevenue)}; günlük ortalama beklenti yaklaşık ${money(expectedDaily)}.',
    ];

    if (bestHour != null) {
      parts.add(
        'Hasılat ve işlem yoğunluğu en çok $bestHour bandında toplanıyor.',
      );
    }

    if (bestService != null) {
      parts.add('Hizmet tarafında öne çıkan işlem: $bestService.');
    }

    if (bestProduct != null) {
      parts.add('Ürün satışında öne çıkan ürün: $bestProduct.');
    }

    if (profile != null) {
      parts.add(
        'Bireysel kullanıcı profili tarafında baskın segment: $profile.',
      );
    }

    if (totalRevenue <= 0) {
      parts.add(
        'Ödeme tutarları kaydedilmediği için ciro tahmini düşük görünüyor.',
      );
    } else if (computed.soldProductCount == 0) {
      parts.add(
        'Ürün satışı görünmediği için çapraz satış potansiyeli değerlendirilebilir.',
      );
    } else {
      parts.add(
        'Ürün ve hizmet verisini birlikte izlemek stok planlaması ve kampanya zamanlaması için anlamlı hale gelmiş.',
      );
    }

    return parts.join(' ');
  }


  int _daysInMonth(DateTime value) {
    return DateTime(value.year, value.month + 1, 0).day;
  }
}
