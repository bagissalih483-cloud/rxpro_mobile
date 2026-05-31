import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/features/businesses/data/business_appointment_management_repository.dart';
import 'package:rxpro_mobile/features/businesses/presentation/widgets/business_appointment_management_widgets.dart';

part 'business_appointment_management_data_part.dart';
part 'business_appointment_management_actions_part.dart';
part 'business_appointment_management_list_part.dart';
part 'business_appointment_management_card_part.dart';
part 'business_appointment_management_card_actions_part.dart';
part 'business_appointment_management_model_part.dart';

/// Business appointment management keeps database writes behind repositories.
class BusinessAppointmentManagementPage extends StatelessWidget {
  const BusinessAppointmentManagementPage({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  final String businessId;
  final String businessName;

  static final BusinessAppointmentManagementRepository _appointmentRepository =
      BusinessAppointmentManagementRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey('business-appointments-$businessId'),
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Randevu Yönetimi'),
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Mevcut'),
              Tab(text: 'İptal'),
              Tab(text: 'Erteleme'),
            ],
          ),
        ),
        body: Column(
          children: [
            BusinessAppointmentSummaryCard(
              businessName: businessName,
              stream: _appointments(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _tabBody('current'),
                  _tabBody('cancelled'),
                  _tabBody('postponed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
