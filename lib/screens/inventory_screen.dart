import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'product_screens.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.store,
    required this.initialFilter,
    required this.onFilterChanged,
    required this.onRecordSale,
  });

  final AppStore store;
  final ProductStatus? initialFilter;
  final ValueChanged<ProductStatus?> onFilterChanged;
  final ValueChanged<String> onRecordSale;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _category = 'All categories';
  ProductStatus? _statusFilter;
  _ProductSort _sort = _ProductSort.name;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != _statusFilter) {
      _statusFilter = widget.initialFilter;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(store: widget.store)),
    );
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          store: widget.store,
          productId: product.id,
          onRecordSale: widget.onRecordSale,
        ),
      ),
    );
  }

  void _setStatusFilter(ProductStatus? status) {
    setState(() => _statusFilter = status);
    widget.onFilterChanged(status);
  }

  List<Product> _filteredProducts(AppStore store) {
    final search = _searchController.text.trim().toLowerCase();
    final filtered = store.products.where((product) {
      final matchesSearch =
          search.isEmpty ||
          product.name.toLowerCase().contains(search) ||
          product.category.toLowerCase().contains(search);
      final matchesCategory =
          _category == 'All categories' || product.category == _category;
      final matchesStatus =
          _statusFilter == null ||
          productStatus(
                product,
                defaultLowStockThreshold: store.settings.lowStockThreshold,
                expirationWarningDays: store.settings.expirationWarningDays,
              ) ==
              _statusFilter;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    switch (_sort) {
      case _ProductSort.name:
        filtered.sort((first, second) => first.name.compareTo(second.name));
      case _ProductSort.lowStock:
        filtered.sort(
          (first, second) => first.quantity.compareTo(second.quantity),
        );
      case _ProductSort.price:
        filtered.sort(
          (first, second) => second.sellingPrice.compareTo(first.sellingPrice),
        );
      case _ProductSort.expiration:
        filtered.sort(
          (first, second) =>
              first.expirationDate.compareTo(second.expirationDate),
        );
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final products = _filteredProducts(store);
        final categories = ['All categories', ...store.settings.categories];
        if (!categories.contains(_category)) _category = 'All categories';

        return Column(
          children: [
            PageHeading(
              title: 'Your inventory',
              imagePath: store.settings.storeImagePath,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: TextField(
                key: const ValueKey('inventory-search-field'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search your products...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 45,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  );
                },
              ),
            ),
            SizedBox(
              height: 45,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: [
                  _filterChip('All', null),
                  _filterChip('Low stock', ProductStatus.lowStock),
                  _filterChip('Near expiration', ProductStatus.nearExpiration),
                  _filterChip('Expired', ProductStatus.expired),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${products.length} ${products.length == 1 ? 'product' : 'products'} in your tindahan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TindaColors.brown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<_ProductSort>(
                    tooltip: 'Sort products',
                    initialValue: _sort,
                    onSelected: (sort) => setState(() => _sort = sort),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _ProductSort.name,
                        child: Text('Name A–Z'),
                      ),
                      PopupMenuItem(
                        value: _ProductSort.lowStock,
                        child: Text('Quantity: lowest first'),
                      ),
                      PopupMenuItem(
                        value: _ProductSort.price,
                        child: Text('Price: highest first'),
                      ),
                      PopupMenuItem(
                        value: _ProductSort.expiration,
                        child: Text('Expiration: soonest first'),
                      ),
                    ],
                    child: Row(
                      children: [
                        Text(
                          _sortLabel(_sort),
                          style: const TextStyle(
                            color: TindaColors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(Icons.unfold_more, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? _emptyInventory(store)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _InventoryProductTile(
                            product: product,
                            status: productStatus(
                              product,
                              defaultLowStockThreshold:
                                  store.settings.lowStockThreshold,
                              expirationWarningDays:
                                  store.settings.expirationWarningDays,
                            ),
                            onTap: () => _openProduct(product),
                            onAdjustStock: () => _adjustStock(product),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: FilledButton.icon(
                key: const ValueKey('add-product-button'),
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add product'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, ProductStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _statusFilter == status,
        onSelected: (_) => _setStatusFilter(status),
      ),
    );
  }

  Widget _emptyInventory(AppStore store) {
    final hasActiveSearch =
        _searchController.text.isNotEmpty ||
        _category != 'All categories' ||
        _statusFilter != null;
    return Center(
      child: SingleChildScrollView(
        child: EmptyShelf(
          title: hasActiveSearch
              ? 'Nothing on this shelf'
              : 'Your shelf starts here',
          detail: hasActiveSearch
              ? 'Try another search or clear the selected filters.'
              : store.products.isEmpty
              ? 'Add your first product. We’ll keep your stock and expiration dates together.'
              : 'No products match these filters.',
          action: hasActiveSearch
              ? OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    _category = 'All categories';
                    _setStatusFilter(null);
                  },
                  child: const Text('Clear filters'),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _adjustStock(Product product) async {
    final controller = TextEditingController(text: product.quantity.toString());
    final formKey = GlobalKey<FormState>();
    final newQuantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: TindaColors.cream,
        title: Text('Update ${product.name} stock'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Pieces on the shelf'),
            validator: (value) => int.tryParse(value ?? '') == null
                ? 'Enter a whole number of 0 or more.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, int.parse(controller.text));
            },
            child: const Text('Save stock'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || newQuantity == null) return;
    try {
      await widget.store.updateStock(product.id, newQuantity);
      if (mounted) showAppMessage(context, 'Shelf count updated.');
    } catch (error) {
      if (mounted) showAppMessage(context, readableError(error), isError: true);
    }
  }

  String _sortLabel(_ProductSort sort) => switch (sort) {
    _ProductSort.name => 'Name',
    _ProductSort.lowStock => 'Stock',
    _ProductSort.price => 'Price',
    _ProductSort.expiration => 'Expiration',
  };
}

enum _ProductSort { name, lowStock, price, expiration }

class _InventoryProductTile extends StatelessWidget {
  const _InventoryProductTile({
    required this.product,
    required this.status,
    required this.onTap,
    required this.onAdjustStock,
  });

  final Product product;
  final ProductStatus status;
  final VoidCallback onTap;
  final VoidCallback onAdjustStock;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: [
              ProductArtwork(
                name: product.name,
                category: product.category,
                imagePath: product.imagePath,
                size: 58,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${product.category} · ${product.quantity} pcs · Exp. ${shortDate(product.expirationDate)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 5),
                    StockStatusBadge(status: status),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    peso(product.sellingPrice),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: 'Update ${product.name} stock',
                    onPressed: onAdjustStock,
                    icon: const Icon(Icons.add_box_outlined),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
