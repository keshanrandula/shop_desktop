import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import '../utils/theme.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'accessories':
        return Icons.mouse_rounded;
      case 'apparel':
      case 'clothing':
        return Icons.checkroom_rounded;
      case 'groceries':
      case 'food':
        return Icons.restaurant_rounded;
      default:
        return Icons.shopping_bag_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isOutOfStock = widget.product.stock <= 0;
    final isLowStock = widget.product.stock > 0 && widget.product.stock <= 5;

    Color getStockColor() {
      if (isOutOfStock) return AppTheme.danger;
      if (isLowStock) return AppTheme.warning;
      return AppTheme.success;
    }

    String getStockText() {
      if (isOutOfStock) return 'Out of Stock';
      if (isLowStock) return 'Low Stock: ${widget.product.stock}';
      return '${widget.product.stock} in stock';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primaryLight.withOpacity(0.8)
                  : AppTheme.border,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Simulated Product Image/Icon Box
                Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(_isHovered ? 0.15 : 0.06),
                        AppTheme.secondary.withOpacity(_isHovered ? 0.15 : 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isHovered
                          ? AppTheme.primaryLight.withOpacity(0.2)
                          : AppTheme.border.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                   child: widget.product.imagePath != null && widget.product.imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.product.imagePath!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 110,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  _getCategoryIcon(widget.product.category),
                                  size: 40,
                                  color: _isHovered ? AppTheme.primaryLight : AppTheme.textSecondary,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            _getCategoryIcon(widget.product.category),
                            size: 40,
                            color: _isHovered ? AppTheme.primaryLight : AppTheme.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Category & SKU Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.product.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      widget.product.sku,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Product Name
                Expanded(
                  child: Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Stock Status
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: getStockColor(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      getStockText(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: getStockColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price and Add Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(widget.product.price),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    IconButton(
                      onPressed: isOutOfStock ? null : widget.onAddToCart,
                      icon: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 18,
                        color: isOutOfStock ? AppTheme.textMuted : AppTheme.textPrimary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isOutOfStock
                            ? AppTheme.border
                            : AppTheme.primary,
                        foregroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
