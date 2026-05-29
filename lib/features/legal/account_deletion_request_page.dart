import 'package:flutter/material.dart';

import 'data/account_deletion_repository.dart';

class AccountDeletionRequestPage extends StatefulWidget {
  const AccountDeletionRequestPage({super.key});

  @override
  State<AccountDeletionRequestPage> createState() =>
      _AccountDeletionRequestPageState();
}

class _AccountDeletionRequestPageState
    extends State<AccountDeletionRequestPage> {
  bool _confirmed = false;
  bool _submitting = false;
  final AccountDeletionRepository _repository = AccountDeletionRepository();

  Future<void> _submit() async {
    if (_submitting || !_confirmed) return;

    setState(() => _submitting = true);
    try {
      await _repository.requestDeletion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesap silme talebiniz alındı. Destek ekibi inceleyecek.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talep oluşturulamadı: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabımı Sil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          const Icon(
            Icons.delete_forever_outlined,
            size: 44,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hesap silme talebi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bu işlem hesabınızın kapatılması, kişisel verilerinizin silinmesi veya anonimleştirilmesi için talep oluşturur. Randevu, muhasebe, uyuşmazlık veya yasal saklama yükümlülüğü bulunan kayıtlar sınırlı süre tutulabilir.',
            style: TextStyle(height: 1.45),
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _confirmed,
            onChanged: _submitting
                ? null
                : (value) => setState(() => _confirmed = value ?? false),
            title: const Text(
              'Hesap silme ve veri silme/anonimleştirme sürecini anladım.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _confirmed && !_submitting ? _submit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: const Text('Silme Talebi Oluştur'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
