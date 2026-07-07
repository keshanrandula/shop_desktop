import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:file_picker/file_picker.dart';
import '../services/app_state.dart';
import '../models/product_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/restock_dialog.dart';
import '../utils/theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductDialog(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(product: product),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, Product product) {
    if (product.id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final success = await appState.deleteProduct(product.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Product deleted successfully.'
                          : 'Failed to delete product. Check connection.',
                    ),
                    backgroundColor: AppTheme.surfaceSecondary,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Filter products locally for inventory screen based on local search
    final filteredList = appState.products.where((p) {
      final query = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track products, adjust pricing, and restock items.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                CustomButton(
                  text: 'ADD NEW PRODUCT',
                  icon: Icons.add_rounded,
                  type: ButtonType.primary,
                  onPressed: () => _showProductDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search inventory bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search products by SKU, name, or category...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Inventory Table View
            Expanded(
              child: Card(
                child: appState.isLoadingProducts
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? const Center(
                            child: Text(
                              'No items found in stock.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      cardColor: AppTheme.surface,
                                      dividerColor: AppTheme.border,
                                    ),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSecondary),
                                      dataRowColor: WidgetStateProperty.all(AppTheme.surface),
                                      columnSpacing: 40.0,
                                      horizontalMargin: 16.0,
                                      border: const TableBorder(
                                        horizontalInside: BorderSide(color: AppTheme.border, width: 1.0),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Current Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: filteredList.map((product) {
                                        final isLowStock = product.stock <= 5;
                                        final isOutOfStock = product.stock <= 0;
                                        
                                        // Retrieve supplier name safely
                                        final supplierIndex = appState.suppliers.indexWhere((s) => s.id == product.supplierId);
                                        final supplierName = supplierIndex != -1 ? appState.suppliers[supplierIndex].name : 'Unassigned';

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(product.sku, style: const TextStyle(fontWeight: FontWeight.w600))),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: AppTheme.border),
                                                      color: AppTheme.surfaceSecondary,
                                                    ),
                                                    child: product.imagePath != null && product.imagePath!.isNotEmpty
                                                        ? ClipRRect(
                                                            borderRadius: BorderRadius.circular(6),
                                                            child: Image.file(
                                                              File(product.imagePath!),
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_rounded, size: 16, color: AppTheme.textSecondary),
                                                            ),
                                                          )
                                                        : const Icon(Icons.image_rounded, size: 16, color: AppTheme.textSecondary),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                            DataCell(Text(product.category)),
                                            DataCell(Text(supplierName, style: TextStyle(color: product.supplierId == null ? AppTheme.textSecondary.withOpacity(0.5) : AppTheme.textPrimary))),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${product.stock}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: isLowStock
                                                          ? (isOutOfStock ? AppTheme.danger : AppTheme.warning)
                                                          : AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  if (isLowStock) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      Icons.warning_rounded,
                                                      size: 14,
                                                      color: isOutOfStock ? AppTheme.danger : AppTheme.warning,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            DataCell(Text(
                                              currencyFormat.format(product.price),
                                              style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
                                            )),
                                            DataCell(
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryLight),
                                                    onPressed: () => _showProductDialog(context, product: product),
                                                    tooltip: 'Edit details',
                                                  ),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_rounded, size: 18, color: AppTheme.danger),
                                                    onPressed: () => _confirmDelete(context, appState, product),
                                                    tooltip: 'Delete item',
                                                  ),
                                                  if (product.supplierId != null) ...[
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18, color: AppTheme.warning),
                                                      onPressed: () {
                                                        final sIdx = appState.suppliers.indexWhere((s) => s.id == product.supplierId);
                                                        if (sIdx != -1) {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => RestockDialog(
                                                              supplier: appState.suppliers[sIdx],
                                                              products: [product],
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      tooltip: 'Draft Restock Order',
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  final Product? product;

  const _ProductFormDialog({Key? key, this.product}) : super(key: key);

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _sku;
  late String _name;
  late String _category;
  late double _price;
  late double _costPrice;
  late int _stock;
  ObjectId? _supplierId;
  String? _imagePath;
  File? _pickedImageFile;
  bool _imageCleared = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _sku = p?.sku ?? '';
    _name = p?.name ?? '';
    _category = p?.category ?? 'General';
    _price = p?.price ?? 0.0;
    _costPrice = p?.costPrice ?? 0.0;
    _stock = p?.stock ?? 0;
    _supplierId = p?.supplierId;
    _imagePath = p?.imagePath;
  }

  void _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedImageFile = File(result.files.single.path!);
        _imageCleared = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImageFile = null;
      _imagePath = null;
      _imageCleared = true;
    });
  }

  void _save(AppState appState) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    // Save image locally if picked
    if (_pickedImageFile != null) {
      try {
        final dir = Directory('uploads');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final ext = _pickedImageFile!.path.split('.').last;
        final cleanSku = _sku.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final targetPath = 'uploads/${cleanSku}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = await _pickedImageFile!.copy(targetPath);
        _imagePath = savedFile.path;
      } catch (e) {
        // Fallback or log error
      }
    }

    bool success;
    if (widget.product != null) {
      final updated = widget.product!.copyWith(
        sku: _sku,
        name: _name,
        category: _category,
        price: _price,
        costPrice: _costPrice,
        stock: _stock,
        supplierId: _supplierId,
        imagePath: _imagePath,
        clearImage: _imageCleared,
      );
      success = await appState.updateProduct(updated);
    } else {
      final newProduct = Product(
        sku: _sku,
        name: _name,
        category: _category,
        price: _price,
        costPrice: _costPrice,
        stock: _stock,
        supplierId: _supplierId,
        imagePath: _imagePath,
      );
      success = await appState.addProduct(newProduct);
    }

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null
                  ? 'Product updated successfully.'
                  : 'Product added successfully.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation failed. Please verify database connection.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isEditing = widget.product != null;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header title
                Text(
                  isEditing ? 'Edit Product Details' : 'Add New Inventory Product',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const Divider(color: AppTheme.border, height: 32),

                // Image Upload Preview Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: _pickedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_pickedImageFile!, fit: BoxFit.cover),
                            )
                          : (_imagePath != null && _imagePath!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                )
                              : const Icon(Icons.image_rounded, size: 36, color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                              label: const Text('Browse...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            if (_pickedImageFile != null || (_imagePath != null && _imagePath!.isNotEmpty)) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side: const BorderSide(color: AppTheme.danger),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: _clearImage,
                                icon: const Icon(Icons.delete_rounded, size: 16),
                                label: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Accepts PNG, JPG, or JPEG. Max size 5MB.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SKU Field
                TextFormField(
                  initialValue: _sku,
                  decoration: const InputDecoration(labelText: 'SKU / Barcode', hintText: 'e.g. PROD-100'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'SKU is required' : null,
                  onSaved: (val) => _sku = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Name Field
                TextFormField(
                  initialValue: _name,
                  decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Wireless Headset'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                  onSaved: (val) => _name = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Category Field
                TextFormField(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category', hintText: 'e.g. Accessories'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Category is required' : null,
                  onSaved: (val) => _category = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Dual Column fields: Cost Price & Retail Price
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: isEditing ? _costPrice.toString() : '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cost Price (\$)', hintText: '0.00'),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Cost is required';
                          if (double.tryParse(val) == null) return 'Must be a number';
                          return null;
                        },
                        onSaved: (val) => _costPrice = double.parse(val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: isEditing ? _price.toString() : '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Retail Price (\$)', hintText: '0.00'),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Retail is required';
                          if (double.tryParse(val) == null) return 'Must be a number';
                          return null;
                        },
                        onSaved: (val) => _price = double.parse(val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stock Level Field
                TextFormField(
                  initialValue: isEditing ? _stock.toString() : '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Stock Level', hintText: 'e.g. 50'),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Stock level is required';
                    if (int.tryParse(val) == null) return 'Must be an integer';
                    return null;
                  },
                  onSaved: (val) => _stock = int.parse(val!),
                ),
                const SizedBox(height: 16),

                // Supplier Dropdown Selector
                DropdownButtonFormField<ObjectId?>(
                  value: _supplierId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Supplier',
                    prefixIcon: Icon(Icons.local_shipping_rounded, size: 18),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Supplier Assigned')),
                    ...appState.suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _supplierId = val),
                ),
                const SizedBox(height: 28),

                // Actions row (Cancel / Save)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: isEditing ? 'UPDATE PRODUCT' : 'ADD PRODUCT',
                      isLoading: _isSaving,
                      onPressed: () => _save(appState),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
