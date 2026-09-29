import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/inventory_log.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/inventory_log_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/views/screens/access_denied_screen.dart';

class InventoryLogsScreen extends StatefulWidget {
  const InventoryLogsScreen({super.key});

  @override
  State<InventoryLogsScreen> createState() => _InventoryLogsScreenState();
}

class _InventoryLogsScreenState extends State<InventoryLogsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Newest first';

  static const _sortOptions = <String>[
    'Newest first',
    'Oldest first',
    'Reason (A-Z)',
    'Quantity (high first)',
    'Quantity (low first)',
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<InventoryLogProvider>(context, listen: false)
        .loadInventoryLogs();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final isCustomer = role?.value == 'customer';

    if (isCustomer) {
      return const AccessDeniedScreen();
    }

    final inventoryLogProvider = Provider.of<InventoryLogProvider>(context);
    final inventoryLogsAll = inventoryLogProvider.inventoryLogs;

    // Cache ProductProvider and products outside the list item builder.
    // This avoids repeatedly looking up the provider for every row.
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    List<InventoryLog> inventoryLogs = inventoryLogsAll;

    String productName(String productId) {
      for (final p in products) {
        if (p.productId == productId) return p.productName;
      }
      return '';
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      inventoryLogs = inventoryLogs
          .where((log) =>
              log.date.toLowerCase().contains(q) ||
              log.reason.toLowerCase().contains(q) ||
              log.quantityChange.toString().contains(q) ||
              productName(log.productId).toLowerCase().contains(q))
          .toList();
    }

    // Copy before sorting so the provider's internal list is never mutated.
    inventoryLogs = List<InventoryLog>.from(inventoryLogs);
    switch (_sortBy) {
      case 'Oldest first':
        inventoryLogs.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
        break;
      case 'Reason (A-Z)':
        inventoryLogs.sort(
            (a, b) => a.reason.toLowerCase().compareTo(b.reason.toLowerCase()));
        break;
      case 'Quantity (high first)':
        inventoryLogs
            .sort((a, b) => b.quantityChange.compareTo(a.quantityChange));
        break;
      case 'Quantity (low first)':
        inventoryLogs
            .sort((a, b) => a.quantityChange.compareTo(b.quantityChange));
        break;
      default:
        inventoryLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Logs'),
      ),
      drawer: const AppDrawer(currentRoute: '/inventory_logs'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth =
                constraints.maxWidth > 600 ? 800 : double.infinity;
            double horizontalPadding = constraints.maxWidth > 600
                ? (constraints.maxWidth - 800) / 2
                : 0;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search Inventory Logs',
                                hintText:
                                    'Date, reason, quantity or product name',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _sortBy,
                            underline: const SizedBox.shrink(),
                            items: _sortOptions
                                .map((o) =>
                                    DropdownMenuItem(value: o, child: Text(o)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _sortBy = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                inventoryLogs.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('No inventory logs found'),
                        ),
                      )
                    : SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        sliver: SliverList.builder(
                          itemCount: inventoryLogs.length,
                          itemBuilder: (context, index) {
                            final log = inventoryLogs[index];
                            final product = products.firstWhere(
                              (p) => p.productId == log.productId,
                              orElse: () => Product(
                                productName: 'Unknown Product',
                                category: '',
                                description: '',
                                price: 0.0,
                                stockQuantity: 0,
                              ),
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(
                                  '${product.productName} - ${log.reason}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${log.date} - Qty: ${log.quantityChange}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
