import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxpro_mobile/core/firestore/firestore_collections.dart';
import 'package:rxpro_mobile/core/realtime/rx_notification_service.dart';
import 'package:rxpro_mobile/core/services/app_observability_service.dart';
import 'package:rxpro_mobile/features/appointments/data/appointment_slot_lock_release.dart';
import 'package:rxpro_mobile/features/appointments/domain/appointment_state_transition_policy.dart';

class CustomerAppointmentActionService {
  CustomerAppointmentActionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _firestore.collection(FirestoreCollections.appointments);

  Future<void> cancelByCustomer({
    required CustomerAppointmentActionTarget target,
    required String reason,
  }) async {
    final ref = _appointments.doc(target.id);
    final current = await ref.get();
    final currentData = current.data() ?? const <String, dynamic>{};

    if (!AppointmentStateTransitionPolicy.canCancelByCustomer(
      currentData['status'] ?? currentData['appointmentStatus'],
    )) {
      return;
    }

    final batch = _firestore.batch();
    batch.set(ref, {
      ...AppointmentStateTransitionPolicy.customerCancellationFields(
        reason: reason,
      ),
      'businessNoticeTitle': 'Bireysel kullanici randevuyu iptal etti',
      'businessNoticeBody': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledAtLocalIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final slotRef in AppointmentSlotLockRelease.refsForAppointment(
      firestore: _firestore,
      appointment: currentData,
    )) {
      batch.delete(slotRef);
    }
    await batch.commit();

    await notifyBusiness(
      target: target,
      type: 'appointment_cancelled_by_customer',
      title: 'Bireysel kullanici randevuyu iptal etti',
      body:
          '${target.businessName} randevusu bireysel kullanici tarafindan iptal edildi. Gerekce: $reason',
    );

    _logCancellation(
      appointmentId: target.id,
      actorRole: 'customer',
      reason: reason,
    );
  }

  Future<void> acceptPostpone({
    required CustomerAppointmentActionTarget target,
  }) async {
    final ref = _appointments.doc(target.id);

    await ref.set({
      'status': 'active',
      'appointmentStatus': 'active',
      'state': 'active',
      'isActive': true,
      'isCancelled': false,
      'dateText': target.postponeDateText,
      'appointmentDate': target.postponeDateKey.isEmpty
          ? target.postponeDateText
          : target.postponeDateKey,
      'dateKey': target.postponeDateKey,
      'timeText': target.postponeTimeText,
      'appointmentTime': target.postponeTimeText,
      if (target.postponeStartAt != null) 'startAt': target.postponeStartAt,
      if (target.postponeStartAtIso.isNotEmpty)
        'startAtIso': target.postponeStartAtIso,
      'postponeRequestStatus': 'accepted',
      'customerApprovalStatus': 'accepted',
      'postponeAcceptedAt': FieldValue.serverTimestamp(),
      'postponeAcceptedAtLocalIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await notifyBusiness(
      target: target,
      type: 'appointment_postpone_accepted',
      title: 'Erteleme talebi kabul edildi',
      body:
          'Bireysel kullanici ${target.postponeDateText} ${target.postponeTimeText} erteleme talebini kabul etti.',
    );
  }

  Future<void> rejectPostponeAndCancel({
    required CustomerAppointmentActionTarget target,
    required String reason,
  }) async {
    final ref = _appointments.doc(target.id);
    final current = await ref.get();
    final currentData = current.data() ?? const <String, dynamic>{};

    if (!AppointmentStateTransitionPolicy.canCancelByCustomer(
      currentData['status'] ?? currentData['appointmentStatus'],
    )) {
      return;
    }

    final batch = _firestore.batch();
    batch.set(ref, {
      ...AppointmentStateTransitionPolicy.customerCancellationFields(
        reason: reason,
      ),
      'postponeRequestStatus': 'rejected',
      'customerApprovalStatus': 'rejected',
      'postponeRejectedReason': reason,
      'postponeRejectedAt': FieldValue.serverTimestamp(),
      'postponeRejectedAtLocalIso': DateTime.now().toIso8601String(),
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledAtLocalIso': DateTime.now().toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final slotRef in AppointmentSlotLockRelease.refsForAppointment(
      firestore: _firestore,
      appointment: currentData,
    )) {
      batch.delete(slotRef);
    }
    await batch.commit();

    await notifyBusiness(
      target: target,
      type: 'appointment_postpone_rejected_cancelled',
      title: 'Erteleme reddedildi ve randevu iptal edildi',
      body:
          'Bireysel kullanici erteleme talebini reddetti ve randevuyu iptal etti. Gerekce: $reason',
    );

    _logCancellation(
      appointmentId: target.id,
      actorRole: 'customer',
      reason: 'postpone_rejected',
    );
  }

  Future<void> notifyBusiness({
    required CustomerAppointmentActionTarget target,
    required String type,
    required String title,
    required String body,
  }) async {
    var resolvedBusinessId = target.businessId.trim();
    var resolvedBusinessName = target.businessName.trim();
    var resolvedOwnerUid = target.businessOwnerUid.trim();

    if (resolvedBusinessId.isEmpty ||
        resolvedBusinessName.isEmpty ||
        resolvedOwnerUid.isEmpty) {
      try {
        final snap = await _appointments.doc(target.id).get();
        final data = snap.data() ?? <String, dynamic>{};

        if (resolvedBusinessId.isEmpty) {
          resolvedBusinessId = _clean(data['businessId']);
        }

        if (resolvedBusinessName.isEmpty) {
          resolvedBusinessName = _clean(data['businessName']);
        }

        if (resolvedOwnerUid.isEmpty) {
          resolvedOwnerUid = _clean(
            data['businessOwnerUid'] ?? data['ownerUid'],
          );
        }
      } catch (_) {
        // Notification fallback must not block the appointment action.
      }
    }

    if (resolvedBusinessId.isEmpty) return;

    final actorUid = _auth.currentUser?.uid;

    await RxNotificationService.createBusinessNotification(
      businessId: resolvedBusinessId,
      businessName: resolvedBusinessName.isEmpty
          ? 'Kurumsal Kullanıcı'
          : resolvedBusinessName,
      recipientUid: resolvedOwnerUid,
      actorUid: actorUid,
      type: type,
      title: title,
      body: body,
      route: 'businessAppointments',
      data: {
        'appointmentId': target.id,
        'customerUid': actorUid ?? '',
        'serviceName': target.serviceName,
        'dateText': target.dateText,
        'timeText': target.timeText,
      },
    );
  }

  void _logCancellation({
    required String appointmentId,
    required String actorRole,
    required String reason,
  }) {
    unawaited(
      AppObservabilityService.instance.logEvent(
        AppAnalyticsEvents.appointmentCancelled,
        parameters: <String, Object?>{
          'appointment_id': appointmentId,
          'actor_role': actorRole,
          'reason': reason,
        },
      ),
    );
  }

  static String _clean(dynamic value) => value?.toString().trim() ?? '';
}

class CustomerAppointmentActionTarget {
  const CustomerAppointmentActionTarget({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessOwnerUid,
    required this.serviceName,
    required this.dateText,
    required this.timeText,
    required this.postponeDateKey,
    required this.postponeDateText,
    required this.postponeTimeText,
    required this.postponeStartAt,
    required this.postponeStartAtIso,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String businessOwnerUid;
  final String serviceName;
  final String dateText;
  final String timeText;
  final String postponeDateKey;
  final String postponeDateText;
  final String postponeTimeText;
  final Timestamp? postponeStartAt;
  final String postponeStartAtIso;
}
