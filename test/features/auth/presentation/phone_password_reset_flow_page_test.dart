import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/auth/presentation/pages/phone_password_reset_flow_page.dart';

void main() {
  testWidgets('phone password reset flow keeps clean Turkish labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PhonePasswordResetFlowPage()),
    );

    expect(find.text('Şifremi Unuttum'), findsOneWidget);
    expect(find.text('Telefon numaranı doğrula'), findsOneWidget);
    expect(find.text('Doğrulama Koduna Geç'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '5551112233');
    await tester.tap(find.text('Doğrulama Koduna Geç'));
    await tester.pumpAndSettle();

    expect(find.text('Doğrulama kodu'), findsWidgets);
    expect(find.text('Yeni Şifreye Geç'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Yeni Şifreye Geç'));
    await tester.pumpAndSettle();

    expect(find.text('Yeni şifre oluştur'), findsOneWidget);
    expect(find.text('Şifreyi Güncelle'), findsOneWidget);
  });
}
