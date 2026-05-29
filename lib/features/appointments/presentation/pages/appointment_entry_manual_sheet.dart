part of 'appointment_entry_page.dart';

class _BusinessManualAppointmentSheet extends StatefulWidget {
  const _BusinessManualAppointmentSheet({
    required this.service,
    required this.businessId,
    required this.businessName,
    required this.initialStartAt,
    required this.initialStaff,
    required this.staff,
  });

  final BusinessManualAppointmentService service;
  final String businessId;
  final String businessName;
  final DateTime initialStartAt;
  final AppointmentStaffLite? initialStaff;
  final List<AppointmentStaffLite> staff;

  @override
  State<_BusinessManualAppointmentSheet> createState() =>
      _BusinessManualAppointmentSheetState();
}

class _BusinessManualAppointmentSheetState
    extends State<_BusinessManualAppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _noteController = TextEditingController();

  late Future<List<BusinessManualAppointmentServiceOption>> _servicesFuture;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _selectedStaffId = '';
  String _selectedServiceId = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialStartAt.year,
      widget.initialStartAt.month,
      widget.initialStartAt.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.initialStartAt);
    _selectedStaffId =
        widget.initialStaff?.id ??
        (_staffOptions.isEmpty ? '' : _staffOptions.first.id);
    _servicesFuture = widget.service.loadServices(widget.businessId);
    _servicesFuture.then((items) {
      if (!mounted || items.isEmpty || _serviceNameController.text.isNotEmpty) {
        return;
      }
      final first = items.first;
      setState(() {
        _selectedServiceId = first.id;
        _serviceNameController.text = first.name;
        _durationController.text = first.durationMinutes.toString();
      });
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _serviceNameController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<AppointmentStaffLite> get _staffOptions {
    final seen = <String>{};
    final options = <AppointmentStaffLite>[];

    for (final item in widget.staff) {
      final id = item.id.trim().isEmpty ? item.name.trim() : item.id.trim();
      final name = item.name.trim();
      if (id.isEmpty && name.isEmpty) continue;
      if (!seen.add(id.isEmpty ? name : id)) continue;
      options.add(AppointmentStaffLite(id: id, name: name.isEmpty ? id : name));
    }

    return options;
  }

  AppointmentStaffLite get _selectedStaff {
    final options = _staffOptions;
    for (final item in options) {
      if (item.id == _selectedStaffId) return item;
    }
    return options.isEmpty
        ? const AppointmentStaffLite(id: 'default', name: 'Genel')
        : options.first;
  }

  int get _durationMinutes {
    final parsed = int.tryParse(_durationController.text.trim());
    return parsed == null ? 30 : parsed.clamp(5, 480).toInt();
  }

  DateTime get _startAt {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _dateText(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  String _timeText(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final staff = _selectedStaff;
    final startAt = _startAt;
    final result = await widget.service.createManualAppointment(
      BusinessManualAppointmentDraft(
        businessId: widget.businessId,
        businessName: widget.businessName,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        customerEmail: _customerEmailController.text.trim(),
        serviceId: _selectedServiceId,
        serviceName: _serviceNameController.text.trim(),
        staffId: staff.id,
        staffName: staff.name,
        dateKey: _dateKey(startAt),
        dateText: _dateText(startAt),
        timeText: _timeText(startAt),
        startAt: startAt,
        durationMinutes: _durationMinutes,
        note: _noteController.text.trim(),
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (result.ok) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final staffOptions = _staffOptions;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.52,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_task_outlined,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manuel randevu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Takvimde seçilen saate hızlı kayıt oluşturun.',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _customerNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Müşteri adı',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 2) return 'Müşteri adı gerekli.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _customerPhoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            prefixIcon: Icon(Icons.call_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _customerEmailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<BusinessManualAppointmentServiceOption>>(
                    future: _servicesFuture,
                    builder: (context, snapshot) {
                      final services =
                          snapshot.data ??
                          const <BusinessManualAppointmentServiceOption>[];
                      if (services.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final validValue =
                          services.any((item) => item.id == _selectedServiceId)
                          ? _selectedServiceId
                          : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: validValue,
                          decoration: const InputDecoration(
                            labelText: 'Kayıtlı hizmet',
                            prefixIcon: Icon(Icons.spa_outlined),
                          ),
                          items: services
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final selected = services.firstWhere(
                              (item) => item.id == value,
                            );
                            setState(() {
                              _selectedServiceId = selected.id;
                              _serviceNameController.text = selected.name;
                              _durationController.text = selected
                                  .durationMinutes
                                  .toString();
                            });
                          },
                        ),
                      );
                    },
                  ),
                  TextFormField(
                    controller: _serviceNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Hizmet / işlem adı',
                      prefixIcon: Icon(Icons.design_services_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Hizmet adı gerekli.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(_dateText(_startAt)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(_timeText(_startAt)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              staffOptions.any(
                                (item) => item.id == _selectedStaffId,
                              )
                              ? _selectedStaffId
                              : (staffOptions.isEmpty
                                    ? null
                                    : staffOptions.first.id),
                          decoration: const InputDecoration(
                            labelText: 'Personel',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: staffOptions
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedStaffId = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Süre (dk)',
                            prefixIcon: Icon(Icons.timer_outlined),
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 5) {
                              return 'Geçerli süre girin.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Not',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _saving ? 'Kaydediliyor...' : 'Randevuyu kaydet',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
