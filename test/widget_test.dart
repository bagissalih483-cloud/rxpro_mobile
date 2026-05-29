import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxpro_mobile/features/auth/widgets/fix_session_loading_image.dart';

void main() {
  testWidgets('RxPro startup shell renders a real first frame', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FixSessionLoadingImage(message: 'RxPro hazirlaniyor...'),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('RxPro hazirlaniyor...'), findsOneWidget);
  });
}
