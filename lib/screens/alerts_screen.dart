import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'product_screens.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.store,
    required this.onRecordSale,
  });

  final AppStore store;
  final ValueChanged<String> onRecordSale;

  Future<void> _openProduct(BuildContext context, Product product) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          store: store,
          productId: product.id,
          onRecordSale: onRecordSale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final expired = store.expiredProducts;
        final lowStock = store.lowStockProducts;
        final expiring = store.expiringProducts;
        final alertCount =
            expired.length +
            lowStock
                .where(
                  (item) => !expired.any((expired) => expired.id == item.id),
                )
                .length +
            expiring.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Shelf reminders',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            PaperCard(
              color: const Color(0xFFFFF0CB),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$alertCount ${alertCount == 1 ? 'product needs' : 'products need'} your attention',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Expiration notices use your ${store.settings.expirationWarningDays}-day reminder.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AlertSection(
              title: 'Remove from shelf',
              count: expired.length,
              badge: 'expired',
              color: const Color(0xFFFBE8E1),
              icon: Icons.error_outline_rounded,
              products: expired,
              emptyText: 'No expired products. Your shelves are clear.',
              detail: (product) =>
                  '${product.quantity} pcs · Expired ${shortDate(product.expirationDate)} · Do not sell',
              onOpen: (product) => _openProduct(context, product),
            ),
            const SizedBox(height: 16),
            _AlertSection(
              title: 'Time to restock',
              count: lowStock.length,
              badge: 'low stock',
              color: const Color(0xFFFFF0CB),
              icon: Icons.inventory_outlined,
              products: lowStock,
              emptyText: 'No low-stock products.',
              detail: (product) =>
                  '${product.quantity} pcs left · Low-stock reminder: ${product.lowStockThreshold}',
              onOpen: (product) => _openProduct(context, product),
              onUpdateStock: (product) => _changeStock(context, product),
            ),
            const SizedBox(height: 16),
            _AlertSection(
              title: 'Sell these first',
              count: expiring.length,
              badge: 'near expiration',
              color: const Color(0xFFFFF0CB),
              icon: Icons.event_available_outlined,
              products: expiring,
              emptyText: 'No products approaching expiration.',
              detail: (product) {
                final days = daysUntilExpiration(product);
                return '${product.quantity} pcs · Expires ${shortDate(product.expirationDate)} · ${days == 0 ? 'today' : 'in $days days'}';
              },
              onOpen: (product) => _openProduct(context, product),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeStock(BuildContext context, Product product) async {
    final controller = TextEditingController(text: '${product.quantity}');
    final formKey = GlobalKey<FormState>();
    final quantity = await showDialog<int>(
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
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.title,
    required this.count,
    required this.badge,
    required this.color,
    required this.icon,
    required this.products,
    required this.emptyText,
    required this.detail,
    required this.onOpen,
    this.onUpdateStock,
  });

  final String title;
  final int count;
  final String badge;
  final Color color;
  final IconData icon;
  final List<Product> products;
  final String emptyText;
  final String Function(Product) detail;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product>? onUpdateStock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            _CountBadge(count: count, label: badge, color: color),
          ],
        ),
        const SizedBox(height: 8),
        if (products.isEmpty)
          PaperCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: TindaColors.green),
                const SizedBox(width: 10),
                Expanded(child: Text(emptyText)),
              ],
            ),
          )
        else
          for (final product in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlertProductTile(
                product: product,
                detail: detail(product),
                icon: icon,
                color: color,
                onTap: () => onOpen(product),
                onUpdateStock: onUpdateStock == null
                    ? null
                    : () => onUpdateStock!(product),
              ),
            ),
      ],
    );
  }
}

class _AlertProductTile extends StatelessWidget {
  const _AlertProductTile({
    required this.product,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onUpdateStock,
  });

  final Product product;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onUpdateStock;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(detail, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (onUpdateStock != null)
                IconButton(
                  tooltip: 'Update ${product.name} stock',
                  onPressed: onUpdateStock,
                  icon: const Icon(Icons.add_box_outlined),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count $label',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: TindaColors.brown, fontWeight: FontWeight.w800),
      ),
    );
  }
}
