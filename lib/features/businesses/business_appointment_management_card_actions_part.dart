part of 'business_appointment_management_page.dart';

extension _BusinessAppointmentManagementCardActions
    on BusinessAppointmentManagementPage {
  Widget _appointmentCardActions(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        children: [
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () => _postponeAppointment(context, doc),
              icon: const Icon(Icons.schedule_outlined, size: 15),
              label: const Text('Ertele', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(78, 32),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: FilledButton.icon(
              onPressed: () => _cancelAppointment(context, doc),
              icon: const Icon(Icons.cancel_outlined, size: 15),
              label: const Text('Iptal', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                minimumSize: const Size(74, 32),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}