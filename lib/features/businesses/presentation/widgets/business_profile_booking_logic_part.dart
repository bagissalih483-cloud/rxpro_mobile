part of '../../business_profile_page.dart';

extension _AppointmentTabLogic on _AppointmentTabState {
  Stream<List<_InlineService>> _servicesStream() {
    return BusinessProfileRepository()
        .watchBusinessServices(businessId: widget.businessId)
        .map((rows) {
          final list = rows
              .where((data) {
                return data[FirestoreFields.bookingEnabled] != false &&
                    data[FirestoreFields.isActive] != false;
              })
              .map((data) {
                return _InlineService(
                  id: data[FirestoreFields.id]?.toString() ?? '',
                  name:
                      data[FirestoreFields.serviceName]?.toString() ??
                      data[FirestoreFields.name]?.toString() ??
                      'Hizmet',
                  price: data[FirestoreFields.price]?.toString() ?? '',
                  duration:
                      data[FirestoreFields.durationMinutes]?.toString() ??
                      data[FirestoreFields.duration]?.toString() ??
                      '',
                );
              })
              .toList();

          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  Stream<List<_InlineStaff>> _staffStream() {
    return BusinessProfileRepository()
        .watchBusinessStaff(businessId: widget.businessId)
        .map((rows) {
          final list = rows
              .where((data) {
                return data[FirestoreFields.isActive] != false;
              })
              .map((data) {
                final serviceIds = BusinessProfileBookingPolicy.stringList(
                  data[FirestoreFields.serviceIds] ??
                      data[FirestoreFields.staffServiceIds] ??
                      data[FirestoreFields.allowedServiceIds],
                );

                return _InlineStaff(
                  id: data[FirestoreFields.id]?.toString() ?? '',
                  name:
                      data[FirestoreFields.staffName]?.toString() ??
                      data[FirestoreFields.name]?.toString() ??
                      'Personel',
                  uid:
                      (data[FirestoreFields.linkedUid] ??
                              data[FirestoreFields.staffUid] ??
                              data[FirestoreFields.userUid] ??
                              '')
                          .toString(),
                  email:
                      (data[FirestoreFields.staffEmail] ??
                              data[FirestoreFields.targetEmail] ??
                              data[FirestoreFields.email] ??
                              '')
                          .toString(),
                  serviceIds: serviceIds,
                );
              })
              .toList();

          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  List<DateTime> _days() {
    return BusinessProfileBookingPolicy.upcomingDays(now: DateTime.now());
  }

  String _dateText(DateTime date) {
    return BusinessProfileBookingPolicy.dateText(date);
  }

  String _shortDay(DateTime date) {
    return BusinessProfileBookingPolicy.shortDay(date);
  }

  List<_InlineService> _servicesForSelectedStaff(
    List<_InlineService> services,
  ) {
    if (_controller.selectedStaffId == null) return services;
    return services
        .where(
          (service) => _controller.selectedStaffCanProvideService(service.id),
        )
        .toList();
  }

  Future<void> _createAppointment() async {
    if (!_controller.hasRequiredSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hizmet, personel, tarih ve saat secin.')),
      );
      return;
    }

    _controller.setSaving(true);

    try {
      final result = await _appointmentBookingService.createCustomerAppointment(
        AppointmentBookingRequest(
          businessId: widget.businessId,
          businessName: widget.businessName,
          category: widget.category,
          serviceId: _controller.selectedServiceId!,
          serviceName: _controller.selectedServiceName ?? 'Hizmet',
          businessStaffId: _controller.selectedStaffId!,
          staffName: _controller.selectedStaffName ?? 'Personel',
          staffUid: _controller.selectedStaffUid ?? '',
          staffEmail: _controller.selectedStaffEmail ?? '',
          staffServiceIdsAtBooking: _controller.selectedStaffServiceIds,
          durationMinutes: _controller.selectedServiceDurationMinutes,
          dateText: _controller.selectedDateText!,
          timeText: _controller.selectedTimeText!,
        ),
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Expanded(child: Text('Randevunuz olusturuldu')),
              ],
            ),
            content: Text(
              'Randevunuz basariyla kaydedildi.\n\n'
              'Hizmet: ${result.serviceName}\n'
              'Personel: ${result.staffName}\n'
              'Tarih: ${result.dateText}\n'
              'Saat: ${result.timeText}\n\n'
              'Randevu No: ${result.appointmentId}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      _controller.resetAfterBooking();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Randevu olusturulamadi: $e')));
      }
    } finally {
      if (mounted) {
        _controller.setSaving(false);
      }
    }
  }
}
