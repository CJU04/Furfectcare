import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/sale_item.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/inventory_log.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/inventory_log_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final List<_CartEntry> _cart = [];
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartSheet(context),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.fold(0, (s, e) => s + e.quantity)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/product_catalog'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final inCart = _cart.where((e) => e.productId == product.productId).isNotEmpty;
              return _ProductCard(
                product: product,
                onAdd: () => _addToCart(product),
                inCart: inCart,
              );
            },
          );
        },
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ₱${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showCartSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('View Cart (${_cart.fold(0, (s, e) => s + e.quantity)})'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _addToCart(Product product) {
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.productName} is out of stock')),
      );
      return;
    }

    setState(() {
      final existing = _cart.where((e) => e.productId == product.productId).firstOrNull;
      if (existing != null) {
        if (existing.quantity < product.stockQuantity) {
          existing.quantity++;
          existing.subtotal = existing.price * existing.quantity;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Max stock reached for ${product.productName}')),
          );
          return;
        }
      } else {
        _cart.add(_CartEntry(
          productId: product.productId!,
          productName: product.productName,
          price: product.price,
          quantity: 1,
          subtotal: product.price,
          stockQuantity: product.stockQuantity,
        ));
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((e) => e.productId == productId);
      _calculateTotal();
    });
  }

  void _updateQuantity(String productId, int delta) {
    setState(() {
      final entry = _cart.where((e) => e.productId == productId).firstOrNull;
      if (entry == null) return;
      final newQty = entry.quantity + delta;
      if (newQty <= 0) {
        _cart.removeWhere((e) => e.productId == productId);
      } else if (newQty > entry.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only ${entry.stockQuantity} available in stock')),
        );
        return;
      } else {
        entry.quantity = newQty;
        entry.subtotal = entry.price * entry.quantity;
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _total = _cart.fold(0.0, (sum, e) => sum + e.subtotal);
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CartSheet(
          cart: _cart,
          total: _total,
          scrollController: scrollController,
          onRemove: _removeFromCart,
          onUpdateQty: _updateQuantity,
          onCheckout: _checkout,
        ),
      ),
    );
  }

  void _checkout() async {
    Navigator.pop(context); // close cart sheet

    final uid = Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to complete purchase')),
      );
      return;
    }

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final saleItemProvider = Provider.of<SaleItemProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final inventoryLogProvider = Provider.of<InventoryLogProvider>(context, listen: false);

    final sale = Sales(
      saleId: null,
      ownerUid: uid,
      date: DateTime.now().toIso8601String().split('T')[0],
      totalAmount: _total,
      paymentStatus: 'Paid',
      paymentMethod: 'Cash',
      paymentDate: DateTime.now().toIso8601String(),
    );

    final saleId = await DatabaseService().insertSales(sale);

    for (final item in _cart) {
      final saleItem = SaleItem(
        salesItemId: null,
        saleId: saleId,
        productId: item.productId,
        quantity: item.quantity,
        price: item.price,
        subtotal: item.subtotal,
      );
      await DatabaseService().insertSaleItem(saleItem);

      final product = productProvider.products.firstWhere(
        (p) => p.productId == item.productId,
        orElse: () => Product(
          productId: null, productName: '', description: '', price: 0, stockQuantity: 0, category: '',
        ),
      );
      final updatedProduct = Product(
        productId: product.productId,
        productName: product.productName,
        description: product.description,
        price: product.price,
        stockQuantity: product.stockQuantity - item.quantity,
        category: product.category,
      );
      await DatabaseService().updateProduct(updatedProduct);

      final log = InventoryLog(
        logId: null,
        productId: item.productId,
        quantityChange: -item.quantity,
        date: DateTime.now().toIso8601String().split('T')[0],
        reason: 'Sale',
      );
      await DatabaseService().insertInventoryLog(log);
    }

    setState(() {
      _cart.clear();
      _total = 0.0;
    });

    await Future.wait([
      salesProvider.loadSales(),
      saleItemProvider.loadSaleItems(),
      productProvider.loadProducts(),
      inventoryLogProvider.loadInventoryLogs(),
    ]);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully!')),
    );
  }
}

class _CartEntry {
  String productId;
  String productName;
  double price;
  int quantity;
  double subtotal;
  int stockQuantity;

  _CartEntry({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.stockQuantity,
  });
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final bool inCart;

  const _ProductCard({
    required this.product,
    required this.onAdd,
    required this.inCart,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stockQuantity <= 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: outOfStock ? null : onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    _iconForCategory(product.category),
                    size: 48,
                    color: outOfStock ? Colors.grey : AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.productName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₱${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: outOfStock ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      outOfStock ? 'Out of stock' : 'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 10,
                        color: outOfStock ? Colors.red : Colors.green.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (inCart)
                    const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: outOfStock ? null : onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: outOfStock ? Colors.grey : AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: Text(outOfStock ? 'Unavailable' : 'Add to Cart', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'medicine':
        return Icons.medical_services;
      case 'accessories':
        return Icons.pets;
      case 'grooming':
        return Icons.content_cut;
      case 'supplies':
        return Icons.inventory_2;
      case 'toys':
        return Icons.toys;
      default:
        return Icons.shopping_bag;
    }
  }
}

class _CartSheet extends StatelessWidget {
  final List<_CartEntry> cart;
  final double total;
  final ScrollController scrollController;
  final void Function(String productId) onRemove;
  final void Function(String productId, int delta) onUpdateQty;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.total,
    required this.scrollController,
    required this.onRemove,
    required this.onUpdateQty,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your Cart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text('₱${item.price.toStringAsFixed(2)} x ${item.quantity} = ₱${item.subtotal.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => onUpdateQty(item.productId, -1),
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onUpdateQty(item.productId, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => onRemove(item.productId),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Place Order', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
