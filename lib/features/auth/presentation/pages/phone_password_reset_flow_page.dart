import 'package:flutter/material.dart';

class PhonePasswordResetFlowPage extends StatefulWidget {
  const PhonePasswordResetFlowPage({super.key});

  @override
  State<PhonePasswordResetFlowPage> createState() =>
      _PhonePasswordResetFlowPageState();
}

class _PhonePasswordResetFlowPageState
    extends State<PhonePasswordResetFlowPage> {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordAgainController = TextEditingController();

  int step = 0;
  bool obscure = true;

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    passwordController.dispose();
    passwordAgainController.dispose();
    super.dispose();
  }

  void _nextFromPhone() {
    final phone = phoneController.text.trim();

    if (phone.length < 10) {
      _snack('Telefon numarası eksik görünüyor.');
      return;
    }

    _snack(
      'Telefon doğrulama altyapısı hazırlandı; SMS gönderimi bu aşamada aktif değil.',
    );
    setState(() => step = 1);
  }

  void _nextFromCode() {
    final code = codeController.text.trim();

    if (code.length < 4) {
      _snack('Doğrulama kodu en az 4 haneli olmalıdır.');
      return;
    }

    setState(() => step = 2);
  }

  void _finish() {
    final p1 = passwordController.text.trim();
    final p2 = passwordAgainController.text.trim();

    if (p1.length < 6) {
      _snack('Yeni şifre en az 6 haneli olmalıdır.');
      return;
    }

    if (p1 != p2) {
      _snack('Şifreler eşleşmiyor.');
      return;
    }

    _snack(
      'Yeni şifre ekranı hazır. Gerçek güncelleme SMS doğrulama aktif edilince bağlanacak.',
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Telefon numaranı doğrula',
      'Doğrulama kodu',
      'Yeni şifre oluştur',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ProgressHeader(step: step, title: titles[step]),
          const SizedBox(height: 16),
          if (step == 0) _phoneStep(),
          if (step == 1) _codeStep(),
          if (step == 2) _newPasswordStep(),
        ],
      ),
    );
  }

  Widget _phoneStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Kayıtlı GSM numaranı gir. İleride bu ekrandan SMS doğrulama kodu gönderilecek.',
              style: TextStyle(color: Color(0xFF60727A), height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '05xx xxx xx xx',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _nextFromPhone,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Doğrulama Koduna Geç'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Bu aşama şimdilik şema ekranıdır. SMS doğrulama aktif edilince gerçek kod kontrolü buraya bağlanacak.',
              style: TextStyle(color: Color(0xFF60727A), height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Doğrulama kodu',
                hintText: '000000',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _nextFromCode,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Yeni Şifreye Geç'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPasswordStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Yeni şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordAgainController,
              obscureText: obscure,
              decoration: const InputDecoration(
                labelText: 'Yeni şifre tekrar',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Şifreyi Güncelle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.title});

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFFAF4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF8FD19E),
              child: Text(
                '${step + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B3D2B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
