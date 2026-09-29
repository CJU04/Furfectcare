import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/sale_item.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class ProductHistoryScreen extends StatefulWidget {
  const ProductHistoryScreen({super.key, this.recordId});
  final String? recordId;

  @override
  State<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends State<ProductHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String _selectedPeriod = 'All Time';
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 2, vsync: this, initialIndex: widget.recordId == null ? 0 : 1);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        Provider.of<SalesProvider>(context, listen: false).loadSales(),
        Provider.of<SaleItemProvider>(context, listen: false).loadSaleItems(),
        Provider.of<ProductProvider>(context, listen: false).loadProducts(),
      ]);
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

    // Customer allowed, but only their own purchases.

    final uid = authProvider.firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'By Product'),
            Tab(text: 'Per Order'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: '/product_history'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 900 ? 980.0 : double.infinity;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history, size: 22),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Purchase records',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 110,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedPeriod,
                            items: const [
                              'All Time',
                              'This Week',
                              'This Month',
                              'Last Month',
                              'This Year',
                            ]
                                .map((v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v,
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() {
                                _selectedPeriod = v;
                                _selectedProductId = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildByProduct(uid: uid),
                          _buildPerOrder(uid: uid),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildByProduct({required String? uid}) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final saleItemProvider = Provider.of<SaleItemProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final allSales = salesProvider.sales;
    final allSaleItems = saleItemProvider.saleItems;
    final products = productProvider.products;

    final visibleSales = _filterSalesByRoleAndPeriod(allSales);
    final visibleSaleIds = visibleSales
        .where((s) => s.saleId != null)
        .map((s) => s.saleId!)
        .toSet();

    final filteredSaleItems = allSaleItems
        .where((i) => i.saleId != null && visibleSaleIds.contains(i.saleId))
        .toList();

    final Map<String, int> qtyByProduct = {};
    final Map<String, double> revenueByProduct = {};

    for (final item in filteredSaleItems) {
      qtyByProduct[item.productId] =
          (qtyByProduct[item.productId] ?? 0) + item.quantity;
      revenueByProduct[item.productId] =
          (revenueByProduct[item.productId] ?? 0) + item.subtotal;
    }

    final entries = qtyByProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final productRows = entries
        .map((e) => _ProductSummaryRow(
              productId: e.key,
              qty: e.value,
              revenue: revenueByProduct[e.key] ?? 0,
              productName: products
                  .firstWhere(
                    (p) => p.productId == e.key,
                    orElse: () => Product(
                      productId: null,
                      productName: 'Unknown',
                      description: '',
                      price: 0,
                      stockQuantity: 0,
                      category: '',
                    ),
                  )
                  .productName,
            ))
        .toList();

    final selectedProductId = _selectedProductId ??
        (productRows.isNotEmpty ? productRows.first.productId : null);

    if (selectedProductId == null) {
      return const Center(
          child: Text('No purchase history found for this period.'));
    }

    final selectedProduct = products.firstWhere(
      (p) => p.productId == selectedProductId,
      orElse: () => Product(
        productId: null,
        productName: 'Unknown',
        description: '',
        price: 0,
        stockQuantity: 0,
        category: '',
      ),
    );

    final selectedItems = filteredSaleItems
        .where((i) => i.productId == selectedProductId)
        .toList();

    // Group by sale
    final Map<String, List<SaleItem>> itemsBySale = {};
    for (final si in selectedItems) {
      final saleId = si.saleId;
      if (saleId == null) continue;
      itemsBySale.putIfAbsent(saleId, () => []).add(si);
    }

    final selectedSales = visibleSales
        .where((s) => s.saleId != null && itemsBySale.containsKey(s.saleId))
        .toList();
    selectedSales.sort((a, b) => (b.paymentDate).compareTo(a.paymentDate));

    if (MediaQuery.sizeOf(context).width < 650) {
      return ListView(
          children: productRows.map((row) {
        final productItems =
            filteredSaleItems.where((i) => i.productId == row.productId);
        return Card(
            child: ExpansionTile(
          title: Text(row.productName, softWrap: true),
          subtitle:
              Text('${row.qty} purchased • ₱${row.revenue.toStringAsFixed(2)}'),
          children: productItems.map((item) {
            final sale =
                visibleSales.firstWhere((s) => s.saleId == item.saleId);
            return ListTile(
              title: Text(row.productName),
              subtitle: Text(
                  '${sale.date}\n${item.quantity} × ₱${item.price.toStringAsFixed(2)}\nSubtotal: ₱${item.subtotal.toStringAsFixed(2)}'),
              onTap: () => _showOrderDetailDialog(
                  context,
                  sale,
                  filteredSaleItems
                      .where((i) => i.saleId == sale.saleId)
                      .toList(),
                  products),
            );
          }).toList(),
        ));
      }).toList());
    }
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: productRows.length,
                  itemBuilder: (context, index) {
                    final row = productRows[index];
                    final isSelected = row.productId == selectedProductId;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: isSelected ? 4 : 1,
                      child: ListTile(
                        title: Text(row.productName,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${row.qty} sold • ₱${row.revenue.toStringAsFixed(2)}'),
                        trailing: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.chevron_right,
                            color: isSelected ? Colors.green : Colors.grey),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedProductId = row.productId;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History: ${selectedProduct.productName}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedSales.length,
                  itemBuilder: (context, index) {
                    final sale = selectedSales[index];
                    final saleId = sale.saleId;
                    if (saleId == null) {
                      return const SizedBox.shrink();
                    }

                    final lines = itemsBySale[saleId] ?? const <SaleItem>[];
                    final totalQty =
                        lines.fold<int>(0, (sum, e) => sum + e.quantity);
                    final subtotalTotal =
                        lines.fold<double>(0, (sum, e) => sum + e.subtotal);

                    final saleLabel =
                        saleId.length >= 8 ? saleId.substring(0, 8) : saleId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sale #$saleLabel',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Date: ${sale.date}'),
                            const SizedBox(height: 8),
                            Text('Qty: $totalQty'),
                            Text(
                              'Subtotal: ₱${subtotalTotal.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Products: ${lines.length} line(s)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerOrder({required String? uid}) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final saleItemProvider = Provider.of<SaleItemProvider>(context);

    final visibleSales = _filterSalesByRoleAndPeriod(salesProvider.sales);
    final visibleSaleIds = visibleSales
        .where((s) => s.saleId != null)
        .map((s) => s.saleId!)
        .toSet();

    final allItems = saleItemProvider.saleItems;
    final items = allItems
        .where((i) => i.saleId != null && visibleSaleIds.contains(i.saleId))
        .toList();

    // Group by sale
    final Map<String, List<SaleItem>> bySale = {};
    for (final si in items) {
      if (si.saleId == null) continue;
      bySale.putIfAbsent(si.saleId!, () => []).add(si);
    }

    visibleSales.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    if (visibleSales.isEmpty) {
      return const Center(child: Text('No orders found for this period.'));
    }

    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final products = productProvider.products;

    return ListView.builder(
      itemCount: visibleSales.length,
      itemBuilder: (context, index) {
        final sale = visibleSales[index];
        final saleId = sale.saleId;
        if (saleId == null) {
          return const SizedBox.shrink();
        }

        final lines = bySale[saleId] ?? const <SaleItem>[];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => _showOrderDetailDialog(context, sale, lines, products),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sale #${saleId.substring(0, 8)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text('Date: ${sale.date}'),
                  Text('Total: ₱${sale.totalAmount.toStringAsFixed(2)}'),
                  if (sale.customerName.isNotEmpty)
                    Text('Customer: ${sale.customerName}'),
                  if (sale.customerContact.isNotEmpty)
                    Text('Contact: ${sale.customerContact}'),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines.map((li) {
                      final productName = products
                          .firstWhere(
                            (p) => p.productId == li.productId,
                            orElse: () => Product(
                              productId: null,
                              productName: 'Unknown',
                              description: '',
                              price: 0,
                              stockQuantity: 0,
                              category: '',
                            ),
                          )
                          .productName;

                      return Text(
                        '- $productName • ${li.quantity} pcs • ₱${li.subtotal.toStringAsFixed(2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOrderDetailDialog(BuildContext context, Sales sale,
      List<SaleItem> lines, List<Product> products) {
    final theme = Theme.of(context);
    final saleRef = sale.saleId != null && sale.saleId!.length >= 8
        ? sale.saleId!.substring(0, 8)
        : sale.saleId ?? 'N/A';

    final orderRef =
        sale.orderReference.isNotEmpty ? sale.orderReference : null;

    final paymentRef =
        sale.paymentReference.isNotEmpty ? sale.paymentReference : null;

    final orderNotes = sale.orderNotes;

    final productLines = lines.map((li) {
      final product = products.firstWhere(
        (p) => p.productId == li.productId,
        orElse: () => Product(
          productId: null,
          productName: 'Unknown',
          description: '',
          price: 0,
          stockQuantity: 0,
          category: '',
        ),
      );
      return {
        'name': product.productName,
        'qty': li.quantity,
        'price': li.price,
        'subtotal': li.subtotal
      };
    }).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Order Details', style: theme.textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(theme, 'Sale Reference', saleRef),
                if (orderRef != null)
                  _detailRow(theme, 'Order Reference', orderRef),
                _detailRow(theme, 'Date', sale.date),
                if (sale.customerName.isNotEmpty)
                  _detailRow(theme, 'Customer Name', sale.customerName),
                if (sale.customerEmail.isNotEmpty)
                  _detailRow(theme, 'Customer Email', sale.customerEmail),
                if (sale.customerContact.isNotEmpty)
                  _detailRow(theme, 'Customer Contact', sale.customerContact),
                if (sale.customerAddress.isNotEmpty)
                  _detailRow(theme, 'Customer Address', sale.customerAddress),
                _detailRow(theme, 'Payment Method', sale.paymentMethod),
                _detailRow(theme, 'Payment Status', sale.paymentStatus),
                _detailRow(theme, 'Order Status', sale.orderStatus),
                if (paymentRef != null)
                  _detailRow(theme, 'Payment Reference', paymentRef),
                if (orderNotes != null)
                  _detailRow(theme, 'Order Notes', orderNotes),
                const Divider(),
                const SizedBox(height: 8),
                Text('Products', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...productLines.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${p['name']} x${p['qty']} @ ₱${(p['price'] as double).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '₱${(p['subtotal'] as double).toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium),
                    Text(
                      '₱${sale.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  List<Sales> _filterSalesByRoleAndPeriod(List<Sales> sales) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final roleValue = authProvider.role?.value;
    final uid = authProvider.firebaseUser?.uid;

    final periodFiltered = _filterSalesByPeriod(sales, _selectedPeriod)
        .where((s) =>
            widget.recordId == null ||
            // Notifications may link either the Firestore sale id or the
            // human-readable order reference — accept both so the "View
            // purchase" navigation always lands on the order.
            s.saleId == widget.recordId ||
            s.orderReference == widget.recordId)
        .toList();

    // Role-based: customer sees only their own purchases.
    if (roleValue == 'customer') {
      if (uid == null) return const [];
      return periodFiltered.where((s) => s.ownerUid == uid).toList();
    }

    // Admin/staff/vet: all purchases.
    return periodFiltered;
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
        return saleDate
                .isAfter(currentWeekStart.subtract(const Duration(days: 1))) &&
            saleDate.isBefore(currentWeekEnd.add(const Duration(days: 1)));
      }).toList();
    }

    if (period == 'This Month') {
      return allSales.where((sale) {
        final saleDate = DateTime.parse(sale.date);
        return saleDate.year == currentMonth.year &&
            saleDate.month == currentMonth.month;
      }).toList();
    }

    if (period == 'This Year') {
      return allSales.where((sale) {
        final saleDate = DateTime.parse(sale.date);
        return saleDate.year == now.year;
      }).toList();
    }

    // Last Month
    return allSales.where((sale) {
      final saleDate = DateTime.parse(sale.date);
      return saleDate.year == lastMonth.year &&
          saleDate.month == lastMonth.month;
    }).toList();
  }
}

class _ProductSummaryRow {
  final String productId;
  final String productName;
  final int qty;
  final double revenue;

  _ProductSummaryRow({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.revenue,
  });
}
