import 'package:flutter/material.dart';

import 'data/app_store.dart';
import 'data/models.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/settings_screen.dart';

export 'data/app_store.dart';
export 'screens/alerts_screen.dart';
export 'screens/auth_screens.dart';
export 'screens/dashboard_screen.dart';
export 'screens/inventory_screen.dart';
export 'screens/sales_screen.dart';
export 'screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});

  final AppStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  ProductStatus? _requestedFilter;
  String? _pendingSaleProductId;

  void _goTo(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showFilteredInventory(ProductStatus status) {
    setState(() {
      _requestedFilter = status;
      _selectedIndex = 1;
    });
  }

  void _recordProductSale(String productId) {
    setState(() {
      _pendingSaleProductId = productId;
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final pages = [
      DashboardScreen(
        store: store,
        onNavigate: _goTo,
        onShowAlerts: _showFilteredInventory,
      ),
      InventoryScreen(
        store: store,
        initialFilter: _requestedFilter,
        onFilterChanged: (filter) => _requestedFilter = filter,
        onRecordSale: _recordProductSale,
      ),
      SalesScreen(store: store, initialProductId: _pendingSaleProductId),
      AlertsScreen(store: store, onRecordSale: _recordProductSale),
      SettingsScreen(store: store),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(
            key: ValueKey('navigation-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            key: ValueKey('navigation-inventory'),
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventory',
          ),
          NavigationDestination(
            key: ValueKey('navigation-sales'),
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Sales',
          ),
          NavigationDestination(
            key: ValueKey('navigation-alerts'),
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_active_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            key: ValueKey('navigation-more'),
            icon: Icon(Icons.menu_rounded),
            selectedIcon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
