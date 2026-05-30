import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAppointmentStatusPolicy {
  const CustomerAppointmentStatusPolicy._();

  static String clean(Object? value) => value?.toString().trim() ?? '';

  static bool matchesCurrentUser(Map<String, dynamic> data, String uid) {
    return [
      data['customerUid'],
      data['customerId'],
      data['userId'],
      data['uid'],
      data['clientUid'],
    ].map(clean).contains(uid);
  }

  static String statusOf(Map<String, dynamic> data) {
    return clean(
      data['status'] ??
          data['appointmentStatus'] ??
          data['state'] ??
          data['bookingStatus'],
    ).toLowerCase();
  }

  static bool isCancelled(Map<String, dynamic> data) {
    final status = statusOf(data);
    if (status.contains('cancel')) return true;
    if (status.contains('iptal')) return true;
    if (data['isCancelled'] == true) return true;
    return false;
  }

  static bool isPostponeRequested(Map<String, dynamic> data) {
    final status = statusOf(data);
    final approval = clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return status == 'postpone_requested' ||
        status == 'reschedule_requested' ||
        approval == 'pending';
  }

  static bool isPast(Map<String, dynamic> data, {DateTime? now}) {
    final comparisonNow = now ?? DateTime.now();
    final startAt = data['startAt'];
    if (startAt is Timestamp) {
      return startAt.toDate().isBefore(comparisonNow);
    }

    final parsedIso = DateTime.tryParse(clean(data['startAtIso']));
    if (parsedIso != null) return parsedIso.isBefore(comparisonNow);

    return false;
  }

  static bool isActive(Map<String, dynamic> data, {DateTime? now}) {
    if (isCancelled(data)) return false;
    if (isPostponeRequested(data)) return false;
    if (isPast(data, now: now)) return false;

    final status = statusOf(data);
    if (status.isEmpty) return true;

    return [
      'active',
      'pending',
      'approved',
      'confirmed',
      'onayli',
      'onayl\u0131',
      'bekliyor',
    ].contains(status);
  }

  static bool isCompleted(Map<String, dynamic> data, {DateTime? now}) {
    if (isCancelled(data)) return false;
    if (isPostponeRequested(data)) return false;

    final status = statusOf(data);
    if ([
      'done',
      'completed',
      'complete',
      'gecmis',
      'ge\u00e7mi\u015f',
      'tamamlandi',
      'tamamland\u0131',
    ].contains(status)) {
      return true;
    }

    return isPast(data, now: now);
  }
}
