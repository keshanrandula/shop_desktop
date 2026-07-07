import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/cart_item_model.dart';
import '../widgets/product_card.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class BillingPosScreen extends StatefulWidget {
  const BillingPosScreen({Key? key}) : super(key: key);

  @override
  State<BillingPosScreen> createState() => _BillingPosScreenState();
}

class _BillingPosScreenState extends State<BillingPosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _searchController.text = appState.posSearchQuery;
    _discountController.text = appState.posDiscount > 0 ? appState.posDiscount.toString() : '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _handleCheckout(AppState appState) async {
    if (appState.cart.isEmpty) return;

    setState(() => _isCheckingOut = true);
    
    final success = await appState.checkout();
    
    setState(() => _isCheckingOut = false);

    if (mounted) {
      if (success) {
        _discountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.success),
                SizedBox(width: 12),
                Text('Transaction completed successfully! Stock levels updated.',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: AppTheme.surfaceSecondary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: AppTheme.danger),
                SizedBox(width: 12),
                Text('Checkout failed. Please check your database connection.'),
              ],
            ),
            backgroundColor: AppTheme.surfaceSecondary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // LEFT PANEL: Product Grid & Search
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header & Search Bar
                  Row(
                    children: [
                      const Text(
                        'Billing Terminal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => appState.setPosSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search products by name or SKU...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      appState.setPosSearchQuery('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Categories Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: appState.categories.map((category) {
                        final isSelected = appState.posSelectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                appState.setPosCategory(category);
                              }
                            },
                            selectedColor: AppTheme.primary,
                            backgroundColor: AppTheme.surface,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : AppTheme.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Product Grid
                  Expanded(
                    child: appState.products.isEmpty && appState.isLoadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : appState.filteredProducts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? 'No products matching search.'
                                          : 'No products in catalog. Add some in Inventory!',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  // Determine appropriate column count based on width
                                  int crossAxisCount = 3;
                                  if (constraints.maxWidth < 600) {
                                    crossAxisCount = 1;
                                  } else if (constraints.maxWidth < 900) {
                                    crossAxisCount = 2;
                                  } else if (constraints.maxWidth < 1200) {
                                    crossAxisCount = 3;
                                  } else {
                                    crossAxisCount = 4;
                                  }

                                  return GridView.builder(
                                    itemCount: appState.filteredProducts.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                    ),
                                    itemBuilder: (context, index) {
                                      final product = appState.filteredProducts[index];
                                      return ProductCard(
                                        product: product,
                                        onAddToCart: () => appState.addToCart(product),
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT PANEL: POS Checkout Cart
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  left: BorderSide(color: AppTheme.border, width: 1),
                ),
              ),
            child: Column(
              children: [
                // Cart Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryLight),
                          SizedBox(width: 10),
                          Text(
                            'Active Bill',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (appState.cart.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            appState.clearCart();
                            _discountController.clear();
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppTheme.danger),
                          label: const Text('Clear', style: TextStyle(color: AppTheme.danger, fontSize: 13)),
                          style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero),
                        ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.border, height: 1),

                // Cart List
                Expanded(
                  child: appState.cart.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'Shopping cart is empty',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: appState.cart.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = appState.cart[index];
                            return _CartItemRow(
                              item: item,
                              onAdd: () => appState.addToCart(item.product),
                              onMinus: () => appState.decrementCartItem(item),
                              onRemove: () => appState.removeCartItem(item),
                            );
                          },
                        ),
                ),
                const Divider(color: AppTheme.border, height: 1),

                // Summary Section
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: AppTheme.textSecondary)),
                          Text(
                            currencyFormat.format(appState.cartSubtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Discount Input Field
                      Row(
                        children: [
                          const Text('Discount (\$)', style: TextStyle(color: AppTheme.textSecondary)),
                          const Spacer(),
                          SizedBox(
                            width: 100,
                            height: 38,
                            child: TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final d = double.tryParse(val) ?? 0.0;
                                appState.setDiscount(d);
                              },
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                hintText: '0.00',
                                fillColor: AppTheme.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Payment Method Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment', style: TextStyle(color: AppTheme.textSecondary)),
                          DropdownButton<String>(
                            value: appState.posSelectedPaymentMethod,
                            dropdownColor: AppTheme.surface,
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                            onChanged: (val) {
                              if (val != null) {
                                appState.setPaymentMethod(val);
                              }
                            },
                            items: ['Cash', 'Card', 'Mobile Pay']
                                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.border, height: 24),

                      // Total Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          Text(
                            currencyFormat.format(appState.cartTotal),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Place Order / Checkout Button
                      CustomButton(
                        text: 'PROCEED TO CHECKOUT',
                        icon: Icons.check_rounded,
                        width: double.infinity,
                        height: 52,
                        isLoading: _isCheckingOut,
                        type: ButtonType.success,
                        onPressed: appState.cart.isEmpty
                            ? null
                            : () => _handleCheckout(appState),
                      ),
                    ],
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

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onMinus;
  final VoidCallback onRemove;

  const _CartItemRow({
    Key? key,
    required this.item,
    required this.onAdd,
    required this.onMinus,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${item.product.sku} • ${currencyFormat.format(item.product.price)} each',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Controls & Total column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price Total
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currencyFormat.format(item.total),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.cancel_rounded, size: 16, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Plus / Minus Quantity Adjuster
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onMinus,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.remove, size: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, size: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
