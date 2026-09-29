import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/views/screens/access_denied_screen.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/views/widgets/shimmer_loading.dart';
import 'package:vetcare_connect/utils/export/report_exporter.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<SalesProvider>(context, listen: false).loadSales();
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<SaleItemProvider>(context, listen: false).loadSaleItems();
    });
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
        body: RefreshIndicator(
          onRefresh: () async {
            final salesProvider =
                Provider.of<SalesProvider>(context, listen: false);
            final productProvider =
                Provider.of<ProductProvider>(context, listen: false);
            final saleItemProvider =
                Provider.of<SaleItemProvider>(context, listen: false);
            await salesProvider.loadSales();
            await productProvider.loadProducts();
            await saleItemProvider.loadSaleItems();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth > 600 ? 900 : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSalesReport(),
                        _buildInventoryReport(),
                        _buildProductsReport(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ));
  }

  Widget _buildSalesReport() {
    final salesProvider = Provider.of<SalesProvider>(context);
    final allSales = salesProvider.sales;

    if (salesProvider.isLoading) {
      return const Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            children: [
              ShimmerLoading(
                  width: double.infinity,
                  height: 220,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: ShimmerLoading(
                          width: double.infinity,
                          height: 90,
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                  SizedBox(width: 12),
                  Expanded(
                      child: ShimmerLoading(
                          width: double.infinity,
                          height: 90,
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                ],
              ),
              SizedBox(height: 24),
              ShimmerLoading(
                  width: double.infinity,
                  height: 160,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(height: 24),
              ShimmerLoading(
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
            ],
          ));
    }

    final filteredSales = _filterSalesByPeriod(allSales, _selectedPeriod);

    final totalSales = filteredSales.fold<double>(
      0.0,
      (sum, sale) => sum + sale.totalAmount,
    );
    final totalTransactions = filteredSales.length;

    final groupedByDate = <String, double>{};
    for (final sale in filteredSales) {
      groupedByDate[sale.date] =
          (groupedByDate[sale.date] ?? 0.0) + sale.totalAmount;
    }
    final sortedDates = groupedByDate.keys.toList()..sort();
    final chartEntries =
        sortedDates.map((d) => MapEntry(d, groupedByDate[d]!)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sales Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: _selectedPeriod,
                    items: [
                      'All Time',
                      'This Week',
                      'This Month',
                      'Last Month',
                      'This Year'
                    ]
                        .map((value) => DropdownMenuItem<String>(
                              value: value,
                              child:
                                  Text(value, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedPeriod = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _ExportButton(
                  tooltip: 'Export transactions as CSV',
                  onPressed: filteredSales.isEmpty
                      ? null
                      : () => _exportSalesCsv(filteredSales, _selectedPeriod),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Total Sales',
                  value: '₱${totalSales.toStringAsFixed(2)}',
                  color: Theme.of(context).colorScheme.primaryContainer,
                  textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  label: 'Total Transactions',
                  value: '$totalTransactions',
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sales by Date',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth > 600 ? 260.0 : 220.0;
              // Guard maxY: reduce() on an empty list and NaN/Infinity values
              // both crash fl_chart. Fall back to a safe default.
              double chartMaxY = 100.0;
              try {
                if (chartEntries.isNotEmpty) {
                  final peak = chartEntries
                      .map((e) => e.value.isFinite ? e.value : 0.0)
                      .fold<double>(0.0, (a, b) => a > b ? a : b);
                  chartMaxY = (peak <= 0 ? 100.0 : peak) * 1.15;
                }
              } catch (_) {
                chartMaxY = 100.0;
              }
              return SizedBox(
                height: chartHeight + 80,
                child: chartEntries.isEmpty
                    ? _EmptyState(
                        message: 'No sales available for the selected period.',
                        icon: Icons.show_chart,
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceBetween,
                          maxY: chartMaxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) =>
                                  Theme.of(context).colorScheme.surface,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final dateLabel = chartEntries[group.x].key;
                                final value = chartEntries[group.x].value;
                                return BarTooltipItem(
                                  '$dateLabel\n₱${value.toStringAsFixed(2)}',
                                  TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= chartEntries.length)
                                    return const SizedBox.shrink();
                                  final label =
                                      _shortDate(chartEntries[index].key);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 32,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 48,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '₱${value.toInt()}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups:
                              List.generate(chartEntries.length, (index) {
                            final value = chartEntries[index].value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  width: 24,
                                  borderRadius: BorderRadius.circular(6),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Icon(
                Icons.list_alt,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: filteredSales.isEmpty
                ? _EmptyState(
                    message: 'No transactions found for the selected period.',
                    icon: Icons.receipt_long,
                  )
                : SingleChildScrollView(
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
                          final timeDisplay =
                              _extractTimeDisplay(sale.paymentDate);

                          return DataRow(
                            onSelectChanged: (selected) {
                              if (selected != true) return;

                              final id = sale.saleId;
                              if (id == null) return;

                              _showSalesDetailsDialog(id, [sale]);
                            },
                            cells: [
                              DataCell(Text(sale.date)),
                              DataCell(Text(timeDisplay)),
                              DataCell(
                                Text(
                                  '₱${sale.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
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

    final lowStockProducts =
        products.where((p) => p.stockQuantity < 10).toList();
    final outOfStockProducts =
        products.where((p) => p.stockQuantity == 0).toList();

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
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Inventory Summary',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _ExportButton(
                tooltip: 'Export inventory as CSV',
                onPressed: products.isEmpty
                    ? null
                    : () => _exportInventoryCsv(products),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Products:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${products.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
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
                  size: 24, color: Theme.of(context).colorScheme.primary),
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
              child: lowStockProducts.isEmpty
                  ? _EmptyState(
                      message: 'All products are sufficiently stocked.',
                      icon: Icons.check_circle,
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
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
                          final statusColor = product.stockQuantity == 0
                              ? Colors.red
                              : Colors.orange;
                          final statusText = product.stockQuantity == 0
                              ? 'Out of Stock'
                              : 'Low Stock';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  product.productName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
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
                                  '₱${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
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
          ),
        ],
      ),
    );
  }

  DateTime? _safeSaleDate(Sales sale) {
    // Sales.date is stored as yyyy-MM-dd but old rows may be ISO datetimes
    // or empty. Never let one bad row crash the whole Reports screen.
    try {
      final raw = sale.date.trim();
      if (raw.isEmpty) {
        return _safeSaleDateFromPayment(sale.paymentDate);
      }
      return DateTime.parse(raw);
    } catch (_) {
      return _safeSaleDateFromPayment(sale.paymentDate);
    }
  }

  DateTime? _safeSaleDateFromPayment(String paymentDate) {
    try {
      final raw = paymentDate.trim();
      if (raw.isEmpty) return null;
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
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
        final saleDate = _safeSaleDate(sale);
        if (saleDate == null) return false;
        return saleDate
                .isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
            saleDate.isBefore(currentWeekEnd.add(const Duration(days: 1)));
      }).toList();
    }

    if (period == 'This Month') {
      return allSales.where((sale) {
        final saleDate = _safeSaleDate(sale);
        if (saleDate == null) return false;
        return saleDate.year == currentMonth.year &&
            saleDate.month == currentMonth.month;
      }).toList();
    }

    if (period == 'This Year') {
      return allSales.where((sale) {
        final saleDate = _safeSaleDate(sale);
        if (saleDate == null) return false;
        return saleDate.year == now.year;
      }).toList();
    }

    return allSales.where((sale) {
      final saleDate = _safeSaleDate(sale);
      if (saleDate == null) return false;
      return saleDate.year == lastMonth.year &&
          saleDate.month == lastMonth.month;
    }).toList();
  }

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

  String _shortDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      if (parts.length >= 2) return '${parts[1]}/${parts[2].split(' ').first}';
    } catch (_) {}
    return isoDate;
  }

  Widget _buildProductsReport() {
    final salesProvider = Provider.of<SalesProvider>(context);
    final saleItemProvider = Provider.of<SaleItemProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final allSales = salesProvider.sales;
    final allSaleItems = saleItemProvider.saleItems;
    final products = productProvider.products;

    final filteredSales =
        _filterSalesByPeriod(allSales, _selectedProductPeriod);
    final filteredSaleIds =
        filteredSales.map((s) => s.saleId).where((id) => id != null).toSet();

    final Map<String, int> productQty = {};
    final Map<String, double> productRevenue = {};
    for (final item in allSaleItems) {
      if (item.saleId != null && filteredSaleIds.contains(item.saleId)) {
        productQty[item.productId] =
            (productQty[item.productId] ?? 0) + item.quantity;
        productRevenue[item.productId] =
            (productRevenue[item.productId] ?? 0) + item.subtotal;
      }
    }

    final sortedEntries = productQty.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = sortedEntries.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Most Sold Products',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 160,
                child: DropdownButton<String>(
                  isDense: true,
                  isExpanded: true,
                  value: _selectedProductPeriod,
                  items: [
                    'All Time',
                    'This Week',
                    'This Month',
                    'Last Month',
                    'This Year'
                  ]
                      .map((value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedProductPeriod = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              _ExportButton(
                tooltip: 'Export product rankings as CSV',
                onPressed: topProducts.isEmpty
                    ? null
                    : () => _exportProductsCsv(topProducts, productRevenue,
                        products, _selectedProductPeriod),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: _EmptyState(
                message: 'No sales data for this period.',
                icon: Icons.inbox,
              ),
            )
          else
            Column(
              children: [
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxQty = topProducts
                        .map((e) => e.value)
                        .reduce((a, b) => a > b ? a : b);
                    final chartWidth = constraints.maxWidth > 600
                        ? 500.0
                        : constraints.maxWidth - 32;
                    return SizedBox(
                      height: 220.0 + topProducts.length * 42.0,
                      width: chartWidth,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (maxQty * 1.2).toDouble(),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= topProducts.length)
                                    return const SizedBox.shrink();
                                  final product = products.firstWhere(
                                    (p) =>
                                        p.productId == topProducts[index].key,
                                    orElse: () => Product(
                                        productId: null,
                                        productName: 'Unknown',
                                        description: '',
                                        price: 0,
                                        stockQuantity: 0,
                                        category: ''),
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: SizedBox(
                                      width: 90,
                                      child: Text(
                                        product.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 52,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(topProducts.length, (index) {
                            final value = topProducts[index].value.toDouble();
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  width: 22,
                                  borderRadius: BorderRadius.circular(6),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Icon(
                      Icons.format_list_bulleted,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Top 5 Details',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(topProducts.length, (index) {
                  final entry = topProducts[index];
                  final product = products.firstWhere(
                    (p) => p.productId == entry.key,
                    orElse: () => Product(
                        productId: null,
                        productName: 'Unknown',
                        description: '',
                        price: 0,
                        stockQuantity: 0,
                        category: ''),
                  );
                  final qty = entry.value;
                  final revenue = productRevenue[entry.key] ?? 0;
                  final rank = index + 1;
                  final rankColor = index == 0
                      ? Colors.amber
                      : (index == 1
                          ? Colors.grey.shade400
                          : (index == 2
                              ? Colors.brown.shade300
                              : Colors.grey.shade200));
                  final rankTextColor =
                      index == 0 ? Colors.black : Colors.white;

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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.category,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.green),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₱${revenue.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 12),
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
        ],
      ),
    );
  }

  Future<void> _exportSalesCsv(List<Sales> sales, String period) async {
    final rows = <List<String>>[
      [
        'Date',
        'Time',
        'Customer',
        'Payment Method',
        'Payment Status',
        'Order Status',
        'Order Reference',
        'Total Amount (PHP)'
      ],
      for (final s in sales)
        [
          s.date,
          _extractTimeDisplay(s.paymentDate),
          s.customerName,
          s.paymentMethod,
          s.paymentStatus,
          s.orderStatus,
          s.orderReference,
          s.totalAmount.toStringAsFixed(2),
        ],
    ];
    await _saveExport(
      fileName: 'sales_report_${_periodSlug(period)}.csv',
      csv: buildCsv(rows),
    );
  }

  Future<void> _exportInventoryCsv(List<Product> products) async {
    final rows = <List<String>>[
      ['Product Name', 'Category', 'Price (PHP)', 'Stock Quantity', 'Status'],
      for (final p in products)
        [
          p.productName,
          p.category,
          p.price.toStringAsFixed(2),
          '${p.stockQuantity}',
          p.stockQuantity == 0
              ? 'Out of Stock'
              : (p.stockQuantity < 10 ? 'Low Stock' : 'In Stock'),
        ],
    ];
    await _saveExport(
      fileName: 'inventory_report_${_periodSlug('All Time')}.csv',
      csv: buildCsv(rows),
    );
  }

  Future<void> _exportProductsCsv(
    List<MapEntry<String, int>> topProducts,
    Map<String, double> productRevenue,
    List<Product> products,
    String period,
  ) async {
    final rows = <List<String>>[
      ['Rank', 'Product', 'Category', 'Units Sold', 'Revenue (PHP)'],
      for (var i = 0; i < topProducts.length; i++)
        [
          '${i + 1}',
          products
              .firstWhere(
                (p) => p.productId == topProducts[i].key,
                orElse: () => Product(
                    productId: null,
                    productName: 'Unknown product',
                    description: '',
                    price: 0,
                    stockQuantity: 0,
                    category: ''),
              )
              .productName,
          products
              .firstWhere(
                (p) => p.productId == topProducts[i].key,
                orElse: () => Product(
                    productId: null,
                    productName: 'Unknown product',
                    description: '',
                    price: 0,
                    stockQuantity: 0,
                    category: ''),
              )
              .category,
          '${topProducts[i].value}',
          (productRevenue[topProducts[i].key] ?? 0).toStringAsFixed(2),
        ],
    ];
    await _saveExport(
      fileName: 'top_products_${_periodSlug(period)}.csv',
      csv: buildCsv(rows),
    );
  }

  Future<void> _saveExport(
      {required String fileName, required String csv}) async {
    try {
      final saved = await saveTextFile(fileName: fileName, content: csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              saved ? 'Report exported as $fileName' : 'Export cancelled.'),
          backgroundColor: saved ? Colors.green : Colors.orange,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not export the report. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _periodSlug(String period) =>
      period.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  void _showSalesDetailsDialog(String saleId, List<Sales> sales) {
    if (sales.isEmpty) return;

    final sale = sales.first;
    final saleItemsAtOpen =
        Provider.of<SaleItemProvider>(context, listen: false)
            .saleItems
            .where((item) => item.saleId == saleId)
            .toList();
    final productsAtOpen =
        Provider.of<ProductProvider>(context, listen: false).products.toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // saleId may be longer or shorter than 8 chars; never crash on substring.
        final shortId = saleId.length > 8 ? saleId.substring(0, 8) : saleId;
        return AlertDialog(
          title: Text('Sales Details for Sale #$shortId'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${sale.date}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${_extractTimeDisplay(sale.paymentDate)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (sale.customerName.isNotEmpty)
                    Text(
                      'Customer: ${sale.customerName}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  if (sale.customerEmail.isNotEmpty)
                    Text(
                      'Email: ${sale.customerEmail}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  if (sale.customerContact.isNotEmpty)
                    Text(
                      'Contact: ${sale.customerContact}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  if (sale.customerAddress.isNotEmpty)
                    Text(
                      'Address: ${sale.customerAddress}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment Method: ${sale.paymentMethod}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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
                        DataColumn(
                            label: Text('Product',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Price',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Subtotal',
                                style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: saleItemsAtOpen.map<DataRow>((item) {
                        final product = productsAtOpen.firstWhere(
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
                              Text(
                                  '₱${(item.price * item.quantity).toStringAsFixed(2)}'),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Amount: ₱${sale.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                    scale: 0.7 + (0.3 * value), child: child);
              },
              child: Icon(icon,
                  size: 52, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)), child: child),
                );
              },
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact CSV export button used in the header row of each report tab.
/// Disabled (greyed out) when there is nothing to export.
class _ExportButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;

  const _ExportButton({required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.outlined(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: const Icon(Icons.ios_share, size: 20),
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }
}
