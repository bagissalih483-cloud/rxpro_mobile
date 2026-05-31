part of 'customer_appointments_page.dart';

class _AppointmentItem {
  const _AppointmentItem({
    required this.id,
    required this.businessId,
    required this.businessOwnerUid,
    required this.businessName,
    required this.serviceName,
    required this.staffName,
    required this.dateText,
    required this.timeText,
    required this.status,
    required this.isActive,
    required this.isPast,
    required this.isCancelled,
    required this.isPostponeRequested,
    required this.customerApprovalStatus,
    required this.postponeDateKey,
    required this.postponeDateText,
    required this.postponeTimeText,
    required this.postponeStartAt,
    required this.postponeStartAtIso,
    required this.postponeRequestNote,
    required this.cancellationReason,
    required this.sortValue,
  });

  final String id;
  final String businessId;
  final String businessOwnerUid;
  final String businessName;
  final String serviceName;
  final String staffName;
  final String dateText;
  final String timeText;
  final String status;
  final bool isActive;
  final bool isPast;
  final bool isCancelled;
  final bool isPostponeRequested;
  final String customerApprovalStatus;
  final String postponeDateKey;
  final String postponeDateText;
  final String postponeTimeText;
  final Timestamp? postponeStartAt;
  final String postponeStartAtIso;
  final String postponeRequestNote;
  final String cancellationReason;
  final int sortValue;

  CustomerAppointmentActionTarget toActionTarget() {
    return CustomerAppointmentActionTarget(
      id: id,
      businessId: businessId,
      businessName: businessName,
      businessOwnerUid: businessOwnerUid,
      serviceName: serviceName,
      dateText: dateText,
      timeText: timeText,
      postponeDateKey: postponeDateKey,
      postponeDateText: postponeDateText,
      postponeTimeText: postponeTimeText,
      postponeStartAt: postponeStartAt,
      postponeStartAtIso: postponeStartAtIso,
    );
  }

  factory _AppointmentItem.fromCustomerDocument(
    CustomerAppointmentDocument doc,
  ) {
    return _AppointmentItem.fromData(id: doc.id, data: doc.data);
  }

  factory _AppointmentItem.fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final cancelled = CustomerAppointmentStatusPolicy.isCancelled(data);
    final active = CustomerAppointmentStatusPolicy.isActive(data);
    final past = CustomerAppointmentStatusPolicy.isCompleted(data);
    final postponed = CustomerAppointmentStatusPolicy.isPostponeRequested(data);
    final startAt = data['startAt'];

    int sort = 0;

    if (startAt is Timestamp) {
      sort = startAt.millisecondsSinceEpoch;
    } else {
      sort =
          DateTime.tryParse(
            CustomerAppointmentStatusPolicy.clean(data['startAtIso']),
          )?.millisecondsSinceEpoch ??
          DateTime.tryParse(
            CustomerAppointmentStatusPolicy.clean(data['createdAtLocalIso']),
          )?.millisecondsSinceEpoch ??
          0;
    }

    final postponeStartAtRaw = data['postponeRequestedStartAt'];
    final approval = CustomerAppointmentStatusPolicy.clean(
      data['customerApprovalStatus'] ?? data['postponeRequestStatus'],
    ).toLowerCase();

    return _AppointmentItem(
      id: id,
      businessId: CustomerAppointmentStatusPolicy.clean(data['businessId']),
      businessOwnerUid: CustomerAppointmentStatusPolicy.clean(
        data['businessOwnerUid'] ?? data['ownerUid'] ?? data['providerUid'],
      ),
      businessName:
          CustomerAppointmentStatusPolicy.clean(data['businessName']).isEmpty
          ? 'Kurumsal Kullanıcı'
          : CustomerAppointmentStatusPolicy.clean(data['businessName']),
      serviceName:
          CustomerAppointmentStatusPolicy.clean(data['serviceName']).isEmpty
          ? 'Hizmet'
          : CustomerAppointmentStatusPolicy.clean(data['serviceName']),
      staffName:
          CustomerAppointmentStatusPolicy.clean(data['staffName']).isEmpty
          ? 'Personel'
          : CustomerAppointmentStatusPolicy.clean(data['staffName']),
      dateText:
          CustomerAppointmentStatusPolicy.clean(
            data['dateText'] ?? data['appointmentDate'],
          ).isEmpty
          ? '-'
          : CustomerAppointmentStatusPolicy.clean(
              data['dateText'] ?? data['appointmentDate'],
            ),
      timeText:
          CustomerAppointmentStatusPolicy.clean(
            data['timeText'] ?? data['appointmentTime'],
          ).isEmpty
          ? '-'
          : CustomerAppointmentStatusPolicy.clean(
              data['timeText'] ?? data['appointmentTime'],
            ),
      status: CustomerAppointmentStatusPolicy.statusOf(data),
      isActive: active,
      isPast: past,
      isCancelled: cancelled,
      isPostponeRequested: postponed,
      customerApprovalStatus: approval.isEmpty ? '-' : approval,
      postponeDateKey: CustomerAppointmentStatusPolicy.clean(
        data['postponeRequestedDateKey'],
      ),
      postponeDateText: CustomerAppointmentStatusPolicy.clean(
        data['postponeRequestedDateText'] ?? data['postponedDateText'],
      ),
      postponeTimeText: CustomerAppointmentStatusPolicy.clean(
        data['postponeRequestedTimeText'] ?? data['postponedTimeText'],
      ),
      postponeStartAt: postponeStartAtRaw is Timestamp
          ? postponeStartAtRaw
          : null,
      postponeStartAtIso: CustomerAppointmentStatusPolicy.clean(
        data['postponeRequestedStartAtIso'],
      ),
      postponeRequestNote: CustomerAppointmentStatusPolicy.clean(
        data['postponeRequestNote'] ?? data['postponedNote'],
      ),
      cancellationReason: CustomerAppointmentStatusPolicy.clean(
        data['cancellationReason'] ?? data['postponeRejectedReason'],
      ),
      sortValue: sort,
    );
  }
}

extension _AppointmentItem37MDFix on _AppointmentItem {
  bool get isCompleted {
    final normalized = status.toLowerCase().trim();

    return normalized == 'completed' ||
        normalized == 'done' ||
        normalized == 'finished' ||
        normalized == 'tamamlandı' ||
        normalized == 'tamamlandı' ||
        normalized == 'sonuçlandı' ||
        normalized == 'sonuçlandı' ||
        normalized == 'resulted' ||
        isPast;
  }

  String get appointmentNo => '';
}
