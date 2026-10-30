import 'package:flutter_test/flutter_test.dart';
import 'package:tindatala/data/app_store.dart';
import 'package:tindatala/data/models.dart';

import 'helpers/memory_store_repository.dart';

void main() {
  late AppStore store;
  late MemoryStoreRepository repository;

  setUp(() async {
    repository = MemoryStoreRepository();
    store = AppStore(repository: repository);
    await store.initialize();
  });

  tearDown(() {
    store.dispose();
  });

  test(
    'accounts, sessions, store settings, and products survive reopening',
    () async {
      await store.register(
        'AlingNena',
        'store1234',
        storeName: 'Nena’s Tindahan',
      );
      final product = _product(
        id: 'sardines',
        name: 'Ligo Sardines',
        category: 'Canned goods',
        quantity: 8,
        lowStockThreshold: 5,
      );
      await store.addProduct(product);
      await store.updateSettings(
        store.settings.copyWith(
          lowStockThreshold: 3,
          expirationWarningDays: 14,
        ),
      );

      final account = repository.data.accounts.single;
      expect(account.passwordHash, isNot('store1234'));
      expect(account.passwordSalt, isNotEmpty);

      await store.signOut();
      expect(store.isAuthenticated, isFalse);
      expect(store.products.single.name, 'Ligo Sardines');

      await expectLater(
        store.register('alingnena', 'another123', storeName: 'Another Store'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        store.login('AlingNena', 'wrong123'),
        throwsA(isA<StateError>()),
      );
      await store.login('alingnena', 'store1234');
      expect(store.currentAccount?.username, 'AlingNena');

      final reopened = AppStore(repository: repository);
      await reopened.initialize();
      expect(reopened.currentAccount?.username, 'AlingNena');
      expect(reopened.settings.storeName, 'Nena’s Tindahan');
      expect(reopened.settings.lowStockThreshold, 3);
      expect(reopened.settings.expirationWarningDays, 14);
      expect(reopened.products.single.name, 'Ligo Sardines');
      reopened.dispose();
    },
  );

  test(
    'each account keeps its own products, sales, settings, and photos',
    () async {
      await store.register('AlingNena', 'store1234', storeName: 'Nena Store');
      final nenaProduct = _product(
        id: 'nena-sardines',
        name: 'Sardines',
        category: 'Canned goods',
        quantity: 5,
        lowStockThreshold: 2,
      );
      await store.addProduct(nenaProduct);
      await store.recordSale(nenaProduct.id, 1);
      await store.updateSettings(
        store.settings.copyWith(
          storeImagePath: 'account_images/alingnena/store/nena.jpg',
          categories: ['Canned goods', 'Snacks'],
        ),
      );
      await store.signOut();

      await store.register('AlingLito', 'store5678', storeName: 'Lito Store');
      expect(store.products, isEmpty);
      expect(store.sales, isEmpty);
      expect(store.settings.storeName, 'Lito Store');
      expect(store.settings.storeImagePath, isNull);
      expect(store.settings.categories, contains('Drinks'));

      final litoProduct = _product(
        id: 'lito-coffee',
        name: 'Coffee',
        category: 'Coffee',
        quantity: 12,
        lowStockThreshold: 3,
      );
      await store.addProduct(litoProduct);
      await store.updateSettings(
        store.settings.copyWith(
          storeImagePath: 'account_images/alinglito/store/lito.jpg',
          categories: ['Coffee'],
        ),
      );
      await store.signOut();

      await store.login('alingnena', 'store1234');
      expect(store.settings.storeName, 'Nena Store');
      expect(store.settings.storeImagePath, contains('alingnena'));
      expect(store.settings.categories, ['Canned goods', 'Snacks']);
      expect(store.products.single.id, nenaProduct.id);
      expect(store.sales.single.productName, 'Sardines');
      await store.signOut();

      await store.login('alinglito', 'store5678');
      expect(store.settings.storeName, 'Lito Store');
      expect(store.settings.storeImagePath, contains('alinglito'));
      expect(store.settings.categories, ['Coffee']);
      expect(store.products.single.id, litoProduct.id);
      expect(store.sales, isEmpty);

      final restoredData = StoreData.fromJson(repository.data.toJson());
      expect(
        restoredData.workspaces['alingnena']?.products.single.id,
        nenaProduct.id,
      );
      expect(
        restoredData.workspaces['alingnena']?.settings.storeImagePath,
        contains('alingnena'),
      );

      final reopened = AppStore(repository: repository);
      await reopened.initialize();
      expect(reopened.currentAccount?.username, 'AlingLito');
      expect(reopened.products.single.id, litoProduct.id);
      expect(reopened.settings.storeImagePath, contains('alinglito'));
      reopened.dispose();
    },
  );

  test(
    'store picture replacement and removal persist across sign-in',
    () async {
      await store.register('AlingNena', 'store1234', storeName: 'Nena Store');
      const firstImagePath = 'account_images/alingnena/store/first.jpg';
      const replacementImagePath = 'account_images/alingnena/store/second.jpg';

      await store.updateSettings(
        store.settings.copyWith(storeImagePath: firstImagePath),
      );
      await store.signOut();
      await store.login('alingnena', 'store1234');
      expect(store.settings.storeImagePath, firstImagePath);

      await store.updateSettings(
        store.settings.copyWith(storeImagePath: replacementImagePath),
      );
      await store.signOut();

      final reopened = AppStore(repository: repository);
      await reopened.initialize();
      await reopened.login('alingnena', 'store1234');
      expect(reopened.settings.storeImagePath, replacementImagePath);
      await reopened.updateSettings(
        reopened.settings.copyWith(removeStoreImage: true),
      );
      await reopened.signOut();

      final reopenedAfterRemoval = AppStore(repository: repository);
      await reopenedAfterRemoval.initialize();
      await reopenedAfterRemoval.login('alingnena', 'store1234');
      expect(reopenedAfterRemoval.settings.storeImagePath, isNull);

      reopened.dispose();
      reopenedAfterRemoval.dispose();
    },
  );

  test(
    'sale commits stock and history together and rejects invalid quantities',
    () async {
      await store.register('shopkeeper', 'shelf123', storeName: 'Store');
      final product = _product(
        id: 'coffee',
        name: 'Coffee sachets',
        category: 'Coffee',
        quantity: 4,
        lowStockThreshold: 1,
        sellingPrice: 12.5,
      );
      await store.addProduct(product);

      await expectLater(
        store.recordSale(product.id, 5),
        throwsA(isA<StateError>()),
      );
      expect(store.products.single.quantity, 4);
      expect(store.sales, isEmpty);

      expect(() => store.recordSale(product.id, 0), throwsArgumentError);
      expect(() => store.recordSale(product.id, -1), throwsArgumentError);
      expect(() => store.updateStock(product.id, -1), throwsArgumentError);

      final sale = await store.recordSale(product.id, 2);
      expect(sale.total, 25);
      expect(store.products.single.quantity, 2);
      expect(store.sales, hasLength(1));
      expect(store.totalSales, 25);

      final restored = AppStore(repository: repository);
      await restored.initialize();
      expect(restored.products.single.quantity, 2);
      expect(restored.sales.single.total, 25);
      restored.dispose();

      await store.deleteProduct(product.id);
      expect(store.products, isEmpty);
      expect(store.sales.single.productName, 'Coffee sachets');
    },
  );

  test(
    'products can be edited without duplicating names or old sales',
    () async {
      await store.register('storeowner', 'secure123', storeName: 'Store');
      final original = _product(
        id: 'biscuits',
        name: 'Biscuits',
        category: 'Snacks',
        quantity: 10,
        lowStockThreshold: 4,
      );
      await store.addProduct(original);
      await store.updateProduct(
        original.copyWith(name: 'Crackers', sellingPrice: 18),
      );

      expect(store.products.single.name, 'Crackers');
      expect(store.products.single.sellingPrice, 18);

      final other = _product(
        id: 'milk',
        name: 'Milk',
        category: 'Dairy',
        quantity: 4,
        lowStockThreshold: 5,
      );
      await store.addProduct(other);
      await expectLater(
        store.updateProduct(other.copyWith(name: ' crackers ')),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        store.addProduct(
          _product(
            id: 'another-product',
            name: 'CRACKERS',
            category: 'Snacks',
            quantity: 3,
            lowStockThreshold: 2,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'stock and expiration status use each product threshold and store settings',
    () async {
      final today = DateTime(2026, 10, 30);
      final nearExpiration = _product(
        id: 'near',
        name: 'Piatto Cheese',
        category: 'Snacks',
        quantity: 20,
        lowStockThreshold: 0,
        expirationDate: DateTime(2026, 11, 5),
      );
      final lowStock = _product(
        id: 'low',
        name: 'Ligo Sardines',
        category: 'Canned goods',
        quantity: 4,
        lowStockThreshold: 5,
        expirationDate: DateTime(2027, 1, 15),
      );
      final expired = _product(
        id: 'expired',
        name: 'Expired snack',
        category: 'Snacks',
        quantity: 6,
        lowStockThreshold: 5,
        expirationDate: DateTime(2026, 10, 28),
      );

      expect(
        productStatus(
          nearExpiration,
          defaultLowStockThreshold: 5,
          expirationWarningDays: 7,
          today: today,
        ),
        ProductStatus.nearExpiration,
      );
      expect(
        productStatus(
          lowStock,
          defaultLowStockThreshold: 5,
          expirationWarningDays: 7,
          today: today,
        ),
        ProductStatus.lowStock,
      );
      expect(
        productStatus(
          expired,
          defaultLowStockThreshold: 5,
          expirationWarningDays: 7,
          today: today,
        ),
        ProductStatus.expired,
      );
      expect(daysUntilExpiration(nearExpiration, today: today), 6);
    },
  );
}

Product _product({
  required String id,
  required String name,
  required String category,
  required int quantity,
  required int lowStockThreshold,
  double sellingPrice = 28,
  DateTime? expirationDate,
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    sellingPrice: sellingPrice,
    purchaseCost: 15,
    quantity: quantity,
    expirationDate:
        expirationDate ?? DateTime.now().add(const Duration(days: 30)),
    lowStockThreshold: lowStockThreshold,
  );
}
