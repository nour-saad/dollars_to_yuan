import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dollars_to_yuan/src/app.dart';
import 'package:dollars_to_yuan/src/core/services/ad_service.dart';
import 'package:dollars_to_yuan/src/core/services/storage_service.dart';
import 'package:dollars_to_yuan/src/core/services/purchase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Avoid network font fetches during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('App boots, shows title and core conversion UI',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final purchase = PurchaseService();

    // overrideWithValue skips the provider's preload closure, so no AdMob
    // platform channel is invoked in this non-mobile test environment.
    final adService = AdService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          storageServiceProvider.overrideWithValue(storage),
          purchaseServiceProvider.overrideWithValue(purchase),
          adServiceProvider.overrideWithValue(adService),
          premiumStatusProvider
              .overrideWith((ref) => PremiumStatusNotifier(storage, purchase)),
        ],
        child: const DollarsToYuanApp(),
      ),
    );
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 100)); // let state settle

    // App bar title present.
    expect(find.text('Dollars to Yuan'), findsWidgets);

    // Core conversion UI present (default direction is USD -> CNY).
    expect(find.text('Enter amount'), findsOneWidget);
    expect(find.text('Convert to CNY (Yuan)'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // In free (non-premium) mode the premium promotion card is shown.
    expect(find.text('Go Premium'), findsOneWidget);
  });
}
