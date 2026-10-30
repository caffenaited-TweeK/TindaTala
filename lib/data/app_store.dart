import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'local_store.dart';
import 'models.dart';

class AppStore extends ChangeNotifier {
  AppStore({StoreRepository? repository})
    : _repository = repository ?? LocalStoreRepository();

  static const _passwordIterations = 60000;

  final StoreRepository _repository;
  StoreData _data = const StoreData();
  Future<void> _writeQueue = Future<void>.value();
  bool isReady = false;
  Object? startupError;

  List<Product> get products => List.unmodifiable(_data.products);
  List<Sale> get sales => List.unmodifiable(_data.sales);
  StoreSettings get settings => _data.settings;
  Account? get currentAccount => _data.currentAccount;
  bool get isAuthenticated => currentAccount != null;

  int get totalQuantity =>
      _data.products.fold(0, (total, product) => total + product.quantity);

  double get totalSales =>
      _data.sales.fold(0, (total, sale) => total + sale.total);

  List<Product> get lowStockProducts => _data.products.where((product) {
    return product.quantity <=
        (product.lowStockThreshold > 0
            ? product.lowStockThreshold
            : settings.lowStockThreshold);
  }).toList();

  List<Product> get expiredProducts => _data.products
      .where((product) => daysUntilExpiration(product) < 0)
      .toList();

  List<Product> get expiringProducts => _data.products.where((product) {
    final daysLeft = daysUntilExpiration(product);
    return daysLeft >= 0 && daysLeft <= settings.expirationWarningDays;
  }).toList();

  Future<void> initialize() async {
    try {
      var loadedData = await _repository.load();
      var shouldSave = false;
      final signedInAccount = loadedData.currentAccount;
      if (signedInAccount == null && loadedData.sessionUsername != null) {
        loadedData = loadedData.copyWith(sessionUsername: null);
        shouldSave = true;
      }

      final workspaces = Map<String, StoreWorkspace>.of(
        loadedData.workspaces,
      );
      if (workspaces.isEmpty && loadedData.accounts.isNotEmpty) {
        final legacyOwner = signedInAccount ?? loadedData.accounts.first;
        workspaces[legacyOwner.normalizedUsername] = _workspaceFrom(
          loadedData,
        );
        shouldSave = true;
      }

      final activeAccount = loadedData.currentAccount;
      if (activeAccount != null) {
        final workspace = workspaces[activeAccount.normalizedUsername];
        if (workspace != null) {
          loadedData = loadedData.copyWith(
            sessionUsername: activeAccount.normalizedUsername,
            products: workspace.products,
            sales: workspace.sales,
            settings: workspace.settings,
            workspaces: workspaces,
          );
        } else {
          workspaces[activeAccount.normalizedUsername] = _workspaceFrom(
            loadedData,
          );
          loadedData = loadedData.copyWith(
            sessionUsername: activeAccount.normalizedUsername,
            workspaces: workspaces,
          );
          shouldSave = true;
        }
      }

      _data = loadedData;
      if (shouldSave) await _repository.save(_data);
      isReady = true;
      startupError = null;
    } catch (error) {
      startupError = error;
    }
    notifyListeners();
  }

  Future<void> register(
    String username,
    String password, {
    required String storeName,
  }) {
    final cleanUsername = username.trim();
    final cleanStoreName = storeName.trim();
    if (cleanUsername.length < 3) {
      throw ArgumentError('Choose a username with at least 3 characters.');
    }
    if (!RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(cleanUsername)) {
      throw ArgumentError(
        'Use only letters, numbers, periods, underscores, and hyphens in your username.',
      );
    }
    if (password.length < 6) {
      throw ArgumentError('Your password must be at least 6 characters.');
    }
    if (cleanStoreName.isEmpty) throw ArgumentError('Enter your store name.');

    return _runWrite(() async {
      if (_data.accounts.any(
        (account) => account.normalizedUsername == cleanUsername.toLowerCase(),
      )) {
        throw StateError('That username is already registered.');
      }

      final salt = _newSalt();
      final account = Account(
        username: cleanUsername,
        passwordSalt: salt,
        passwordHash: _hashPassword(password, salt),
        createdAt: DateTime.now(),
      );
      final newSettings = const StoreSettings().copyWith(
        storeName: cleanStoreName,
      );
      final workspaces = Map<String, StoreWorkspace>.of(_data.workspaces)
        ..[account.normalizedUsername] = StoreWorkspace(
          settings: newSettings,
        );
      final nextData = _data.copyWith(
        accounts: [..._data.accounts, account],
        sessionUsername: account.normalizedUsername,
        products: const [],
        sales: const [],
        settings: newSettings,
        workspaces: workspaces,
      );
      await _save(nextData);
    });
  }

  Future<void> login(String username, String password) {
    if (username.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Enter your username and password.');
    }

    return _runWrite(() async {
      Account? matchingAccount;
      for (final account in _data.accounts) {
        if (account.normalizedUsername == username.trim().toLowerCase()) {
          matchingAccount = account;
          break;
        }
      }

      if (matchingAccount == null ||
          !_constantTimeEquals(
            _hashPassword(password, matchingAccount.passwordSalt),
            matchingAccount.passwordHash,
          )) {
        throw StateError('That username and password do not match.');
      }

      final workspace =
          _data.workspaces[matchingAccount.normalizedUsername] ??
          StoreWorkspace(
            settings: StoreSettings(
              storeName: '${matchingAccount.username}’s Tindahan',
            ),
          );
      final nextData = _data.copyWith(
        sessionUsername: matchingAccount.normalizedUsername,
        products: workspace.products,
        sales: workspace.sales,
        settings: workspace.settings,
      );
      await _save(nextData);
    });
  }

  Future<void> signOut() {
    return _runWrite(() async {
      final nextData = _data.copyWith(sessionUsername: null);
      await _save(nextData);
    });
  }

  Future<void> addProduct(Product product) {
    return _runWrite(() async {
      _ensureUniqueName(product.name);
      if (_data.products.any((existing) => existing.id == product.id)) {
        throw StateError('This product has already been saved.');
      }
      final nextData = _data.copyWith(
        products: [..._data.products, product],
        sessionUsername: _data.sessionUsername,
      );
      await _save(nextData);
    });
  }

  Future<void> updateProduct(Product product) {
    return _runWrite(() async {
      final index = _data.products.indexWhere(
        (existing) => existing.id == product.id,
      );
      if (index < 0) throw StateError('This product is no longer available.');
      _ensureUniqueName(product.name, excludingId: product.id);

      final updatedProducts = [..._data.products];
      updatedProducts[index] = product;
      final nextData = _data.copyWith(
        products: updatedProducts,
        sessionUsername: _data.sessionUsername,
      );
      await _save(nextData);
    });
  }

  Future<void> deleteProduct(String productId) {
    return _runWrite(() async {
      if (!_data.products.any((product) => product.id == productId)) return;
      final nextData = _data.copyWith(
        products: _data.products
            .where((product) => product.id != productId)
            .toList(),
        sessionUsername: _data.sessionUsername,
      );
      await _save(nextData);
    });
  }

  Future<void> updateStock(String productId, int quantity) {
    if (quantity < 0) throw ArgumentError('Stock cannot be below zero.');
    return _runWrite(() async {
      final product = _findProduct(productId);
      final index = _data.products.indexWhere(
        (existing) => existing.id == productId,
      );
      final updatedProducts = [..._data.products];
      updatedProducts[index] = product.copyWith(quantity: quantity);
      final nextData = _data.copyWith(
        products: updatedProducts,
        sessionUsername: _data.sessionUsername,
      );
      await _save(nextData);
    });
  }

  Future<Sale> recordSale(String productId, int quantity) {
    if (quantity <= 0) {
      throw ArgumentError('Sale quantity must be at least one.');
    }

    return _runWrite(() async {
      final product = _findProduct(productId);
      if (quantity > product.quantity) {
        throw StateError(
          'Only ${product.quantity} ${product.quantity == 1 ? 'piece is' : 'pieces are'} available.',
        );
      }

      final sale = Sale(
        id: _newId(),
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        createdAt: DateTime.now(),
      );
      final updatedProducts = [..._data.products];
      final index = updatedProducts.indexWhere(
        (existing) => existing.id == productId,
      );
      updatedProducts[index] = product.copyWith(
        quantity: product.quantity - quantity,
      );
      final nextData = _data.copyWith(
        products: updatedProducts,
        sales: [..._data.sales, sale],
        sessionUsername: _data.sessionUsername,
      );

      await _save(nextData);
      return sale;
    });
  }

  Future<void> updateSettings(StoreSettings newSettings) {
    if (newSettings.storeName.trim().isEmpty) {
      throw ArgumentError('Enter your store name.');
    }
    if (newSettings.lowStockThreshold < 0) {
      throw ArgumentError('The low-stock threshold cannot be negative.');
    }
    if (newSettings.expirationWarningDays < 0 ||
        newSettings.expirationWarningDays > 365) {
      throw ArgumentError(
        'Choose an expiration warning period between 0 and 365 days.',
      );
    }
    if (newSettings.categories.any((category) => category.trim().isEmpty)) {
      throw ArgumentError('Category names cannot be empty.');
    }

    return _runWrite(() async {
      final nextData = _data.copyWith(
        settings: newSettings,
        sessionUsername: _data.sessionUsername,
      );
      await _save(nextData);
    });
  }

  Future<void> _save(StoreData nextData) async {
    final activeAccount = nextData.currentAccount;
    final dataToSave = activeAccount == null
        ? nextData
        : nextData.copyWith(
            sessionUsername: nextData.sessionUsername,
            workspaces: {
              ...nextData.workspaces,
              activeAccount.normalizedUsername: _workspaceFrom(nextData),
            },
          );
    await _repository.save(dataToSave);
    _data = dataToSave;
    notifyListeners();
  }

  static StoreWorkspace _workspaceFrom(StoreData data) => StoreWorkspace(
    settings: data.settings,
    products: data.products,
    sales: data.sales,
  );

  Future<T> _runWrite<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Product _findProduct(String productId) {
    for (final product in _data.products) {
      if (product.id == productId) return product;
    }
    throw StateError('This product is no longer available.');
  }

  void _ensureUniqueName(String name, {String? excludingId}) {
    final normalizedName = name.trim().toLowerCase();
    if (_data.products.any(
      (product) =>
          product.id != excludingId &&
          product.name.trim().toLowerCase() == normalizedName,
    )) {
      throw StateError('A product with that name already exists.');
    }
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

  static String _newSalt() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String _hashPassword(String password, String salt) {
    var digest = sha256.convert(utf8.encode('$salt:$password'));
    for (var iteration = 1; iteration < _passwordIterations; iteration++) {
      digest = sha256.convert(utf8.encode('$salt:${digest.toString()}'));
    }
    return digest.toString();
  }

  static bool _constantTimeEquals(String first, String second) {
    var difference = first.length ^ second.length;
    for (var index = 0; index < first.length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }
}
