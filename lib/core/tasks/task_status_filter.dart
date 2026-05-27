import 'package:rxpro_mobile/core/appointments/appointment_status.dart';
import 'package:rxpro_mobile/core/appointments/appointment_status_mapper.dart';

enum TaskStatusBucket { queue, done, cancelled }

extension TaskStatusBucketX on TaskStatusBucket {
  String get trLabel {
    switch (this) {
      case TaskStatusBucket.queue:
        return 'İş Kuyruğu';
      case TaskStatusBucket.done:
        return 'Biten';
      case TaskStatusBucket.cancelled:
        return 'İptal / Gelmedi';
    }
  }
}

class TaskStatusFilter {
  const TaskStatusFilter._();

  static TaskStatusBucket bucketOf(Object? rawStatus) {
    final status = AppointmentStatusMapper.fromAny(rawStatus);

    if (status.isDone) return TaskStatusBucket.done;
    if (status.isCancelledOrNoShow) return TaskStatusBucket.cancelled;
    return TaskStatusBucket.queue;
  }

  static bool belongsTo(Object? rawStatus, TaskStatusBucket bucket) {
    return bucketOf(rawStatus) == bucket;
  }

  static List<String> keysFor(TaskStatusBucket bucket) {
    switch (bucket) {
      case TaskStatusBucket.queue:
        return const ['pending', 'confirmed', 'late', 'inProgress'];
      case TaskStatusBucket.done:
        return const ['completed', 'paid', 'paymentPending'];
      case TaskStatusBucket.cancelled:
        return const ['cancelledByUser', 'cancelledByBusiness', 'noShow'];
    }
  }

  static bool canStart(Object? rawStatus) {
    return AppointmentStatusMapper.fromAny(rawStatus).canStart;
  }

  static bool canComplete(Object? rawStatus) {
    return AppointmentStatusMapper.fromAny(rawStatus).canComplete;
  }

  static bool shouldCreateFinanceRecord(Object? rawStatus) {
    return AppointmentStatusMapper.fromAny(rawStatus).shouldCreateFinanceRecord;
  }
}
