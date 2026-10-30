enum ProductStatus { expired, lowStock, nearExpiration, inStock }

class Account {
  const Account({
    required this.username,
    required this.passwordSalt,
    required this.passwordHash,
    required this.createdAt,
  });

  final String username;
  final String passwordSalt;
  final String passwordHash;
  final DateTime createdAt;

  String get normalizedUsername => username.trim().toLowerCase();

  Map<String, Object?> toJson() => {
    'username': username,
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Account.fromJson(Map<String, Object?> json) => Account(
    username: json['username'] as String,
    passwordSalt: json['passwordSalt'] as String,
    passwordHash: json['passwordHash'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.purchaseCost,
    required this.quantity,
    required this.expirationDate,
    required this.lowStockThreshold,
    this.imagePath,
  });

  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final double purchaseCost;
  final int quantity;
  final DateTime expirationDate;
  final int lowStockThreshold;
  final String? imagePath;

  Product copyWith({
    String? name,
    String? category,
    double? sellingPrice,
    double? purchaseCost,
    int? quantity,
    DateTime? expirationDate,
    int? lowStockThreshold,
    String? imagePath,
    bool removeImage = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imagePath: removeImage ? null : imagePath ?? this.imagePath,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'sellingPrice': sellingPrice,
    'purchaseCost': purchaseCost,
    'quantity': quantity,
    'expirationDate': expirationDate.toIso8601String(),
    'lowStockThreshold': lowStockThreshold,
    'imagePath': imagePath,
  };

  factory Product.fromJson(Map<String, Object?> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    sellingPrice: (json['sellingPrice'] as num).toDouble(),
    purchaseCost: (json['purchaseCost'] as num).toDouble(),
    quantity: json['quantity'] as int,
    expirationDate: DateTime.parse(json['expirationDate'] as String),
    lowStockThreshold: json['lowStockThreshold'] as int,
    imagePath: json['imagePath'] as String?,
  );
}

class Sale {
  const Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final DateTime createdAt;

  double get total => unitPrice * quantity;

  Map<String, Object?> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Sale.fromJson(Map<String, Object?> json) => Sale(
    id: json['id'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class StoreSettings {
  const StoreSettings({
    this.storeName = 'Aling Nena’s Tindahan',
    this.storeImagePath,
    this.lowStockThreshold = 5,
    this.expirationWarningDays = 7,
    this.categories = const [
      'Canned goods',
      'Snacks',
      'Drinks',
      'Noodles',
      'Coffee',
      'Dairy',
      'Personal care',
      'Household',
      'Candy',
      'Other',
    ],
  });

  final String storeName;
  final String? storeImagePath;
  final int lowStockThreshold;
  final int expirationWarningDays;
  final List<String> categories;

  StoreSettings copyWith({
    String? storeName,
    String? storeImagePath,
    bool removeStoreImage = false,
    int? lowStockThreshold,
    int? expirationWarningDays,
    List<String>? categories,
  }) {
    return StoreSettings(
      storeName: storeName ?? this.storeName,
      storeImagePath: removeStoreImage
          ? null
          : storeImagePath ?? this.storeImagePath,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      expirationWarningDays:
          expirationWarningDays ?? this.expirationWarningDays,
      categories: categories ?? this.categories,
    );
  }

  Map<String, Object?> toJson() => {
    'storeName': storeName,
    'storeImagePath': storeImagePath,
    'lowStockThreshold': lowStockThreshold,
    'expirationWarningDays': expirationWarningDays,
    'categories': categories,
  };

  factory StoreSettings.fromJson(Map<String, Object?>? json) {
    if (json == null) return const StoreSettings();
    return StoreSettings(
      storeName: json['storeName'] as String? ?? 'Aling Nena’s Tindahan',
      storeImagePath: json['storeImagePath'] as String?,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 5,
      expirationWarningDays: json['expirationWarningDays'] as int? ?? 7,
      categories:
          (json['categories'] as List<Object?>?)
              ?.map((category) => category as String)
              .toList() ??
          const [
            'Canned goods',
            'Snacks',
            'Drinks',
            'Noodles',
            'Coffee',
            'Dairy',
            'Personal care',
            'Household',
            'Candy',
            'Other',
          ],
    );
  }
}

class StoreWorkspace {
  const StoreWorkspace({
    this.settings = const StoreSettings(),
    this.products = const [],
    this.sales = const [],
  });

  final StoreSettings settings;
  final List<Product> products;
  final List<Sale> sales;

  Map<String, Object?> toJson() => {
    'settings': settings.toJson(),
    'products': products.map((product) => product.toJson()).toList(),
    'sales': sales.map((sale) => sale.toJson()).toList(),
  };

  factory StoreWorkspace.fromJson(Map<String, Object?> json) =>
      StoreWorkspace(
        settings: StoreSettings.fromJson(
          json['settings'] as Map<String, Object?>?,
        ),
        products: (json['products'] as List<Object?>? ?? const [])
            .map((product) => Product.fromJson(product as Map<String, Object?>))
            .toList(),
        sales: (json['sales'] as List<Object?>? ?? const [])
            .map((sale) => Sale.fromJson(sale as Map<String, Object?>))
            .toList(),
      );
}

class StoreData {
  const StoreData({
    this.accounts = const [],
    this.sessionUsername,
    this.products = const [],
    this.sales = const [],
    this.settings = const StoreSettings(),
    this.workspaces = const {},
  });

  final List<Account> accounts;
  final String? sessionUsername;
  final List<Product> products;
  final List<Sale> sales;
  final StoreSettings settings;
  final Map<String, StoreWorkspace> workspaces;

  Account? get currentAccount {
    final username = sessionUsername?.toLowerCase();
    if (username == null) return null;
    for (final account in accounts) {
      if (account.normalizedUsername == username) return account;
    }
    return null;
  }

  StoreData copyWith({
    List<Account>? accounts,
    required String? sessionUsername,
    List<Product>? products,
    List<Sale>? sales,
    StoreSettings? settings,
    Map<String, StoreWorkspace>? workspaces,
  }) {
    return StoreData(
      accounts: accounts ?? this.accounts,
      sessionUsername: sessionUsername,
      products: products ?? this.products,
      sales: sales ?? this.sales,
      settings: settings ?? this.settings,
      workspaces: workspaces ?? this.workspaces,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 2,
    'accounts': accounts.map((account) => account.toJson()).toList(),
    'sessionUsername': sessionUsername,
    'products': products.map((product) => product.toJson()).toList(),
    'sales': sales.map((sale) => sale.toJson()).toList(),
    'settings': settings.toJson(),
    'workspaces': workspaces.map(
      (username, workspace) => MapEntry(username, workspace.toJson()),
    ),
  };

  factory StoreData.fromJson(Map<String, Object?> json) {
    final workspaceJson =
        json['workspaces'] as Map<String, Object?>? ?? const {};
    return StoreData(
      accounts: (json['accounts'] as List<Object?>? ?? const [])
          .map((account) => Account.fromJson(account as Map<String, Object?>))
          .toList(),
      sessionUsername: json['sessionUsername'] as String?,
      products: (json['products'] as List<Object?>? ?? const [])
          .map((product) => Product.fromJson(product as Map<String, Object?>))
          .toList(),
      sales: (json['sales'] as List<Object?>? ?? const [])
          .map((sale) => Sale.fromJson(sale as Map<String, Object?>))
          .toList(),
      settings: StoreSettings.fromJson(
        json['settings'] as Map<String, Object?>?,
      ),
      workspaces: workspaceJson.map(
        (username, workspace) => MapEntry(
          username,
          StoreWorkspace.fromJson(workspace as Map<String, Object?>),
        ),
      ),
    );
  }
}

ProductStatus productStatus(
  Product product, {
  required int defaultLowStockThreshold,
  required int expirationWarningDays,
  DateTime? today,
}) {
  final currentDate = today ?? DateTime.now();
  final now = DateTime(currentDate.year, currentDate.month, currentDate.day);
  final expiration = DateTime(
    product.expirationDate.year,
    product.expirationDate.month,
    product.expirationDate.day,
  );

  if (expiration.isBefore(now)) return ProductStatus.expired;
  if (product.quantity <=
      (product.lowStockThreshold > 0
          ? product.lowStockThreshold
          : defaultLowStockThreshold)) {
    return ProductStatus.lowStock;
  }
  if (expiration.difference(now).inDays <= expirationWarningDays) {
    return ProductStatus.nearExpiration;
  }
  return ProductStatus.inStock;
}

int daysUntilExpiration(Product product, {DateTime? today}) {
  final currentDate = today ?? DateTime.now();
  final now = DateTime(currentDate.year, currentDate.month, currentDate.day);
  final expiration = DateTime(
    product.expirationDate.year,
    product.expirationDate.month,
    product.expirationDate.day,
  );
  return expiration.difference(now).inDays;
}
