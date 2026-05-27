class BusinessRoleResult {
  const BusinessRoleResult.customer()
    : isBusiness = false,
      businessId = '',
      businessName = 'İşletme',
      businessData = const {};

  const BusinessRoleResult.business({
    required this.businessId,
    required this.businessName,
    required this.businessData,
  }) : isBusiness = true;

  final bool isBusiness;
  final String businessId;
  final String businessName;
  final Map<String, dynamic> businessData;
}
