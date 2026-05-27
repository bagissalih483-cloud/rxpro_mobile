import 'auth_status_model.dart';

class BusinessAccountModel {
  final String id;
  final String ownerUid;
  final String businessName;
  final String category;
  final String phone;
  final String address;
  final BusinessStatus businessStatus;
  final bool ownerEmailVerified;
  final bool ownerPhoneVerified;
  final bool adminApproved;

  const BusinessAccountModel({
    required this.id,
    required this.ownerUid,
    required this.businessName,
    required this.category,
    required this.phone,
    required this.address,
    required this.businessStatus,
    required this.ownerEmailVerified,
    required this.ownerPhoneVerified,
    required this.adminApproved,
  });

  bool get canGoLive {
    return businessStatus == BusinessStatus.active && adminApproved;
  }

  BusinessAccountModel copyWith({
    String? id,
    String? ownerUid,
    String? businessName,
    String? category,
    String? phone,
    String? address,
    BusinessStatus? businessStatus,
    bool? ownerEmailVerified,
    bool? ownerPhoneVerified,
    bool? adminApproved,
  }) {
    return BusinessAccountModel(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      businessStatus: businessStatus ?? this.businessStatus,
      ownerEmailVerified: ownerEmailVerified ?? this.ownerEmailVerified,
      ownerPhoneVerified: ownerPhoneVerified ?? this.ownerPhoneVerified,
      adminApproved: adminApproved ?? this.adminApproved,
    );
  }

  Map<String, dynamic> toMap() {
    final now = DateTime.now().toIso8601String();

    return {
      'id': id,
      'ownerUid': ownerUid,
      'businessName': businessName,
      'category': category,
      'phone': phone,
      'address': address,
      'businessStatus': businessStatus.name,
      'ownerEmailVerified': ownerEmailVerified,
      'ownerPhoneVerified': ownerPhoneVerified,
      'adminApproved': adminApproved,
      'testMode': true,
      'createdAt': now,
      'updatedAt': now,
    };
  }

  factory BusinessAccountModel.fromMap(Map<String, dynamic> map) {
    return BusinessAccountModel(
      id: map['id']?.toString() ?? '',
      ownerUid: map['ownerUid']?.toString() ?? '',
      businessName: map['businessName']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      businessStatus: BusinessStatus.values.firstWhere(
        (item) => item.name == map['businessStatus'],
        orElse: () => BusinessStatus.active,
      ),
      ownerEmailVerified: map['ownerEmailVerified'] == true,
      ownerPhoneVerified: map['ownerPhoneVerified'] == true,
      adminApproved: map['adminApproved'] == true,
    );
  }
}
