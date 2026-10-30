import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({
    super.key,
    required this.store,
    required this.initialProductId,
  });

  final AppStore store;
  final String? initialProductId;

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _saleFormKey = GlobalKey<FormState>();
  final _historySearchController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String? _selectedProductId;
  DateTimeRange? _dateFilter;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
  }

  @override
  void didUpdateWidget(covariant SalesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialProductId != oldWidget.initialProductId &&
        widget.initialProductId != null) {
      _selectedProductId = widget.initialProductId;
      _quantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _historySearchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Product? _selectedProduct(AppStore store) {
    for (final product in store.products) {
      if (product.id == _selectedProductId) return product;
    }
    return null;
  }

  Future<void> _recordSale(Product product) async {
    if (!_saleFormKey.currentState!.validate()) return;
    final quantity = int.parse(_quantityController.text);
    if (quantity > product.quantity) {
      showAppMessage(
        context,
        'Only ${product.quantity} ${product.quantity == 1 ? 'piece is' : 'pieces are'} available.',
        isError: true,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: TindaColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm this sale?'),
        content: Text(
          '${product.name} × $quantity\n'
          '${peso(product.sellingPrice)} each · Total ${peso(product.sellingPrice * quantity)}\n\n'
          '${product.quantity - quantity} pieces will remain on the shelf.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-sale-dialog-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm sale'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRecording = true);
    try {
      final sale = await widget.store.recordSale(product.id, quantity);
      if (!mounted) return;
      _quantityController.text = '1';
      showAppMessage(context, 'Sale saved · ${peso(sale.total)}');
    } catch (error) {
      if (mounted) showAppMessage(context, readableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _chooseDateRange() async {
    final today = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 1),
      initialDateRange:
          _dateFilter ??
          DateTimeRange(
            start: DateTime(today.year, today.month, 1),
            end: DateTime(today.year, today.month, today.day),
          ),
      helpText: 'Filter sales by date',
    );
    if (result != null) setState(() => _dateFilter = result);
  }

  List<Sale> _filteredSales(List<Sale> sales) {
    final query = _historySearchController.text.trim().toLowerCase();
    final filtered = sales.where((sale) {
      final matchesName = sale.productName.toLowerCase().contains(query);
      final filter = _dateFilter;
      final saleDate = DateTime(
        sale.createdAt.year,
        sale.createdAt.month,
        sale.createdAt.day,
      );
      final matchesDate =
          filter == null ||
          (!saleDate.isBefore(filter.start) && !saleDate.isAfter(filter.end));
      return matchesName && matchesDate;
    }).toList();
    filtered.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final product = _selectedProduct(store);
        final sales = _filteredSales(store.sales);
        if (product == null &&
            _selectedProductId != null &&
            !store.products.any((item) => item.id == _selectedProductId)) {
          _selectedProductId = null;
        }

        return Column(
          children: [
            const PageHeading(title: 'Record a sale'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
                children: [
                  Text(
                    'Select a product and confirm the tala.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _saleForm(store, product),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sales history',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: _dateFilter == null
                            ? 'Filter sales by date'
                            : 'Change sales date filter',
                        onPressed: _chooseDateRange,
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                      if (_dateFilter != null)
                        IconButton(
                          tooltip: 'Clear date filter',
                          onPressed: () => setState(() => _dateFilter = null),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                  TextField(
                    controller: _historySearchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search sales by product...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _historySearchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _historySearchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  if (_dateFilter != null) ...[
                    const SizedBox(height: 7),
                    Text(
                      '${shortDate(_dateFilter!.start)} – ${shortDate(_dateFilter!.end)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (sales.isEmpty)
                    EmptyShelf(
                      title: store.sales.isEmpty
                          ? 'No sales recorded yet'
                          : 'No sales on these shelves',
                      detail: store.sales.isEmpty
                          ? 'Confirmed sales will be saved here with the stock change.'
                          : 'Try a different product search or date range.',
                    )
                  else
                    for (final sale in sales)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SaleHistoryTile(sale: sale),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _saleForm(AppStore store, Product? product) {
    return PaperCard(
      color: const Color(0xFFFFF0CB),
      padding: const EdgeInsets.all(14),
      child: Form(
        key: _saleFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a product',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const ValueKey('sale-product-dropdown'),
              initialValue: product?.id,
              decoration: const InputDecoration(
                hintText: 'Select a product',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              items: store.products
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        '${item.name} · ${item.quantity} pcs',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedProductId = value;
                _quantityController.text = '1';
              }),
              validator: (value) =>
                  value == null ? 'Choose a product first.' : null,
            ),
            if (product != null) ...[
              const SizedBox(height: 12),
              PaperCard(
                padding: const EdgeInsets.all(11),
                child: Row(
                  children: [
                    ProductArtwork(
                      name: product.name,
                      category: product.category,
                      imagePath: product.imagePath,
                      size: 54,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${peso(product.sellingPrice)} / pc · ${product.quantity} pcs available',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (product.quantity <=
                              product.lowStockThreshold) ...[
                            const SizedBox(height: 4),
                            const StockStatusBadge(
                              status: ProductStatus.lowStock,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Quantity sold',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 7),
              TextFormField(
                key: const ValueKey('sale-quantity-field'),
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter the number of pieces',
                  helperText: 'Maximum ${product.quantity} pieces.',
                  suffixText: 'pcs',
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number <= 0) {
                    return 'Enter a whole number greater than 0.';
                  }
                  if (number > product.quantity) {
                    return 'You only have ${product.quantity} pieces available.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 13),
              _SaleTotal(
                product: product,
                quantity: int.tryParse(_quantityController.text) ?? 0,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('confirm-sale-button'),
                onPressed: _isRecording || product.quantity == 0
                    ? null
                    : () => _recordSale(product),
                icon: _isRecording
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: TindaColors.ivory,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: const Text('Confirm sale'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                store.products.isEmpty
                    ? 'Add products to your inventory before recording a sale.'
                    : 'Pick a product to see its price, available stock, and sale total.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SaleTotal extends StatelessWidget {
  const _SaleTotal({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final total = product.sellingPrice * quantity;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sale total',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: TindaColors.brown),
              ),
              Text(
                '$quantity pcs × ${peso(product.sellingPrice)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Text(
          peso(total),
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: TindaColors.red),
        ),
      ],
    );
  }
}

class _SaleHistoryTile extends StatelessWidget {
  const _SaleHistoryTile({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: TindaColors.brown,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${sale.quantity} pcs × ${peso(sale.unitPrice)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  shortDateTime(sale.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            peso(sale.total),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
