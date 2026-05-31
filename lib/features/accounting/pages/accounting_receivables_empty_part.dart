part of 'accounting_receivables_page.dart';

class _EmptyReceivables extends StatelessWidget {
  const _EmptyReceivables();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 38),
            SizedBox(height: 10),
            Text(
              'Bu filtrede alacak yok',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

int _parseMoneyKurus(String input) {
  final normalized = input.trim().replaceAll('.', '').replaceAll(',', '.');
  final value = double.tryParse(normalized) ?? 0;
  return (value * 100).round();
}
