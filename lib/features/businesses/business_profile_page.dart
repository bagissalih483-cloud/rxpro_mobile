import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxpro_mobile/core/firestore/firestore_fields.dart';
import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_booking_request.dart';
import 'package:rxpro_mobile/features/appointments/service/appointment_booking_service.dart';

import '../../core/app_cache/app_cache_service.dart';
import '../../core/theme/rx_ui.dart';
import '../messages/messages_inbox_page.dart';
import '../business/widgets/business_profile_edit_button.dart';
import '../business/pages/business_profile_post_create_page.dart';
import '../business/widgets/business_profile_post_interactive_card.dart';
import 'package:rxpro_mobile/features/businesses/data/business_profile_repository.dart';

part 'presentation/widgets/business_profile_header_part.dart';
part 'presentation/widgets/business_profile_intro_part.dart';
part 'presentation/widgets/business_profile_booking_part.dart';
part 'presentation/widgets/business_profile_reviews_part.dart';

bool _rxProfileIsCorporateSession(Map<String, dynamic>? data) {
  if (data == null) return false;

  String clean(dynamic value) => value?.toString().trim().toLowerCase() ?? '';

  final accountKind = clean(data[FirestoreFields.accountKind]);
  final accountType = clean(data[FirestoreFields.accountType]);
  final userType = clean(data[FirestoreFields.userType]);
  final role = clean(data[FirestoreFields.role]);
  final legacyRole = clean(data[FirestoreFields.legacyRole]);

  final stringSignals = <String>[
    accountKind,
    accountType,
    userType,
    role,
    legacyRole,
  ];

  if (stringSignals.any(
    (value) =>
        value == 'business' ||
        value == 'corporate' ||
        value == 'corporatestaff' ||
        value == 'businessstaff' ||
        value == 'owner' ||
        value == 'kurumsal' ||
        value == 'isletme',
  )) {
    return true;
  }

  if (data[FirestoreFields.isBusiness] == true ||
      data[FirestoreFields.isBusinessOwner] == true ||
      data[FirestoreFields.businessAccount] == true) {
    return true;
  }

  final linkedBusinessId = clean(data[FirestoreFields.businessId]);
  final activeBusinessId = clean(data[FirestoreFields.activeBusinessId]);
  final selectedBusinessId = clean(data[FirestoreFields.selectedBusinessId]);
  final staffBusinessId = clean(data[FirestoreFields.staffBusinessId]);

  return linkedBusinessId.isNotEmpty ||
      activeBusinessId.isNotEmpty ||
      selectedBusinessId.isNotEmpty ||
      staffBusinessId.isNotEmpty;
}

/// Business profile keeps reads and profile actions behind repositories/services.
class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.category,
  });

  final String businessId;
  final String businessName;
  final String category;

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final BusinessProfileRepository _businessProfileRepository =
      BusinessProfileRepository();
  final AuthService _authService = AuthService();
  int selectedTab = 0;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _currentUserDocStream() {
    final uid = _authService.currentUser?.uid;
    return _businessProfileRepository.watchCurrentUserDocument(uid: uid);
  }

  int _displayIndexFromSelectedTab({
    required int selected,
    required bool disableAppointment,
  }) {
    if (!disableAppointment) return selected;
    if (selected == 2) return 1;
    return 0;
  }

  int _selectedTabFromDisplayIndex({
    required int displayIndex,
    required bool disableAppointment,
  }) {
    if (!disableAppointment) return displayIndex;
    return displayIndex == 0 ? 0 : 2;
  }

  Widget _tabContent({
    required int selected,
    required bool disableAppointment,
  }) {
    if (disableAppointment && selected == 1) {
      return const _BusinessBookingDisabledCard();
    }

    if (selected == 0) {
      return _IntroTab(
        businessId: widget.businessId,
        businessName: widget.businessName,
        category: widget.category,
      );
    }

    if (selected == 1) {
      return _AppointmentTab(
        businessId: widget.businessId,
        businessName: widget.businessName,
        category: widget.category,
      );
    }

    return _ReviewsTab(
      businessId: widget.businessId,
      businessName: widget.businessName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userStream = _currentUserDocStream();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userStream,
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data();
        final disableAppointment = _rxProfileIsCorporateSession(userData);

        final effectiveSelectedTab = disableAppointment && selectedTab == 1
            ? 0
            : selectedTab;

        return Scaffold(
          appBar: AppBar(title: const Text('Kurumsal Profil')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
            children: [
              _BusinessHeroCard(
                businessId: widget.businessId,
                businessName: widget.businessName,
                category: widget.category,
              ),
              const SizedBox(height: 12),
              _SegmentTabs(
                selectedIndex: _displayIndexFromSelectedTab(
                  selected: effectiveSelectedTab,
                  disableAppointment: disableAppointment,
                ),
                hideAppointment: disableAppointment,
                onChanged: (index) {
                  setState(() {
                    selectedTab = _selectedTabFromDisplayIndex(
                      displayIndex: index,
                      disableAppointment: disableAppointment,
                    );
                  });
                },
              ),
              if (disableAppointment) ...[
                const SizedBox(height: 10),
                const _BusinessBookingDisabledCard(),
              ],
              const SizedBox(height: 12),
              _tabContent(
                selected: effectiveSelectedTab,
                disableAppointment: disableAppointment,
              ),
            ],
          ),
        );
      },
    );
  }
}
