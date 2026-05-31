import 'package:cloud_functions/cloud_functions.dart';

class AppointmentAdisyonService {
  AppointmentAdisyonService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<AppointmentAdisyonResult> ensurePendingAdisyonForAppointment({
    required String businessId,
    required String appointmentId,
    required Map<String, dynamic> appointmentData,
    required String actorUid,
    required String actorName,
    String? staffId,
    String? staffName,
  }) async {
    final cleanBusinessId = businessId.trim();
    final cleanAppointmentId = appointmentId.trim();

    if (cleanBusinessId.isEmpty || cleanAppointmentId.isEmpty) {
      return const AppointmentAdisyonResult.skipped();
    }

    final callable = _functions.httpsCallable(
      'accountingEnsureAppointmentAdisyon',
    );
    final result = await callable.call(<String, dynamic>{
      'businessId': cleanBusinessId,
      'appointmentId': cleanAppointmentId,
      'appointmentData': appointmentData,
      'actorName': actorName,
      'actorUid': actorUid,
      'staffId': staffId,
      'staffName': staffName,
    });

    final raw = result.data;
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return AppointmentAdisyonResult(
      saleId: (data['saleId'] ?? '').toString(),
      created: data['created'] == true,
    );
  }
}

class AppointmentAdisyonResult {
  const AppointmentAdisyonResult({required this.saleId, required this.created});

  const AppointmentAdisyonResult.skipped() : saleId = '', created = false;

  final String saleId;
  final bool created;
}
