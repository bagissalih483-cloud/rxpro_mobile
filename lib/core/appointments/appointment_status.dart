enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelledByUser,
  cancelledByBusiness,
  noShow,
  late,
  paymentPending,
  paid,
  unknown,
}

extension AppointmentStatusX on AppointmentStatus {
  String get key {
    switch (this) {
      case AppointmentStatus.pending:
        return 'pending';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.inProgress:
        return 'inProgress';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelledByUser:
        return 'cancelledByUser';
      case AppointmentStatus.cancelledByBusiness:
        return 'cancelledByBusiness';
      case AppointmentStatus.noShow:
        return 'noShow';
      case AppointmentStatus.late:
        return 'late';
      case AppointmentStatus.paymentPending:
        return 'paymentPending';
      case AppointmentStatus.paid:
        return 'paid';
      case AppointmentStatus.unknown:
        return 'unknown';
    }
  }

  String get trLabel {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Bekliyor';
      case AppointmentStatus.confirmed:
        return 'Onaylandı';
      case AppointmentStatus.inProgress:
        return 'İşlemde';
      case AppointmentStatus.completed:
        return 'Tamamlandı';
      case AppointmentStatus.cancelledByUser:
        return 'Kullanıcı iptal etti';
      case AppointmentStatus.cancelledByBusiness:
        return 'İşletme iptal etti';
      case AppointmentStatus.noShow:
        return 'Gelmedi';
      case AppointmentStatus.late:
        return 'Gecikti';
      case AppointmentStatus.paymentPending:
        return 'Tahsilat bekliyor';
      case AppointmentStatus.paid:
        return 'Ödendi';
      case AppointmentStatus.unknown:
        return 'Bilinmiyor';
    }
  }

  bool get isQueue {
    return this == AppointmentStatus.pending ||
        this == AppointmentStatus.confirmed ||
        this == AppointmentStatus.late ||
        this == AppointmentStatus.inProgress;
  }

  bool get isDone {
    return this == AppointmentStatus.completed ||
        this == AppointmentStatus.paid ||
        this == AppointmentStatus.paymentPending;
  }

  bool get isCancelledOrNoShow {
    return this == AppointmentStatus.cancelledByUser ||
        this == AppointmentStatus.cancelledByBusiness ||
        this == AppointmentStatus.noShow;
  }

  bool get canStart {
    return this == AppointmentStatus.pending ||
        this == AppointmentStatus.confirmed ||
        this == AppointmentStatus.late;
  }

  bool get canComplete {
    return this == AppointmentStatus.inProgress;
  }

  bool get shouldCreateFinanceRecord {
    return this == AppointmentStatus.completed ||
        this == AppointmentStatus.paymentPending ||
        this == AppointmentStatus.paid;
  }
}
