part of 'business_customers_page.dart';

class _ManualCustomerSheet extends StatefulWidget {
  const _ManualCustomerSheet({
    required this.businessId,
    required this.repository,
  });

  final String businessId;
  final BusinessCustomerRepository repository;

  @override
  State<_ManualCustomerSheet> createState() => _ManualCustomerSheetState();
}

class _ManualCustomerSheetState extends State<_ManualCustomerSheet> {
  final ManualCustomerFormController _controller =
      ManualCustomerFormController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final input = BusinessCustomerManualInput(
      businessId: widget.businessId,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      note: _noteController.text,
      segmentId: _controller.segmentId,
      campaignConsent: _controller.campaignConsent,
    );

    if (!input.hasRequiredIdentity) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ad, telefon veya e-posta bilgilerinden biri gerekli.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _controller.setSaving(true);
    try {
      await widget.repository.createManualCustomer(input);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Müşteri kaydı eklendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Müşteri eklenemedi: $e'),
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
      title: 'Müşteri ekle',
      child: Column(
        children: [
          _SheetTextField(controller: _nameController, label: 'Ad soyad'),
          _SheetTextField(controller: _phoneController, label: 'Telefon'),
          _SheetTextField(controller: _emailController, label: 'E-posta'),
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
                  : const Icon(Icons.check),
              label: Text(_controller.saving ? 'Kaydediliyor' : 'Kaydet'),
            ),
          ),
        ],
      ),
        );
      },
    );
  }
}
