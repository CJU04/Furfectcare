import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vetcare_connect/services/storage_service.dart';
import 'package:vetcare_connect/utils/platform_image_picker.dart';
import 'package:vetcare_connect/models/inventory_log.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/inventory_log_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';

class ProductInventoryScreen extends StatefulWidget {
  const ProductInventoryScreen({super.key});

  @override
  State<ProductInventoryScreen> createState() => _ProductInventoryScreenState();
}

class _ProductInventoryScreenState extends State<ProductInventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Name (A-Z)';

  static const _sortOptions = <String>[
    'Name (A-Z)',
    'Name (Z-A)',
    'Price (low first)',
    'Price (high first)',
    'Stock (low first)',
    'Stock (high first)',
  ];
  String _selectedCategory = 'All';
  PickedFileData? productImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    Provider.of<ProductProvider>(context, listen: false)
        .loadProducts()
        .whenComplete(() {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final isCustomer = role?.value == 'customer';

    List<Product> products = productProvider.products;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      products = products
          .where((product) =>
              product.productName.toLowerCase().contains(q) ||
              product.description.toLowerCase().contains(q) ||
              product.category.toLowerCase().contains(q) ||
              (product.productCode ?? '').toLowerCase().contains(q))
          .toList();
    }
    if (_selectedCategory != 'All') {
      products = products
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Copy before sorting so the provider's internal list is never mutated.
    products = List<Product>.from(products);
    switch (_sortBy) {
      case 'Name (Z-A)':
        products.sort((a, b) =>
            b.productName.toLowerCase().compareTo(a.productName.toLowerCase()));
        break;
      case 'Price (low first)':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price (high first)':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Stock (low first)':
        products.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'Stock (high first)':
        products.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      default:
        products.sort((a, b) =>
            a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inventory'),
      ),
      drawer: const AppDrawer(currentRoute: '/product_inventory'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600 ? 800 : double.infinity;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search Products',
                            hintText: 'Name, description, code or category',
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
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(
                              value: 'Medicine', child: Text('Medicine')),
                          DropdownMenuItem(
                              value: 'Accessories', child: Text('Accessories')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
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
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : products.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 64, color: Colors.green.shade300),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No products found',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isEmpty &&
                                            _selectedCategory == 'All'
                                        ? 'Products will appear here once they are added to inventory.'
                                        : 'No products match your search or filter. Try adjusting them.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth > 600
                                    ? (constraints.maxWidth - 800) / 2
                                    : 0),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                elevation: 3,
                                shadowColor: AppTheme.primaryGreen
                                    .withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryGreen
                                        .withValues(alpha: 0.1),
                                    backgroundImage: product.imageUrl != null &&
                                            product.imageUrl!.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            product.imageUrl!)
                                        : null,
                                    child: product.imageUrl == null ||
                                            product.imageUrl!.isEmpty
                                        ? Icon(Icons.inventory,
                                            color: AppTheme.primaryGreen)
                                        : null,
                                  ),
                                  title: Text(
                                    product.productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${product.category} - ₱${product.price.toStringAsFixed(2)} - Stock: ${product.stockQuantity}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: isCustomer
                                      ? null
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              onPressed: () =>
                                                  _editProduct(product),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () =>
                                                  _deleteProduct(product),
                                            ),
                                          ],
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
      floatingActionButton: isCustomer
          ? null
          : FloatingActionButton(
              onPressed: _addProduct,
              child: const Icon(Icons.add),
            ),
    );
  }

  void _addProduct() {
    productImage = null; // ensure a stale selection is never carried over
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    String selectedCategory = 'Food';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final picked = await PlatformImagePicker.pickImageData();
                      if (picked != null) {
                        setState(() {
                          productImage = picked;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Image selected: ${PlatformImagePicker.describeSize(picked.size)}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    } on PickedFileTooLargeException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(e.message),
                              backgroundColor: Colors.orange),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not select an image. Please try again.'),
                              backgroundColor: Colors.orange),
                        );
                      }
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.shade50,
                    backgroundImage: productImage?.previewProvider,
                    child: productImage == null
                        ? const Icon(Icons.camera_alt, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Product Name'),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'Food', child: Text('Food')),
                        DropdownMenuItem(
                            value: 'Medicine', child: Text('Medicine')),
                        DropdownMenuItem(
                            value: 'Accessories', child: Text('Accessories')),
                        DropdownMenuItem(
                            value: 'Grooming', child: Text('Grooming')),
                        DropdownMenuItem(
                            value: 'Supplies', child: Text('Supplies')),
                        DropdownMenuItem(value: 'Toys', child: Text('Toys')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: stockController,
                      decoration:
                          const InputDecoration(labelText: 'Stock Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final priceText = priceController.text.trim();
                final stockText = stockController.text.trim();
                final price = double.tryParse(priceText);
                final stock = int.tryParse(stockText);

                if (price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Price must be a valid non-negative number'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                if (stock == null || stock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Stock must be a valid non-negative integer'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                String? imageUrl;
                if (productImage != null) {
                  try {
                    imageUrl = await StorageService.instance.uploadPickedFile(
                      data: productImage!,
                      folder: 'product_images',
                      referenceName:
                          'product_${DateTime.now().millisecondsSinceEpoch}',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Image upload failed. Please check your connection and try again.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }
                }
                final newProduct = Product(
                  productId: null,
                  productCode: '',
                  productName: nameController.text.trim(),
                  category: selectedCategory,
                  description: descriptionController.text.trim(),
                  price: price,
                  stockQuantity: stock,
                  minimumStock: 0,
                  unit: '',
                  imageUrl: imageUrl,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Adding product...'),
                      duration: Duration(seconds: 1)),
                );
                try {
                  await Provider.of<ProductProvider>(context, listen: false)
                      .addProduct(newProduct);
                  if (newProduct.productId != null && stock > 0) {
                    final log = InventoryLog(
                      logId: null,
                      productId: newProduct.productId!,
                      quantityChange: stock,
                      date: DateTime.now().toIso8601String().split('T')[0],
                      reason: 'Added Product',
                    );
                    await DatabaseService().insertInventoryLog(log);
                    Provider.of<InventoryLogProvider>(context, listen: false)
                        .loadInventoryLogs();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Product added successfully'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to add product'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editProduct(Product product) {
    final nameController = TextEditingController(text: product.productName);
    final categoryController = TextEditingController(text: product.category);
    final descriptionController =
        TextEditingController(text: product.description);
    final priceController =
        TextEditingController(text: product.price.toString());
    final stockController =
        TextEditingController(text: product.stockQuantity.toString());
    productImage = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final picked = await PlatformImagePicker.pickImageData();
                      if (picked != null) {
                        setState(() {
                          productImage = picked;
                        });
                      }
                    } on PickedFileTooLargeException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(e.message),
                              backgroundColor: Colors.orange),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not select an image. Please try again.'),
                              backgroundColor: Colors.orange),
                        );
                      }
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.shade50,
                    backgroundImage: productImage?.previewProvider ??
                        (product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(product.imageUrl!)
                            : null),
                    child: productImage == null &&
                            (product.imageUrl == null ||
                                product.imageUrl!.isEmpty)
                        ? const Icon(Icons.camera_alt, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Product Name'),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: stockController,
                      decoration:
                          const InputDecoration(labelText: 'Stock Quantity'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final priceText = priceController.text.trim();
                final stockText = stockController.text.trim();
                final price = double.tryParse(priceText);
                final stock = int.tryParse(stockText);

                if (price == null || price < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Price must be a valid non-negative number'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                if (stock == null || stock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Stock must be a valid non-negative integer'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                String? imageUrl = product.imageUrl;
                if (productImage != null) {
                  try {
                    imageUrl = await StorageService.instance.uploadPickedFile(
                      data: productImage!,
                      folder: 'product_images',
                      referenceName:
                          'product_${DateTime.now().millisecondsSinceEpoch}',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'New image upload failed; keeping the current product image.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                }
                final updatedProduct = Product(
                  productId: product.productId,
                  productCode: product.productCode,
                  productName: nameController.text.trim(),
                  category: categoryController.text.trim(),
                  description: descriptionController.text.trim(),
                  price: price,
                  stockQuantity: stock,
                  minimumStock: product.minimumStock,
                  unit: product.unit,
                  expirationDate: product.expirationDate,
                  imageUrl: imageUrl,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Updating product...'),
                      duration: Duration(seconds: 1)),
                );
                try {
                  final oldStock = product.stockQuantity;
                  final newStock = stock;
                  final stockChange = newStock - oldStock;
                  await Provider.of<ProductProvider>(context, listen: false)
                      .updateProduct(updatedProduct);
                  if (stockChange != 0 && product.productId != null) {
                    final log = InventoryLog(
                      logId: null,
                      productId: product.productId!,
                      quantityChange: stockChange,
                      date: DateTime.now().toIso8601String().split('T')[0],
                      reason: stockChange > 0 ? 'Stock Added' : 'Stock Reduced',
                    );
                    await DatabaseService().insertInventoryLog(log);
                    Provider.of<InventoryLogProvider>(context, listen: false)
                        .loadInventoryLogs();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Product updated successfully'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to update product'),
                          backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content:
            Text('Are you sure you want to delete ${product.productName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Deleting product...'),
                    duration: Duration(seconds: 1)),
              );
              try {
                await Provider.of<ProductProvider>(context, listen: false)
                    .deleteProduct(product.productId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Product deleted successfully'),
                        backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Failed to delete product'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
