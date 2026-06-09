import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/views/screens/access_denied_screen.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedPeriod = 'All Time';
  String _selectedProductPeriod = 'All Time';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Preload data used by the tabs.
    Provider.of<SalesProvider>(context, listen: false).loadSales();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;

    // Customers are not allowed to view reports.
    if (role?.value == 'customer') {
      return const AccessDeniedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales Report'),
            Tab(text: 'Inventory Report'),
            Tab(text: 'Products Report'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/reports'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 900 : double.infinity;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesReport(),
                _buildInventoryReport(),
                _buildProductsReport(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesReport() {
    final salesProvider = Provider.of<SalesProvider>(context);
    final allSales = salesProvider.sales;

    final filteredSales = _filterSalesByPeriod(allSales, _selectedPeriod);

    final totalSales = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final totalTransactions = filteredSales.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 28,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Sales Summary',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: _selectedPeriod,
                    items: ['All Time', 'This Week', 'This Month', 'Last Month', 'This Year']
                        .map((value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedPeriod = value);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Sales:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
'💰${totalSales.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Transactions:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$totalTransactions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sales by Date',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Time',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Amount',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: filteredSales.map((sale) {
                    final timeDisplay = _extractTimeDisplay(sale.paymentDate);

                    return DataRow(
                      onSelectChanged: (selected) {
                        if (selected != true) return;

                        // saleid is nullable in the model; guard to avoid runtime errors.
                        final id = sale.saleId;
                        if (id == null) return;

                        _showSalesDetailsDialog(id, [sale]);
                      },
                      cells: [
                        DataCell(Text(sale.date)),
                        DataCell(Text(timeDisplay)),
                        DataCell(
                          Text(
'💰${sale.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryReport() {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    final lowStockProducts = products.where((p) => p.stockQuantity < 10).toList();
    final outOfStockProducts = products.where((p) => p.stockQuantity == 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Inventory Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Products:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${products.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Low Stock (<10):',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      '${lowStockProducts.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Out of Stock:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      '${outOfStockProducts.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Icon(Icons.warning_amber,
                  size: 24, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Low Stock Products',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'Product Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Stock Quantity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Price',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: lowStockProducts.map((product) {
                  final statusColor =
                      product.stockQuantity == 0 ? Colors.red : Colors.orange;
                  final statusText =
                      product.stockQuantity == 0 ? 'Out of Stock' : 'Low Stock';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          product.productName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${product.stockQuantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
'💰${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Sales> _filterSalesByPeriod(List<Sales> allSales, String period) {
    if (period == 'All Time') return allSales;

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

    if (period == 'This Week') {
      return allSales.where((sale) {
        final saleDate = DateTime.parse(sale.date);
        return saleDate.isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
            saleDate.isBefore(currentWeekEnd.add(const Duration(days: 1)));
      }).toList();
    }

    if (period == 'This Month') {
      return allSales.where((sale) {
        final saleDate = DateTime.parse(sale.date);
        return saleDate.year == currentMonth.year && saleDate.month == currentMonth.month;
      }).toList();
    }

    if (period == 'This Year') {
      return allSales.where((sale) {
        final saleDate = DateTime.parse(sale.date);
        return saleDate.year == now.year;
      }).toList();
    }

    return allSales.where((sale) {
      final saleDate = DateTime.parse(sale.date);
      return saleDate.year == lastMonth.year && saleDate.month == lastMonth.month;
    }).toList();
  }

  /// Extract time display from `paymentDate`.
  /// Handles ISO strings like `YYYY-MM-DDTHH:MM:SS...`.
  String _extractTimeDisplay(String paymentDate) {
    try {
      if (paymentDate.contains('T')) {
        final partsIso = paymentDate.split('T');
        if (partsIso.length > 1) {
          final timePart = partsIso[1];
          if (timePart.length >= 8) return timePart.substring(0, 8);
        }
      }

      if (paymentDate.contains(' ')) {
        final partsSpace = paymentDate.split(' ');
        if (partsSpace.length > 1) {
          final timePart = partsSpace[1];
          return timePart.length >= 8 ? timePart.substring(0, 8) : timePart;
        }
      }

      return 'N/A';
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildProductsReport() {
    final salesProvider = Provider.of<SalesProvider>(context);
    final saleItemProvider = Provider.of<SaleItemProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final allSales = salesProvider.sales;
    final allSaleItems = saleItemProvider.saleItems;
    final products = productProvider.products;

    final filteredSales = _filterSalesByPeriod(allSales, _selectedProductPeriod);
    final filteredSaleIds = filteredSales.map((s) => s.saleId).where((id) => id != null).toSet();

    // Aggregate quantity sold per product
    final Map<String, int> productQty = {};
    final Map<String, double> productRevenue = {};
    for (final item in allSaleItems) {
      if (item.saleId != null && filteredSaleIds.contains(item.saleId)) {
        productQty[item.productId] = (productQty[item.productId] ?? 0) + item.quantity;
        productRevenue[item.productId] = (productRevenue[item.productId] ?? 0) + item.subtotal;
      }
    }

    // Sort by quantity descending
    final sortedEntries = productQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = sortedEntries.take(20).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Most Sold Products',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 160),
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _selectedProductPeriod,
                  items: ['All Time', 'This Week', 'This Month', 'Last Month', 'This Year']
                      .map((value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedProductPeriod = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: const Text('No sales data for this period', style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          else
            ...List.generate(topProducts.length, (index) {
              final entry = topProducts[index];
              final product = products.firstWhere(
                (p) => p.productId == entry.key,
                orElse: () => Product(productId: null, productName: 'Unknown', description: '', price: 0, stockQuantity: 0, category: ''),
              );
              final qty = entry.value;
              final revenue = productRevenue[entry.key] ?? 0;
              final rank = index + 1;
              final rankColor = index == 0 ? Colors.amber : (index == 1 ? Colors.grey.shade400 : (index == 2 ? Colors.brown.shade300 : Colors.grey.shade200));
              final rankTextColor = index == 0 ? Colors.black : Colors.white;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: rankColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: rankTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$qty sold',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
'💰${revenue.toStringAsFixed(2)}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showSalesDetailsDialog(String saleId, List<Sales> sales) {
    if (sales.isEmpty) return;

    final sale = sales.first;

    final saleItemProvider = Provider.of<SaleItemProvider>(context, listen: false);
    final saleItems =
        saleItemProvider.saleItems.where((item) => item.saleId == saleId).toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Sales Details for Sale #${saleId.substring(0, 8)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${sale.date}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${_extractTimeDisplay(sale.paymentDate)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Method: ${sale.paymentMethod}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Products Sold:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: saleItems.map<DataRow>((item) {
                        final productProvider =
                            Provider.of<ProductProvider>(dialogContext, listen: false);

                        final product = productProvider.products.firstWhere(
                          (p) => p.productId == item.productId,
                          orElse: () => Product(
                            productId: null,
                            productName: 'Unknown Product',
                            description: '',
                            price: 0.0,
                            stockQuantity: 0,
                            category: '',
                          ),
                        );

                        return DataRow(
                          cells: [
                            DataCell(Text(product.productName)),
                            DataCell(Text('${item.quantity}')),
                            DataCell(Text('₱${item.price.toStringAsFixed(2)}')),
                            DataCell(
                              Text('₱${(item.price * item.quantity).toStringAsFixed(2)}'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
'Total Amount: 💰${sale.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
}

