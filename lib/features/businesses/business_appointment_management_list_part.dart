part of 'business_appointment_management_page.dart';

extension _BusinessAppointmentManagementList on BusinessAppointmentManagementPage {
  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF64748B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBody(String tab) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _appointments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _empty('Randevular okunamadı: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = _filter(snapshot.data?.docs ?? [], tab);

        if (docs.isEmpty) {
          if (tab == 'cancelled') {
            return _empty('İptal edilen randevu yok.');
          }
          if (tab == 'postponed') {
            return _empty('Bekleyen erteleme talebi yok.');
          }
          return _empty('Mevcut randevu yok.');
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 18),
          itemCount: docs.length,
          itemBuilder: (context, index) =>
              _appointmentCard(context, docs[index], tab),
        );
      },
    );
  }
}
