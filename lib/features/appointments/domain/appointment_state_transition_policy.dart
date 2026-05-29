import 'package:rxpro_mobile/core/appointments/appointment_status.dart';
import 'package:rxpro_mobile/core/appointments/appointment_status_mapper.dart';

class AppointmentStateTransitionPolicy {
  const AppointmentStateTransitionPolicy._();

  static const String customerCancellationStatus = 'cancelledByUser';
  static const String businessCancellationStatus = 'cancelledByBusiness';
  static const String noShowStatus = 'noShow';

  static bool canCancelByCustomer(Object? rawStatus) {
    final status = AppointmentStatusMapper.fromAny(rawStatus);
    if (status == AppointmentStatus.unknown) return true;
    return !status.isDone && !status.isCancelledOrNoShow;
  }

  static bool canCancelByBusiness(Object? rawStatus) {
    final status = AppointmentStatusMapper.fromAny(rawStatus);
    if (status == AppointmentStatus.unknown) return true;
    return !status.isDone && !status.isCancelledOrNoShow;
  }

  static bool canMarkNoShow(Object? rawStatus) {
    final status = AppointmentStatusMapper.fromAny(rawStatus);
    return status == AppointmentStatus.pending ||
        status == AppointmentStatus.confirmed ||
        status == AppointmentStatus.late ||
        status == AppointmentStatus.inProgress ||
        status == AppointmentStatus.unknown;
  }

  static Map<String, Object> customerCancellationFields({
    required String reason,
  }) {
    return _terminalCancellationFields(
      status: customerCancellationStatus,
      cancelledBy: 'customer',
      reason: reason,
    );
  }

  static Map<String, Object> businessCancellationFields({
    required String reason,
  }) {
    return _terminalCancellationFields(
      status: businessCancellationStatus,
      cancelledBy: 'business',
      reason: reason,
    );
  }

  static Map<String, Object> noShowFields({required String reason}) {
    return <String, Object>{
      'status': noShowStatus,
      'appointmentStatus': noShowStatus,
      'state': noShowStatus,
      'isActive': false,
      'isCancelled': false,
      'isNoShow': true,
      'noShowReason': reason.trim(),
    };
  }

  static Map<String, Object> _terminalCancellationFields({
    required String status,
    required String cancelledBy,
    required String reason,
  }) {
    final cleanReason = reason.trim();
    return <String, Object>{
      'status': status,
      'appointmentStatus': status,
      'state': status,
      'isActive': false,
      'isCancelled': true,
      'cancelledBy': cancelledBy,
      'cancelReason': cleanReason,
      'cancellationReason': cleanReason,
    };
  }
}
