import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatala/data/app_store.dart';
import 'package:tindatala/data/local_store.dart';
import 'package:tindatala/data/models.dart';
import 'package:tindatala/main.dart';
import 'package:tindatala/widgets/common_widgets.dart';

import 'helpers/memory_store_repository.dart';

void main() {
  testWidgets('shows the loading screen before opening the sign-in screen', (
    tester,
  ) async {
    final repository = _DelayedStoreRepository();
    final store = AppStore(repository: repository);
    await tester.pumpWidget(TindaTalaApp(store: store));

    expect(find.byKey(const ValueKey('splash-screen')), findsOneWidget);
    expect(find.text('Getting your store ready…'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-username-field')), findsNothing);

    repository.completeLoading();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('splash-screen')), findsNothing);
    expect(find.byKey(const ValueKey('auth-username-field')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('the saved store photo appears on Home and Inventory', (
    tester,
  ) async {
    final store = AppStore(repository: MemoryStoreRepository());
    await store.initialize();
    await store.register(
      'AlingNena',
      'tindahan123',
      storeName: 'Aling Nena’s Tindahan',
    );
    final imagePath = File(
      'assets${Platform.pathSeparator}designs${Platform.pathSeparator}'
      'images${Platform.pathSeparator}TindaTala_logo.png',
    ).absolute.path;
    await store.updateSettings(
      store.settings.copyWith(storeImagePath: imagePath),
    );

    await tester.pumpWidget(TindaTalaApp(store: store));
    await tester.pumpAndSettle();

    final homeArtwork = tester.widget<StoreProfileImage>(
      find.byKey(const ValueKey('home-store-profile-image')),
    );
    expect(homeArtwork.imagePath, imagePath);

    await tester.tap(find.byKey(const ValueKey('navigation-inventory')));
    await tester.pumpAndSettle();
    final inventoryHeading = tester.widget<PageHeading>(
      find.byWidgetPredicate(
        (widget) => widget is PageHeading && widget.title == 'Your inventory',
      ),
    );
    expect(inventoryHeading.imagePath, imagePath);
    expect(
      tester
          .widget<StoreProfileImage>(
            find.descendant(
              of: find.byType(PageHeading),
              matching: find.byType(StoreProfileImage),
            ),
          )
          .imagePath,
      imagePath,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('store profile image stays synchronized across app screens', (
    tester,
  ) async {
    final repository = MemoryStoreRepository();
    final store = AppStore(repository: repository);
    await store.initialize();
    await store.register(
      'AlingNena',
      'tindahan123',
      storeName: 'Aling Nena’s Tindahan',
    );
    const firstImagePath = 'account_images/alingnena/store/first.jpg';
    const replacementImagePath = 'account_images/alingnena/store/second.jpg';
    await store.updateSettings(
      store.settings.copyWith(storeImagePath: firstImagePath),
    );

    await tester.pumpWidget(TindaTalaApp(store: store));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StoreProfileImage>(
            find.byKey(const ValueKey('home-store-profile-image')),
          )
          .imagePath,
      firstImagePath,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-inventory')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StoreProfileImage>(
            find.descendant(
              of: find.byType(PageHeading),
              matching: find.byType(StoreProfileImage),
            ),
          )
          .imagePath,
      firstImagePath,
    );

    await tester.tap(find.byKey(const ValueKey('navigation-more')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<StoreProfileImage>(find.byType(StoreProfileImage))
          .where((image) => image.imagePath == firstImagePath),
      hasLength(2),
    );

    await store.updateSettings(
      store.settings.copyWith(storeImagePath: replacementImagePath),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<StoreProfileImage>(find.byType(StoreProfileImage))
          .where((image) => image.imagePath == replacementImagePath),
      hasLength(2),
    );

    await tester.tap(find.byKey(const ValueKey('navigation-home')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StoreProfileImage>(
            find.byKey(const ValueKey('home-store-profile-image')),
          )
          .imagePath,
      replacementImagePath,
    );
    await tester.tap(find.byKey(const ValueKey('navigation-inventory')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PageHeading>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is PageHeading && widget.title == 'Your inventory',
            ),
          )
          .imagePath,
      replacementImagePath,
    );

    await store.updateSettings(store.settings.copyWith(removeStoreImage: true));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StoreProfileImage>(
            find.descendant(
              of: find.byType(PageHeading),
              matching: find.byType(StoreProfileImage),
            ),
          )
          .imagePath,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('navigation-home')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StoreProfileImage>(
            find.byKey(const ValueKey('home-store-profile-image')),
          )
          .imagePath,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('navigation-more')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<StoreProfileImage>(find.byType(StoreProfileImage))
          .where((image) => image.imagePath == null),
      hasLength(2),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });

  testWidgets('register, add a product, record a sale, and sign back in', (
    tester,
  ) async {
    final store = AppStore(repository: MemoryStoreRepository());
    await tester.pumpWidget(TindaTalaApp(store: store));
    await tester.pumpAndSettle();

    final awningTop = tester
        .getTopLeft(find.byKey(const ValueKey('auth-awning-ribbon')))
        .dy;
    expect(awningTop, 0);
    expect(awningTop, lessThan(tester.getTopLeft(find.byType(TindaLogo)).dy));
    expect(
      awningTop,
      lessThan(
        tester.getTopLeft(find.text('New to TindaTala? Create an account')).dy,
      ),
    );
    expect(find.text('Maayong adlaw!'), findsOneWidget);
    await tester.tap(find.text('New to TindaTala? Create an account'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('auth-username-field')),
      'AlingNena',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password-field')),
      'tindahan123',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-confirm-password-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirm-password-field')),
      'tindahan123',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit-button')));
    await tester.pumpAndSettle();

    expect(store.isAuthenticated, isTrue);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navigation-inventory')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-product-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('product-name-field')),
      'Ligo Sardines',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('selling-price-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('selling-price-field')),
      '12',
    );
    await tester.enterText(
      find.byKey(const ValueKey('purchase-cost-field')),
      '8',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('stock-quantity-field')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('stock-quantity-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('low-stock-threshold-field')),
      '2',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-product-button')),
    );
    await tester.tap(find.byKey(const ValueKey('save-product-button')));
    await tester.pumpAndSettle();

    expect(store.products.single.name, 'Ligo Sardines');
    expect(store.products.single.quantity, 5);

    await tester.tap(find.byKey(const ValueKey('navigation-sales')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sale-product-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ligo Sardines').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('sale-quantity-field')),
      '2',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('confirm-sale-button')),
    );
    await tester.tap(find.byKey(const ValueKey('confirm-sale-button')));
    await tester.pumpAndSettle();
    expect(store.sales, isEmpty);
    await tester.tap(find.byKey(const ValueKey('confirm-sale-dialog-button')));
    await tester.pumpAndSettle();

    expect(store.sales, hasLength(1));
    expect(store.totalSales, 24);
    expect(store.products.single.quantity, 3);

    await tester.enterText(
      find.byKey(const ValueKey('sale-quantity-field')),
      '4',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('confirm-sale-button')),
    );
    await tester.tap(find.byKey(const ValueKey('confirm-sale-button')));
    await tester.pumpAndSettle();
    expect(find.text('You only have 3 pieces available.'), findsOneWidget);
    expect(store.sales, hasLength(1));
    expect(store.products.single.quantity, 3);

    await tester.tap(find.byKey(const ValueKey('navigation-more')));
    await tester.pumpAndSettle();
    expect(find.text('A little more'), findsOneWidget);
    await store.signOut();
    await tester.pumpAndSettle();

    expect(store.isAuthenticated, isFalse);
    expect(store.products.single.quantity, 3);
    expect(store.sales, hasLength(1));

    await tester.enterText(
      find.byKey(const ValueKey('auth-username-field')),
      'alingnena',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password-field')),
      'tindahan123',
    );
    await tester.tap(find.byKey(const ValueKey('auth-submit-button')));
    await tester.pumpAndSettle();
    expect(store.isAuthenticated, isTrue);
    expect(store.products.single.quantity, 3);
    expect(store.sales.single.total, 24);

    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
  });
}

class _DelayedStoreRepository implements StoreRepository {
  final _loadedData = Completer<StoreData>();

  void completeLoading() => _loadedData.complete(const StoreData());

  @override
  Future<StoreData> load() => _loadedData.future;

  @override
  Future<void> save(StoreData data) async {}
}
