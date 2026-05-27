import 'package:cloud_functions/cloud_functions.dart';

class BusinessAnalysisAiService {
  BusinessAnalysisAiService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> generateReport(Map<String, dynamic> payload) async {
    final callable = _functions.httpsCallable('generateBusinessAnalysisAiHttp');
    final result = await callable.call(payload);
    final raw = result.data;

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return (map['report'] ??
              map['analysis'] ??
              map['text'] ??
              map['message'] ??
              '')
          .toString()
          .trim();
    }

    return raw?.toString().trim() ?? '';
  }
}
