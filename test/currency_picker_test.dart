import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:expenses_management_app/l10n/app_localizations.dart';
import 'package:expenses_management_app/presentation/widgets/currency_picker.dart';

Widget _app(Widget child) => MaterialApp(
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  testWidgets('T filters to T codes and TN selects TND', (tester) async {
    String? result;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showCurrencyPicker(context);
        },
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'T');
    await tester.pump();
    expect(find.text('TWD'), findsOneWidget);
    expect(find.text('TRY'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'TN');
    await tester.pump();
    expect(find.text('TND'), findsOneWidget);
    await tester.tap(find.text('TND'));
    await tester.pumpAndSettle();
    expect(result, 'TND');
  });

  testWidgets('unknown code shows empty state', (tester) async {
    await tester.pumpWidget(_app(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showCurrencyPicker(context),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ZZ');
    await tester.pump();
    expect(find.text('No matching currency codes'), findsOneWidget);
  });
}
