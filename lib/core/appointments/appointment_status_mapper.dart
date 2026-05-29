import 'appointment_status.dart';

class AppointmentStatusMapper {
  const AppointmentStatusMapper._();

  static AppointmentStatus fromAny(Object? raw) {
    final value = _normalize(raw);

    switch (value) {
      case 'pending':
      case 'active':
      case 'bekliyor':
      case 'wait':
      case 'waiting':
      case 'open':
      case 'new':
        return AppointmentStatus.pending;

      case 'confirmed':
      case 'confirm':
      case 'approved':
      case 'onaylandi':
      case 'onaylandı':
        return AppointmentStatus.confirmed;

      case 'inprogress':
      case 'in_progress':
      case 'started':
      case 'start':
      case 'islembasladi':
      case 'işlembasladi':
      case 'işlembasladı':
      case 'islemde':
      case 'işlemde':
        return AppointmentStatus.inProgress;

      case 'completed':
      case 'complete':
      case 'done':
      case 'finished':
      case 'bitti':
      case 'tamamlandi':
      case 'tamamlandı':
        return AppointmentStatus.completed;

      case 'cancelledbyuser':
      case 'canceledbyuser':
      case 'cancelled':
      case 'canceled':
      case 'iptal':
      case 'usercancelled':
      case 'usercanceled':
      case 'musteriiptal':
      case 'müşteriiptal':
      case 'kullaniciiptal':
      case 'kullanıcıiptal':
        return AppointmentStatus.cancelledByUser;

      case 'cancelledbybusiness':
      case 'canceledbybusiness':
      case 'businesscancelled':
      case 'businesscanceled':
      case 'isletmeiptal':
      case 'işletmeiptal':
        return AppointmentStatus.cancelledByBusiness;

      case 'noshow':
      case 'no_show':
      case 'gelmedi':
      case 'yok':
        return AppointmentStatus.noShow;

      case 'late':
      case 'delayed':
      case 'gecikti':
      case 'geçikti':
      case 'geciken':
      case 'geçkaldı':
      case 'geckaldi':
        return AppointmentStatus.late;

      case 'paymentpending':
      case 'payment_pending':
      case 'tahsilatbekliyor':
      case 'odembekliyor':
      case 'odemebekliyor':
      case 'ödemebekliyor':
        return AppointmentStatus.paymentPending;

      case 'paid':
      case 'odendi':
      case 'ödendi':
      case 'paymentdone':
      case 'paymentcompleted':
        return AppointmentStatus.paid;

      default:
        return AppointmentStatus.unknown;
    }
  }

  static String toKey(AppointmentStatus status) => status.key;

  static String labelOf(Object? raw) => fromAny(raw).trLabel;

  static bool isQueue(Object? raw) => fromAny(raw).isQueue;

  static bool isDone(Object? raw) => fromAny(raw).isDone;

  static bool isCancelledOrNoShow(Object? raw) {
    return fromAny(raw).isCancelledOrNoShow;
  }

  static String _normalize(Object? raw) {
    return (raw ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('_', '');
  }
}
