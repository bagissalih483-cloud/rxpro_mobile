import 'package:flutter/material.dart';
import 'package:rxpro_mobile/core/services/auth_service.dart';

class PhonePasswordResetFlowPage extends StatefulWidget {
  const PhonePasswordResetFlowPage({super.key});

  @override
  State<PhonePasswordResetFlowPage> createState() =>
      _PhonePasswordResetFlowPageState();
}

class _PhonePasswordResetFlowPageState
    extends State<PhonePasswordResetFlowPage> {
  final emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final ValueNotifier<bool> sending = ValueNotifier<bool>(false);

  @override
  void dispose() {
    sending.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = emailController.text.trim();
    if (!email.contains('@')) {
      _snack('Gecerli bir e-posta adresi gir.');
      return;
    }

    sending.value = true;
    try {
      await _authService.sendPasswordResetEmail(email: email);
      _snack('Sifre sifirlama baglantisi e-posta adresine gonderildi.');
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      _snack('Sifre sifirlama baglantisi gonderilemedi: $error');
    } finally {
      if (mounted) sending.value = false;
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sifre sifirlama')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            color: const Color(0xFFEFFAF4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.mark_email_read_outlined, color: Color(0xFF1DB954)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'E-posta adresine guvenli sifre sifirlama baglantisi gonderecegiz.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B3D2B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@mail.com',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<bool>(
                    valueListenable: sending,
                    builder: (context, isSending, _) {
                      return FilledButton.icon(
                        onPressed: isSending ? null : _sendResetLink,
                        icon: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text(
                          'Sifre sifirlama baglantisi gonder',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
