import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';
import 'package:vetcare_connect/services/storage_service.dart';
import 'package:vetcare_connect/models/inventory_log.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/sale_item.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/models/user.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/inventory_log_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/views/screens/access_denied_screen.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SalesPosScreen extends StatefulWidget {
  const SalesPosScreen({super.key});

  @override
  State<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends State<SalesPosScreen> {
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
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final isCustomer = role?.value == 'customer';

    if (isCustomer) {
      return const AccessDeniedScreen();
    }

    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales POS'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: '/sales_pos'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossCount = constraints.maxWidth > 600 ? 4 : 2;

          return Stack(
            children: [
              GridView.builder(
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
                  final inCart = _cart
                      .where((e) => e.productId == product.productId)
                      .isNotEmpty;
                  return _ProductCard(
                    product: product,
                    onAdd: () => _addToCart(product),
                    inCart: inCart,
                  );
                },
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showCartSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                                'View Cart (${_cart.fold(0, (s, e) => s + e.quantity)})'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
      final existing =
          _cart.where((e) => e.productId == product.productId).firstOrNull;
      if (existing != null) {
        if (existing.quantity < product.stockQuantity) {
          existing.quantity++;
          existing.subtotal = existing.price * existing.quantity;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Max stock reached for ${product.productName}')),
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
          SnackBar(
              content: Text('Only ${entry.stockQuantity} available in stock')),
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

  Future<void> _checkout() async {
    // close cart sheet
    Navigator.pop(context);

    if (_cart.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to complete purchase')),
      );
      return;
    }

    // Re-check stock before writing to Firebase.
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final latestProducts = productProvider.products;

    final List<String> insufficient = [];
    for (final item in _cart) {
      Product? p;
      for (final x in latestProducts) {
        if (x.productId == item.productId) {
          p = x;
          break;
        }
      }
      if (p == null) {
        insufficient.add('Missing product: ${item.productId}');
        continue;
      }
      if (item.quantity > p.stockQuantity) {
        insufficient.add(
            '${p.productName} (requested ${item.quantity}, available ${p.stockQuantity})');
      }
    }

    if (insufficient.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Cannot checkout: stock changed.\n${insufficient.join('\n')}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please review the products below before placing the order:',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ..._cart.map((item) {
                  final lineTotal = item.price * item.quantity;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₱${item.price.toStringAsFixed(2)} x ${item.quantity}',
                                style:
                                    Theme.of(dialogContext).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₱${lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total'),
                    Text(
                      '₱${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final paymentMethod = await _selectPaymentMethod(context);
    if (paymentMethod == null) return;
    if (!context.mounted) return;

    String paymentStatus;
    String orderStatus;
    String paymentReference = '';

    if (paymentMethod == 'Cash / Pay at Clinic') {
      paymentStatus = 'Pending Confirmation';
      orderStatus = 'reserved';
    } else {
      paymentStatus = 'Awaiting Verification';
      orderStatus = 'pending_confirmation';
      final ref = await _askPaymentReference(context);
      if (ref == null) return;
      paymentReference = ref;
    }

    String? paymentProofUrl;

    if (paymentMethod != 'Cash / Pay at Clinic') {
      final PickedFileData? proof = await _askPaymentProof(context);
      if (proof != null) {
        try {
          paymentProofUrl = await StorageService.instance.uploadPickedFile(
            data: proof,
            folder: 'payment_proofs',
            referenceName: 'payment_proof_$uid',
          );
        } catch (e) {
          debugPrint('Payment proof upload failed: $e');
        }
      }
    }

    final now = DateTime.now();
    final orderReference = 'ORD-${now.year}-${_generateOrderSuffix()}';

    if (!context.mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.firebaseUser;
    final firebaseUserProvider =
        Provider.of<FirebaseUserProvider>(context, listen: false);
    final profile = firebaseUserProvider.currentUser;

    final customerName = auth.displayName ?? profile?.name ?? '';
    final customerEmail = currentUser?.email ?? profile?.email ?? '';
    final customerContact = profile?.contactNumber ?? '';
    final customerAddress = profile?.address ?? '';

    final sale = Sales(
      saleId: null,
      ownerUid: uid,
      customerName: customerName,
      customerEmail: customerEmail,
      customerContact: customerContact,
      customerAddress: customerAddress,
      date: now.toIso8601String().split('T')[0],
      totalAmount: _total,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paymentDate: now.toIso8601String(),
      orderStatus: orderStatus,
      orderReference: orderReference,
      paymentReference: paymentReference,
      paymentProofUrl: paymentProofUrl,
    );

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final saleItemProvider =
        Provider.of<SaleItemProvider>(context, listen: false);
    final inventoryLogProvider =
        Provider.of<InventoryLogProvider>(context, listen: false);

    try {
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

        final product = latestProducts.firstWhere(
          (p) => p.productId == item.productId,
          orElse: () => Product(
            productId: null,
            productName: '',
            description: '',
            price: 0,
            stockQuantity: 0,
            category: '',
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
          date: now.toIso8601String().split('T')[0],
          reason: 'Sale',
        );
        await DatabaseService().insertInventoryLog(log);
      }

      try {
        await _notifyStaffAboutOrder(saleId, orderReference, uid);
      } catch (_) {
        // Notification failure should not block checkout
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

      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Order placed successfully'),
            content: Text('Order $orderReference placed at $timestamp.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Done'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Place another order'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushNamed('/product_history');
                },
                child: const Text('View products history'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      final errorText = e.toString().toLowerCase();
      final isNetwork = errorText.contains('network') ||
          errorText.contains('timeout') ||
          errorText.contains('unavailable') ||
          errorText.contains('socket');
      final isPermission = errorText.contains('permission') ||
          errorText.contains('denied') ||
          errorText.contains('unauthorized');
      final isFormat = errorText.contains('format') ||
          errorText.contains('invalid') ||
          errorText.contains('argumenterror');

      final userMessage = isPermission
          ? 'We couldn\'t complete the sale due to your account access. Your cart was not saved.'
          : isFormat
              ? 'Something about the item details looks incorrect. Please review quantities and try again. Your cart was not saved.'
              : isNetwork
                  ? 'A network issue happened while saving. Please check your internet connection and try again. Your cart was not saved.'
                  : 'We couldn\'t complete the checkout right now. Please try again. Your cart was not saved.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.red,
        ),
      );

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('We\'re on it'),
            content: const Text(
              'Don\'t worry—no changes were saved.\n\nIf the problem continues, please wait a moment and try again. If you keep seeing this message, contact support.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<String?> _selectPaymentMethod(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Cash / Pay at Clinic'),
                subtitle: const Text('Pay when you pick up or at the clinic'),
                onTap: () =>
                    Navigator.pop(dialogContext, 'Cash / Pay at Clinic'),
              ),
              ListTile(
                title: const Text('Online Banking'),
                subtitle: const Text('Bank transfer or online banking'),
                onTap: () => Navigator.pop(dialogContext, 'Online Banking'),
              ),
              ListTile(
                title: const Text('GCash'),
                subtitle: const Text('Pay via GCash'),
                onTap: () => Navigator.pop(dialogContext, 'GCash'),
              ),
              ListTile(
                title: const Text('Maya'),
                subtitle: const Text('Pay via Maya'),
                onTap: () => Navigator.pop(dialogContext, 'Maya'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askPaymentReference(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Payment Reference'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g. Transaction ID / Reference Number',
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(50),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a payment reference')),
                  );
                  return;
                }
                if (text.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Reference number is too short')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<PickedFileData?> _askPaymentProof(BuildContext context) async {
    return showDialog<PickedFileData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upload Payment Proof'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Please attach a screenshot or photo of your payment receipt.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final PickedFileData? picked =
                        await PlatformImagePicker.pickImageData();
                    if (picked != null && dialogContext.mounted) {
                      Navigator.pop(dialogContext, picked);
                    }
                  } on PickedFileTooLargeException catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                            content: Text(e.message),
                            backgroundColor: Colors.orange),
                      );
                    }
                  } catch (_) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Could not select an image. Please try again.'),
                            backgroundColor: Colors.orange),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose File'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Skip'),
            ),
          ],
        );
      },
    );
  }

  String _generateOrderSuffix() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _notifyStaffAboutOrder(
      String saleId, String orderReference, String customerUid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'staff']).get();

      for (final doc in snapshot.docs) {
        final notification = AppNotification(
          recipientUserId: doc.id,
          title: 'New Order Received',
          message: 'Order $orderReference has been placed.',
          type: 'order',
          relatedDocumentId: saleId,
        );
        await DatabaseService().insertNotification(notification);
      }
    } catch (e) {
      debugPrint('Notification error: $e');
    }
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
    final imageUrl = product.imageUrl;

    return Card(
      elevation: 4,
      shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: outOfStock ? null : onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.08),
                        AppTheme.secondaryTeal.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _ProductImage(
                        imageUrl: imageUrl, outOfStock: outOfStock),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.productName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₱${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: outOfStock
                          ? Colors.red.shade100
                          : AppTheme.secondaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      outOfStock
                          ? 'Out of stock'
                          : 'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 10,
                        color: outOfStock ? Colors.red : AppTheme.secondaryTeal,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (inCart)
                    const Icon(Icons.check_circle,
                        color: AppTheme.primaryGreen, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: outOfStock ? null : onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        outOfStock ? Colors.grey : AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(outOfStock ? 'Unavailable' : 'Add to Cart',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final bool outOfStock;

  const _ProductImage({required this.imageUrl, required this.outOfStock});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.15),
              AppTheme.secondaryTeal.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: outOfStock
              ? Colors.grey
              : AppTheme.primaryGreen.withValues(alpha: 0.6),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return FadeTransition(
          opacity: AlwaysStoppedAnimation(value),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.1),
                      AppTheme.secondaryTeal.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryGreen)),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                      AppTheme.secondaryTeal.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: outOfStock
                      ? Colors.grey
                      : AppTheme.primaryGreen.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      },
    );
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    subtitle: Text(
                      '₱${item.price.toStringAsFixed(2)} x ${item.quantity} = ₱${item.subtotal.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => onUpdateQty(item.productId, -1),
                        ),
                        Text('${item.quantity}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onUpdateQty(item.productId, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
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
                      child: const Text('Place Order',
                          style: TextStyle(fontSize: 16)),
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final e in this) {
      return e;
    }
    return null;
  }
}
