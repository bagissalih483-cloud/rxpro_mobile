part of 'business_customers_page.dart';

class _ClassificationSheet extends StatefulWidget {
  const _ClassificationSheet({required this.record, required this.repository});

  final BusinessCustomerRecord record;
  final BusinessCustomerRepository repository;

  @override
  State<_ClassificationSheet> createState() => _ClassificationSheetState();
}

class _ClassificationSheetState extends State<_ClassificationSheet> {
  late final CustomerClassificationController _controller =
      CustomerClassificationController(
        initialSegmentId: widget.record.segmentId,
        initialCampaignConsent: widget.record.campaignConsent,
      );
  late final TextEditingController _noteController = TextEditingController(
    text: widget.record.note,
  );
  bool get _saving => _controller.saving;

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    _controller.setSaving(true);
    try {
      await widget.repository.saveCustomerClassification(
        record: widget.record,
        segmentId: _controller.segmentId,
        note: _noteController.text,
        campaignConsent: _controller.campaignConsent,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Müşteri sınıflandırması güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Sınıflandırma kaydedilemedi: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _controller.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _SheetFrame(
      title: widget.record.displayName,
      child: Column(
        children: [
          _SegmentDropdown(
            value: _controller.segmentId,
            onChanged: _controller.selectSegment,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _controller.campaignConsent,
            onChanged: _controller.setCampaignConsent,
            title: const Text('Toplu mesaj izni var'),
          ),
          _SheetTextField(
            controller: _noteController,
            label: 'İşletme notu',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _controller.saving ? null : _save,
              icon: _controller.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor' : 'Sınıflandırmayı kaydet'),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}

class _SegmentDropdown extends StatelessWidget {
  const _SegmentDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: BusinessCustomerSegments.byId(value).id,
      decoration: const InputDecoration(
        labelText: 'Müşteri sınıfı',
        border: OutlineInputBorder(),
      ),
      items: BusinessCustomerSegments.editableValues
          .map(
            (segment) => DropdownMenuItem<String>(
              value: segment.id,
              child: Text(segment.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
