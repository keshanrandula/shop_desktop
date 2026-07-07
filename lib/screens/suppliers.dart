import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/supplier_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/restock_dialog.dart';
import '../utils/theme.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Supplier? _selectedSupplier;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSupplierDialog(BuildContext context, {Supplier? supplier}) {
    showDialog(
      context: context,
      builder: (context) => _SupplierFormDialog(supplier: supplier),
    );
  }

  void _confirmDelete(BuildContext context, AppState appState, Supplier supplier) {
    if (supplier.id == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
            SizedBox(width: 12),
            Text('Delete Supplier'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${supplier.name}"? \n\n'
          'Products currently linked to this supplier will remain in inventory but will be unassigned (Supplier: Unassigned). This action cannot be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final success = await appState.deleteSupplier(supplier.id!);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _selectedSupplier = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Supplier deleted successfully.'
                          : 'Failed to delete supplier. Check DB connection.',
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

    // Filter suppliers
    final filteredSuppliers = appState.suppliers.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(query) ||
          s.phone.contains(query) ||
          s.email.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query);
    }).toList();

    // Sync selected supplier in case it was updated in State
    if (_selectedSupplier != null) {
      final index = appState.suppliers.indexWhere((s) => s.id == _selectedSupplier!.id);
      if (index != -1) {
        _selectedSupplier = appState.suppliers[index];
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier Directory',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage supply vendors, contact details, and restock orders.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                CustomButton(
                  text: 'ADD NEW SUPPLIER',
                  icon: Icons.add_rounded,
                  type: ButtonType.primary,
                  onPressed: () => _showSupplierDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Directory / Split Pane Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE: Supplier list & Search
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search suppliers by name or email...',
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
                        const SizedBox(height: 16),
                        Expanded(
                          child: Card(
                            child: appState.isLoadingSuppliers
                                ? const Center(child: CircularProgressIndicator())
                                : filteredSuppliers.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No suppliers found.',
                                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.all(12.0),
                                        itemCount: filteredSuppliers.length,
                                        separatorBuilder: (context, idx) =>
                                            const Divider(color: AppTheme.border, height: 1),
                                        itemBuilder: (context, idx) {
                                          final supplier = filteredSuppliers[idx];
                                          final isSelected = _selectedSupplier?.id == supplier.id;

                                          return ListTile(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            selected: isSelected,
                                            selectedTileColor: AppTheme.surfaceSecondary,
                                            title: Text(
                                              supplier.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                '${supplier.phone}  •  ${supplier.email}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ),
                                            trailing: const Icon(
                                              Icons.chevron_right_rounded,
                                              color: AppTheme.textSecondary,
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _selectedSupplier = supplier;
                                              });
                                            },
                                          );
                                        },
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // RIGHT SIDE: Details, Products, actions
                  Expanded(
                    flex: 4,
                    child: _selectedSupplier == null
                        ? Card(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping_rounded,
                                    size: 64,
                                    color: AppTheme.textSecondary.withOpacity(0.2),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Select a supplier from the list',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'to manage contact info, supplied items, and draft restocks.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _buildSupplierDetails(context, appState, _selectedSupplier!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierDetails(BuildContext context, AppState appState, Supplier supplier) {
    // Filter products supplied by this supplier
    final suppliedProducts = appState.products.where((p) => p.supplierId == supplier.id).toList();
    final lowStockProducts = suppliedProducts.where((p) => p.stock <= 5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Supplier Header & Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supplier ID: ${supplier.id?.oid ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryLight),
                      onPressed: () => _showSupplierDialog(context, supplier: supplier),
                      tooltip: 'Edit profile',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_rounded, color: AppTheme.danger),
                      onPressed: () => _confirmDelete(context, appState, supplier),
                      tooltip: 'Delete supplier',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 16),

            // Vendor details cards
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.phone_rounded, 'Phone Number', supplier.phone),
                  const SizedBox(height: 12),
                  _detailRow(Icons.email_rounded, 'Email Address', supplier.email),
                  const SizedBox(height: 12),
                  _detailRow(Icons.location_on_rounded, 'Physical Address', supplier.address),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Low Stock Warning Banner & Restock Order Trigger
            if (lowStockProducts.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lowStockProducts.length} Item(s) Running Low!',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Draft a collective restock sheet to replenish inventory levels.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                      label: const Text('Restock Low'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => RestockDialog(
                            supplier: supplier,
                            products: lowStockProducts,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'All items supplied by this vendor are fully in stock.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Products list
            const Text(
              'SUPPLIED PRODUCTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: suppliedProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products linked to this supplier yet.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: suppliedProducts.length,
                        separatorBuilder: (context, idx) =>
                            const Divider(color: AppTheme.border, height: 1),
                        itemBuilder: (context, idx) {
                          final product = suppliedProducts[idx];
                          final isLow = product.stock <= 5;
                          final isOutOfStock = product.stock <= 0;

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                            ),
                            subtitle: Text(
                              'SKU: ${product.sku}  •  Category: ${product.category}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isLow
                                    ? (isOutOfStock
                                        ? AppTheme.danger.withOpacity(0.15)
                                        : AppTheme.warning.withOpacity(0.15))
                                    : AppTheme.border,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isLow
                                      ? (isOutOfStock ? AppTheme.danger : AppTheme.warning)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                'Stock: ${product.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isLow
                                      ? (isOutOfStock ? AppTheme.danger : AppTheme.warning)
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryLight),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Dialog form for creating and updating supplier listings
class _SupplierFormDialog extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormDialog({this.supplier});

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;
  late String _email;
  late String _address;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _name = s?.name ?? '';
    _phone = s?.phone ?? '';
    _email = s?.email ?? '';
    _address = s?.address ?? '';
  }

  void _save(AppState appState) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSaving = true;
    });

    bool success;
    if (widget.supplier != null) {
      final updated = widget.supplier!.copyWith(
        name: _name,
        phone: _phone,
        email: _email,
        address: _address,
      );
      success = await appState.updateSupplier(updated);
    } else {
      final newSupplier = Supplier(
        name: _name,
        phone: _phone,
        email: _email,
        address: _address,
      );
      success = await appState.addSupplier(newSupplier);
    }

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.supplier != null
                  ? 'Supplier updated successfully.'
                  : 'Supplier added successfully.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operation failed. Check connection.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final isEditing = widget.supplier != null;

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
                Text(
                  isEditing ? 'Edit Supplier Profile' : 'Add New Supply Vendor',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const Divider(color: AppTheme.border, height: 32),

                // Name field
                TextFormField(
                  initialValue: _name,
                  decoration:
                      const InputDecoration(labelText: 'Supplier Name', hintText: 'e.g. Apex Distributors'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Supplier name is required' : null,
                  onSaved: (val) => _name = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Phone field
                TextFormField(
                  initialValue: _phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', hintText: 'e.g. +94 77 123 4567'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Phone number is required' : null,
                  onSaved: (val) => _phone = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  initialValue: _email,
                  decoration: const InputDecoration(labelText: 'Email Address', hintText: 'e.g. info@apex.com'),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Email is required' : null,
                  onSaved: (val) => _email = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Address field
                TextFormField(
                  initialValue: _address,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Physical Address', alignLabelWithHint: true),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Address is required' : null,
                  onSaved: (val) => _address = val!.trim(),
                ),
                const SizedBox(height: 28),

                // Actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      text: isEditing ? 'UPDATE SUPPLIER' : 'SAVE SUPPLIER',
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
