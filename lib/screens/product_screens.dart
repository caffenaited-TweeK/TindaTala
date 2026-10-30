import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../data/product_image_store.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, required this.store, this.product});

  final AppStore store;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _purchaseCostController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;
  late DateTime _expirationDate;
  late String? _category;
  late String? _imagePath;
  final _imageStore = ProductImageStore();
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _hasUnsavedChanges = false;
  bool _allowPop = false;

  Product? get _product => widget.product;

  @override
  void initState() {
    super.initState();
    final product = _product;
    final categories = widget.store.settings.categories;
    _nameController = TextEditingController(text: product?.name ?? '');
    _sellingPriceController = TextEditingController(
      text: product?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    _purchaseCostController = TextEditingController(
      text: product?.purchaseCost.toStringAsFixed(2) ?? '',
    );
    _quantityController = TextEditingController(
      text: product?.quantity.toString() ?? '0',
    );
    _thresholdController = TextEditingController(
      text:
          (product?.lowStockThreshold ??
                  widget.store.settings.lowStockThreshold)
              .toString(),
    );
    _category =
        product?.category ?? (categories.isEmpty ? null : categories.first);
    _expirationDate =
        product?.expirationDate ?? DateTime.now().add(const Duration(days: 30));
    _imagePath = product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchaseCostController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _selectImage() async {
    setState(() => _isPickingImage = true);
    try {
      final path = await _imageStore.pickAndSaveImage(
        ownerId: widget.store.currentAccount!.normalizedUsername,
      );
      if (path != null && mounted) {
        setState(() {
          _imagePath = path;
          _hasUnsavedChanges = true;
        });
      }
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not choose that photo. ${readableError(error)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _pickExpirationDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Choose the date printed on the package',
    );
    if (selectedDate != null) {
      setState(() {
        _expirationDate = selectedDate;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _category!.trim().isEmpty) {
      showAppMessage(context, 'Choose a product category.', isError: true);
      return;
    }

    final product = Product(
      id:
          _product?.id ??
          '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
      name: _nameController.text.trim(),
      category: _category!,
      sellingPrice: double.parse(_sellingPriceController.text),
      purchaseCost: double.parse(_purchaseCostController.text),
      quantity: int.parse(_quantityController.text),
      expirationDate: DateTime(
        _expirationDate.year,
        _expirationDate.month,
        _expirationDate.day,
      ),
      lowStockThreshold: int.parse(_thresholdController.text),
      imagePath: _imagePath,
    );

    setState(() => _isSaving = true);
    try {
      if (_product == null) {
        await widget.store.addProduct(product);
      } else {
        await widget.store.updateProduct(product);
      }
      if (!mounted) return;
      Navigator.of(context).pop(product);
    } catch (error) {
      if (mounted) showAppMessage(context, readableError(error), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePop() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await confirmAction(
      context,
      title: 'Leave without saving?',
      message: 'Your product changes will be discarded.',
      confirmLabel: 'Discard changes',
      destructive: true,
    );
    if (discard && mounted) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.store.settings.categories;
    final title = _product == null ? 'Add product' : 'Edit product';

    return PopScope<Product?>(
      canPop: !_hasUnsavedChanges || _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_allowPop) _handlePop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _FormAppBar(title: title, onBack: _handlePop),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                    children: [
                      PaperCard(
                        color: const Color(0xFFFFF0CB),
                        child: Row(
                          children: [
                            Icon(
                              _product == null
                                  ? Icons.note_add_outlined
                                  : Icons.edit_note_rounded,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product == null
                                        ? 'A new item for your shelf'
                                        : 'Update your product details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    'Keep the price, stock, and expiry together.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(label: 'Product name *'),
                      TextFormField(
                        key: const ValueKey('product-name-field'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: 80,
                        onChanged: (_) => _markDirty(),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Ligo Sardines',
                          counterText: '',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a product name.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel(label: 'Product illustration'),
                      Row(
                        children: [
                          ProductArtwork(
                            name: _nameController.text.isEmpty
                                ? 'Product'
                                : _nameController.text,
                            category: _category ?? 'Other',
                            imagePath: _imagePath,
                            size: 78,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _isPickingImage
                                      ? null
                                      : _selectImage,
                                  icon: _isPickingImage
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.photo_library_outlined,
                                        ),
                                  label: const Text('Choose from gallery'),
                                ),
                                if (_imagePath != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _imagePath = null;
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text(
                                      'Use sticker illustration',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel(label: 'Category *'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          hintText: 'Choose a category',
                        ),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Row(
                                  children: [
                                    CategoryArtwork(
                                      category: category,
                                      size: 25,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(category),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _category = value;
                            _hasUnsavedChanges = true;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Choose a category.' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _priceField(
                              label: 'Selling price *',
                              controller: _sellingPriceController,
                              hint: '₱ 0.00',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _priceField(
                              label: 'Purchase cost *',
                              controller: _purchaseCostController,
                              hint: '₱ 0.00',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _wholeNumberField(
                              label: 'Initial stock *',
                              controller: _quantityController,
                              minimum: 0,
                              helper: 'Whole pieces on the shelf.',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _wholeNumberField(
                              label: 'Low-stock alert *',
                              controller: _thresholdController,
                              minimum: 0,
                              helper: 'Alert at this count or below.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel(label: 'Expiration date *'),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickExpirationDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            suffixIcon: Icon(Icons.calendar_month_outlined),
                          ),
                          child: Text(shortDate(_expirationDate)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Use the date printed on the product packaging.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        key: const ValueKey('save-product-button'),
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TindaColors.ivory,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _product == null ? 'Save product' : 'Save changes',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _isSaving ? null : _handlePop,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        TextFormField(
          key: ValueKey(
            label == 'Selling price *'
                ? 'selling-price-field'
                : 'purchase-cost-field',
          ),
          controller: controller,
          onChanged: (_) => _markDirty(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(hintText: hint, prefixText: '₱ '),
          validator: (value) {
            final price = double.tryParse(value ?? '');
            if (value == null || value.trim().isEmpty) {
              return 'Required.';
            }
            if (price == null || !price.isFinite || price < 0) {
              return 'Enter 0 or more.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _wholeNumberField({
    required String label,
    required TextEditingController controller,
    required int minimum,
    required String helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        TextFormField(
          key: ValueKey(
            label == 'Initial stock *'
                ? 'stock-quantity-field'
                : 'low-stock-threshold-field',
          ),
          controller: controller,
          onChanged: (_) => _markDirty(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '0'),
          validator: (value) {
            final number = int.tryParse(value ?? '');
            if (number == null || number < minimum) {
              return 'Enter $minimum or more.';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Text(helper, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.store,
    required this.productId,
    required this.onRecordSale,
  });

  final AppStore store;
  final String productId;
  final ValueChanged<String> onRecordSale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        Product? product;
        for (final item in store.products) {
          if (item.id == productId) product = item;
        }
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product details')),
            body: const Center(
              child: Text('This product is no longer available.'),
            ),
          );
        }
        final currentProduct = product;
        final status = productStatus(
          currentProduct,
          defaultLowStockThreshold: store.settings.lowStockThreshold,
          expirationWarningDays: store.settings.expirationWarningDays,
        );

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _FormAppBar(
                  title: 'Product details',
                  onBack: () => Navigator.pop(context),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
                    children: [
                      PaperCard(
                        color: const Color(0xFFFFF0CB),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            ProductArtwork(
                              name: currentProduct.name,
                              category: currentProduct.category,
                              imagePath: currentProduct.imagePath,
                              size: 134,
                            ),
                            const SizedBox(height: 12),
                            StockStatusBadge(status: status),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentProduct.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentProduct.category} · Unit sold per piece',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      _ProductFacts(product: currentProduct),
                      const SizedBox(height: 12),
                      if (status == ProductStatus.expired)
                        const _ProductHint(
                          text: 'This item has expired. Remove it from the selling shelf.',
                          color: Color(0xFFFBE8E1),
                          icon: Icons.error_outline,
                        )
                      else if (status == ProductStatus.lowStock)
                        _ProductHint(
                          text:
                              'Only ${currentProduct.quantity} pieces left. Update stock when you restock.',
                          color: const Color(0xFFFFF0CB),
                          icon: Icons.lightbulb_outline,
                        )
                      else if (status == ProductStatus.nearExpiration)
                        _ProductHint(
                          text:
                              'This product expires in ${daysUntilExpiration(currentProduct)} days.',
                          color: const Color(0xFFFFF0CB),
                          icon: Icons.event_available_outlined,
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _editProduct(context, currentProduct),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onRecordSale(currentProduct.id);
                              },
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('Record sale'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _changeStock(context, currentProduct),
                        icon: const Icon(Icons.inventory_outlined),
                        label: const Text('Update stock quantity'),
                      ),
                      const SizedBox(height: 3),
                      TextButton.icon(
                        key: const ValueKey('delete-product-button'),
                        onPressed: () =>
                            _deleteProduct(context, currentProduct),
                        style: TextButton.styleFrom(
                          foregroundColor: TindaColors.error,
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete product'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editProduct(BuildContext context, Product product) async {
    await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(store: store, product: product),
      ),
    );
  }

  Future<void> _changeStock(BuildContext context, Product product) async {
    final controller = TextEditingController(text: '${product.quantity}');
    final formKey = GlobalKey<FormState>();
    final quantity = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: TindaColors.cream,
        title: const Text('Update shelf quantity'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Pieces on the shelf'),
            validator: (value) => int.tryParse(value ?? '') == null
                ? 'Enter 0 or more pieces.'
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantity == null || !context.mounted) return;
    try {
      await store.updateStock(product.id, quantity);
      if (context.mounted) showAppMessage(context, 'Shelf count updated.');
    } catch (error) {
      if (context.mounted) {
        showAppMessage(context, readableError(error), isError: true);
      }
    }
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete ${product.name}?',
      message: 'This removes it from your inventory. Past sales will stay in your sales history.',
      confirmLabel: 'Delete product',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await store.deleteProduct(product.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (error) {
      if (context.mounted) {
        showAppMessage(context, readableError(error), isError: true);
      }
    }
  }
}

class _ProductFacts extends StatelessWidget {
  const _ProductFacts({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FactItem(
                  label: 'SELLING PRICE',
                  value: peso(product.sellingPrice),
                ),
              ),
              const VerticalDivider(width: 20),
              Expanded(
                child: _FactItem(
                  label: 'AVAILABLE',
                  value: '${product.quantity} pcs',
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _FactItem(
                  label: 'PURCHASE COST',
                  value: peso(product.purchaseCost),
                ),
              ),
              Expanded(
                child: _FactItem(
                  label: 'EXPIRATION DATE',
                  value: shortDate(product.expirationDate),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(child: Text('Low-stock reminder')),
              Text(
                '${product.lowStockThreshold} pieces',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactItem extends StatelessWidget {
  const _FactItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: TindaColors.mutedBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _ProductHint extends StatelessWidget {
  const _ProductHint({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      color: color,
      child: Row(
        children: [
          Icon(icon, color: TindaColors.brown),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _FormAppBar extends StatelessWidget {
  const _FormAppBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              side: const BorderSide(color: TindaColors.brown, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ],
      ),
    );
  }
}
