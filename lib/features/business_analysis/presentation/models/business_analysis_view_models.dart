class BusinessAnalysisData {
  const BusinessAnalysisData({
    required this.services,
    required this.productSales,
    required this.productPurchases,
  });

  const BusinessAnalysisData.empty()
    : services = const [],
      productSales = const [],
      productPurchases = const [];

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> productSales;
  final List<Map<String, dynamic>> productPurchases;
}

class ComputedBusinessAnalysis {
  const ComputedBusinessAnalysis({
    required this.serviceRevenue,
    required this.productRevenue,
    required this.soldProductCount,
    required this.purchasedProductCount,
    required this.topHours,
    required this.topServices,
    required this.topProducts,
    required this.topStaff,
    required this.topProfiles,
  });

  final double serviceRevenue;
  final double productRevenue;
  final int soldProductCount;
  final int purchasedProductCount;
  final List<MapEntry<String, int>> topHours;
  final List<MapEntry<String, int>> topServices;
  final List<MapEntry<String, int>> topProducts;
  final List<MapEntry<String, int>> topStaff;
  final List<MapEntry<String, int>> topProfiles;
}

