import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/models.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';
import 'product_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.onNavigate,
    required this.onShowAlerts,
  });

  final AppStore store;
  final ValueChanged<int> onNavigate;
  final ValueChanged<ProductStatus> onShowAlerts;

  Future<void> _addProduct(BuildContext context) async {
    await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(store: store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final recentSales = [
          ...store.sales,
        ]..sort((first, second) => second.createdAt.compareTo(first.createdAt));
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Maayong adlaw!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Store settings',
                  child: IconButton(
                    tooltip: 'Store settings',
                    onPressed: () => onNavigate(4),
                    icon: const Icon(Icons.storefront_outlined),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: const Color(0xFFFFF0CB),
                      side: const BorderSide(
                        color: TindaColors.brown,
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _GreetingCard(store: store),
            const SizedBox(height: 18),
            Text(
              'Your shelf at a glance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.52,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardSummary(
                  count: '${store.products.length}',
                  label: 'Total products',
                  icon: Icons.inventory_2_outlined,
                  background: const Color(0xFFE7F0F2),
                  onTap: () => onNavigate(1),
                ),
                _DashboardSummary(
                  count: '$totalQuantity pieces',
                  label: 'Total stock',
                  icon: Icons.all_inbox_outlined,
                  background: const Color(0xFFFFF0CB),
                  onTap: () => onNavigate(1),
                ),
                _DashboardSummary(
                  count: peso(store.totalSales),
                  label: 'Sales recorded',
                  icon: Icons.payments_outlined,
                  background: const Color(0xFFE7F0E7),
                  onTap: () => onNavigate(2),
                ),
                _DashboardSummary(
                  count:
                      '${store.lowStockProducts.length} low · ${store.expiringProducts.length + store.expiredProducts.length} date alerts',
                  label: 'Needs attention',
                  icon: Icons.notifications_none_rounded,
                  background: const Color(0xFFFFF0CB),
                  onTap: () => onNavigate(3),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addProduct(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add product'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigate(2),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Record sale'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Shelf reminders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(3),
                  child: const Text('View all →'),
                ),
              ],
            ),
            if (store.lowStockProducts.isEmpty &&
                store.expiringProducts.isEmpty &&
                store.expiredProducts.isEmpty)
              const PaperCard(
                color: Color(0xFFE7F0E7),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: TindaColors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Looking good! Your shelves are up to date.'),
                    ),
                  ],
                ),
              )
            else ...[
              for (final product in [
                ...store.expiredProducts,
                ...store.lowStockProducts.where(
                  (product) => !store.expiredProducts.any(
                    (expired) => expired.id == product.id,
                  ),
                ),
                ...store.expiringProducts,
              ].take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ReminderTile(
                    product: product,
                    status: _reminderStatus(product),
                    onTap: () => _showInventoryFilter(product),
                  ),
                ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent sales',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(2),
                  child: const Text('See all →'),
                ),
              ],
            ),
            if (recentSales.isEmpty)
              const PaperCard(
                child: Text(
                  'No sales yet. Your recorded sales will appear here.',
                ),
              )
            else
              for (final sale in recentSales.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PaperCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: TindaColors.brown,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sale.productName} · ${sale.quantity} pcs',
                                style: Theme.of(context).textTheme.titleMedium,
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
                  ),
                ),
          ],
        );
      },
    );
  }

  int get totalQuantity => store.totalQuantity;

  ProductStatus _reminderStatus(Product product) {
    if (store.expiredProducts.any((item) => item.id == product.id)) {
      return ProductStatus.expired;
    }
    if (store.lowStockProducts.any((item) => item.id == product.id)) {
      return ProductStatus.lowStock;
    }
    return ProductStatus.nearExpiration;
  }

  void _showInventoryFilter(Product product) {
    final status = _reminderStatus(product);
    onShowAlerts(status);
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFFFFF0CB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AwningStripe(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weekdays[now.weekday - 1]}, ${shortDate(now).toUpperCase()}',
                        style: const TextStyle(
                          color: TindaColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kamusta, ${store.currentAccount?.username ?? 'kaibigan'}?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'A little tala today, a smoother tindahan tomorrow.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StoreProfileImage(
                  key: const ValueKey('home-store-profile-image'),
                  imagePath: store.settings.storeImagePath,
                  size: 48,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AwningStripe extends StatelessWidget {
  const _AwningStripe();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: Row(
        children: List.generate(
          10,
          (index) => Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: index.isEven ? TindaColors.red : TindaColors.cream,
                border: const Border(
                  bottom: BorderSide(color: TindaColors.brown, width: 0.8),
                  right: BorderSide(color: TindaColors.brown, width: 0.7),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({
    required this.count,
    required this.label,
    required this.icon,
    required this.background,
    required this.onTap,
  });

  final String count;
  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        count,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  Icon(icon, size: 20, color: TindaColors.brown),
                ],
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TindaColors.brown,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.product,
    required this.status,
    required this.onTap,
  });

  final Product product;
  final ProductStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpired = status == ProductStatus.expired;
    return Card(
      color: isExpired ? const Color(0xFFFBE8E1) : const Color(0xFFFFF0CB),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          child: Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.warning_amber_rounded,
                color: isExpired ? TindaColors.error : TindaColors.amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExpired
                          ? '${product.name} has expired'
                          : status == ProductStatus.lowStock
                          ? '${product.name} is running low'
                          : '${product.name} expires soon',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      status == ProductStatus.lowStock
                          ? '${product.quantity} pcs left · Threshold ${product.lowStockThreshold}'
                          : 'Expires ${shortDate(product.expirationDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TindaColors.brown),
            ],
          ),
        ),
      ),
    );
  }
}
