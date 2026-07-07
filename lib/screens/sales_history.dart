import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/sale_model.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPaymentMethod = 'All';
  String _selectedStatus = 'All';
  String _dateFilter = 'All Time'; // All Time, Today, Last 7 Days

  Sale? _selectedSale;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Check if a sale matches all active filters
  bool _matchesFilters(Sale sale) {
    // 1. Search Query (matches Sale ID or Product SKU/Name inside the sale)
    final query = _searchQuery.toLowerCase();
    bool matchesSearch = false;
    if (query.isEmpty) {
      matchesSearch = true;
    } else {
      final saleIdStr = sale.id?.oid ?? '';
      if (saleIdStr.toLowerCase().contains(query)) {
        matchesSearch = true;
      } else {
        for (var item in sale.items) {
          if (item.product.name.toLowerCase().contains(query) ||
              item.product.sku.toLowerCase().contains(query)) {
            matchesSearch = true;
            break;
          }
        }
      }
    }

    // 2. Payment Method Filter
    final matchesPayment = _selectedPaymentMethod == 'All' ||
        sale.paymentMethod.toLowerCase() == _selectedPaymentMethod.toLowerCase();

    // 3. Status Filter
    final matchesStatus = _selectedStatus == 'All' ||
        sale.status.toLowerCase() == _selectedStatus.toLowerCase();

    // 4. Date Filter
    bool matchesDate = true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_dateFilter == 'Today') {
      final saleDate = DateTime(sale.dateTime.year, sale.dateTime.month, sale.dateTime.day);
      matchesDate = saleDate.isAtSameMomentAs(today);
    } else if (_dateFilter == 'Last 7 Days') {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      matchesDate = sale.dateTime.isAfter(sevenDaysAgo);
    }

    return matchesSearch && matchesPayment && matchesStatus && matchesDate;
  }

  void _confirmRefund(BuildContext context, AppState appState, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
            SizedBox(width: 12),
            Text('Confirm Refund'),
          ],
        ),
        content: const Text(
          'Are you sure you want to refund this transaction? \n\n'
          'This will return all items back into the inventory stock and mark this sale as Refunded. This action cannot be undone.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final success = await appState.refundSale(sale);
              if (context.mounted) {
                // Keep the updated instance selected
                final updatedSale = appState.sales.firstWhere(
                  (s) => s.id == sale.id,
                  orElse: () => sale,
                );
                setState(() {
                  _selectedSale = updatedSale;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                          color: success ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          success
                              ? 'Transaction refunded successfully. Stock levels restored.'
                              : 'Failed to process refund. Check DB connection.',
                        ),
                      ],
                    ),
                    backgroundColor: AppTheme.surfaceSecondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Refund Transaction'),
          ),
        ],
      ),
    );
  }

  void _showPrintDialog(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (context) => _ThermalReceiptDialog(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Filter sales list based on user selections
    final filteredSales = appState.sales.where(_matchesFilters).toList();

    // Sync selected sale if it exists in the updated state (e.g., status changed to refunded)
    if (_selectedSale != null) {
      final index = appState.sales.indexWhere((s) => s.id == _selectedSale!.id);
      if (index != -1) {
        _selectedSale = appState.sales[index];
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales & Transactions',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View transaction history, print receipts, and manage sales refunds.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters Bar
            Row(
              children: [
                // Search bar
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by Sale ID or Product SKU/Name...',
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
                ),
                const SizedBox(width: 16),

                // Payment Method Filter Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Payments')),
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                    ],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val ?? 'All'),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                      DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'Refunded', child: Text('Refunded')),
                    ],
                    onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
                  ),
                ),
                const SizedBox(width: 16),

                // Date Filter Chips
                Row(
                  children: ['All Time', 'Today', 'Last 7 Days'].map((filter) {
                    final isSelected = _dateFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _dateFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Split View Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE: Table/List of Sales
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: appState.isLoadingSales
                          ? const Center(child: CircularProgressIndicator())
                          : filteredSales.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No matching transactions found.',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12.0),
                                  itemCount: filteredSales.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(color: AppTheme.border, height: 1),
                                  itemBuilder: (context, index) {
                                    final sale = filteredSales[index];
                                    final isSelected = _selectedSale?.id == sale.id;
                                    final isRefunded = sale.status == 'Refunded';

                                    // Truncate ObjectId to 8 characters for screen display
                                    final displayId = sale.id != null
                                        ? '#${sale.id!.oid.substring(16)}'
                                        : '#N/A';

                                    return ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      selected: isSelected,
                                      selectedTileColor: AppTheme.surfaceSecondary,
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            displayId,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            currencyFormat.format(sale.total),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isRefunded
                                                  ? AppTheme.danger
                                                  : AppTheme.primaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${dateFormat.format(sale.dateTime)} • ${sale.items.length} item(s)',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            // Badges
                                            Row(
                                              children: [
                                                // Payment Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.border,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    sale.paymentMethod,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Status Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isRefunded
                                                        ? AppTheme.danger.withOpacity(0.15)
                                                        : AppTheme.success.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: isRefunded
                                                          ? AppTheme.danger.withOpacity(0.5)
                                                          : AppTheme.success.withOpacity(0.5),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    sale.status.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isRefunded
                                                          ? AppTheme.danger
                                                          : AppTheme.success,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          _selectedSale = sale;
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // RIGHT SIDE: Details View / Digital Receipt
                  Expanded(
                    flex: 4,
                    child: _selectedSale == null
                        ? Card(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    size: 64,
                                    color: AppTheme.textSecondary.withOpacity(0.2),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Select a transaction from the list',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'to view detailed invoices, reprint receipts, or process returns.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Detail Title + Status Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Transaction Details',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          SelectableText(
                                            'ID: ${_selectedSale!.id?.oid ?? "N/A"}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _selectedSale!.status == 'Refunded'
                                              ? AppTheme.danger.withOpacity(0.15)
                                              : AppTheme.success.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _selectedSale!.status == 'Refunded'
                                                ? AppTheme.danger
                                                : AppTheme.success,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          _selectedSale!.status.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: _selectedSale!.status == 'Refunded'
                                                ? AppTheme.danger
                                                : AppTheme.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: AppTheme.border, height: 1),
                                  const SizedBox(height: 16),

                                  // Sale Metadata Info
                                  Row(
                                    children: [
                                      _infoTile('DATE & TIME',
                                          dateFormat.format(_selectedSale!.dateTime)),
                                      const SizedBox(width: 24),
                                      _infoTile('PAYMENT METHOD',
                                          _selectedSale!.paymentMethod.toUpperCase()),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Invoice Items Title
                                  const Text(
                                    'ITEMS PURCHASED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Invoice Items Table List
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceSecondary.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.border),
                                      ),
                                      child: ListView.separated(
                                        padding: const EdgeInsets.all(12.0),
                                        itemCount: _selectedSale!.items.length,
                                        separatorBuilder: (context, idx) =>
                                            const Divider(color: AppTheme.border, height: 1),
                                        itemBuilder: (context, idx) {
                                          final item = _selectedSale!.items[idx];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.product.name,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            color: AppTheme.textPrimary),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'SKU: ${item.product.sku}  •  ${currencyFormat.format(item.product.price)} each',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: AppTheme.textSecondary),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  'x ${item.quantity}',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: AppTheme.textSecondary),
                                                ),
                                                const SizedBox(width: 24),
                                                Text(
                                                  currencyFormat.format(item.total),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.textPrimary),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Billing Summary Section
                                  Container(
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceSecondary,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Column(
                                      children: [
                                        _summaryRow(
                                            'Subtotal',
                                            currencyFormat.format(_selectedSale!.subTotal),
                                            false),
                                        const SizedBox(height: 8),
                                        _summaryRow(
                                            'Discount',
                                            '-${currencyFormat.format(_selectedSale!.discount)}',
                                            false,
                                            textColor: AppTheme.tertiary),
                                        const SizedBox(height: 12),
                                        const Divider(color: AppTheme.border, height: 1),
                                        const SizedBox(height: 12),
                                        _summaryRow(
                                            'Grand Total',
                                            currencyFormat.format(_selectedSale!.total),
                                            true,
                                            textColor: AppTheme.primaryLight),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Actions row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: 'REPRINT INVOICE',
                                          icon: Icons.print_rounded,
                                          type: ButtonType.outlined,
                                          onPressed: () =>
                                              _showPrintDialog(context, _selectedSale!),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: CustomButton(
                                          text: _selectedSale!.status == 'Refunded'
                                              ? 'REFUNDED'
                                              : 'REFUND TRANSACTION',
                                          icon: Icons.keyboard_return_rounded,
                                          type: ButtonType.danger,
                                          onPressed: _selectedSale!.status == 'Refunded'
                                              ? null
                                              : () => _confirmRefund(
                                                  context, appState, _selectedSale!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, bool isBold, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 18 : 14,
            color: textColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// Custom Dialog to represent retro thermal-receipt printing simulation
class _ThermalReceiptDialog extends StatefulWidget {
  final Sale sale;
  const _ThermalReceiptDialog({required this.sale});

  @override
  State<_ThermalReceiptDialog> createState() => _ThermalReceiptDialogState();
}

class _ThermalReceiptDialogState extends State<_ThermalReceiptDialog> {
  bool _isPrinting = false;
  double _printProgress = 0.0;

  void _simulatePrint() async {
    setState(() {
      _isPrinting = true;
      _printProgress = 0.0;
    });

    // Simulate sending print instructions to standard serial terminal printer
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _printProgress = i / 10;
        });
      }
    }

    if (mounted) {
      Navigator.pop(context); // Close print preview dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.success),
              SizedBox(width: 12),
              Text('Receipt sent to printer successfully!'),
            ],
          ),
          backgroundColor: AppTheme.surfaceSecondary,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final truncatedId = widget.sale.id != null
        ? widget.sale.id!.oid.substring(12).toUpperCase()
        : 'N/A';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: const Color(0xFF1E294B), // Surface slate
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Receipt Print Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _isPrinting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),

            // Thermal Paper Mockup Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5), // Off-white/creamy paper texture
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.black87,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Center(
                        child: Text(
                          '*** RECEIPT ***',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'SHOP POS & INVENTORY',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const Center(
                        child: Text(
                          '123 Tech Avenue, Colombo',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Tel: +94 11 2345678',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('------------------------------------------'),
                      Text('Receipt ID : TXN-$truncatedId'),
                      Text('Date       : ${dateFormat.format(widget.sale.dateTime)}'),
                      Text('Cashier    : admin (${widget.sale.status})'),
                      const Text('------------------------------------------'),
                      
                      // Table Header
                      const Row(
                        children: [
                          Expanded(flex: 3, child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('QTY', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const Text('- - - - - - - - - - - - - - - - - - - - - '),

                      // Items list
                      Column(
                        children: widget.sale.items.map((item) {
                          // Clean name for small paper print width
                          String displayName = item.product.name;
                          if (displayName.length > 15) {
                            displayName = '${displayName.substring(0, 12)}...';
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Expanded(flex: 3, child: Text(displayName)),
                                Expanded(child: Text('${item.quantity}', textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text(currencyFormat.format(item.product.price), textAlign: TextAlign.right)),
                                Expanded(flex: 2, child: Text(currencyFormat.format(item.total), textAlign: TextAlign.right)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const Text('------------------------------------------'),

                      // Financial Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text(currencyFormat.format(widget.sale.subTotal)),
                        ],
                      ),
                      if (widget.sale.discount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:'),
                            Text('-${currencyFormat.format(widget.sale.discount)}'),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(currencyFormat.format(widget.sale.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Type:'),
                          Text(widget.sale.paymentMethod.toUpperCase()),
                        ],
                      ),
                      const Text('------------------------------------------'),
                      const SizedBox(height: 8),

                      // Barcode simulation
                      Center(
                        child: Column(
                          children: [
                            Container(
                              height: 32,
                              width: 180,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.black, width: 1),
                                  bottom: BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(24, (index) {
                                  // Random black bars simulation
                                  final isBlack = index % 3 == 0 || index % 5 == 1 || index == 2 || index == 21;
                                  final width = (index % 3 == 0) ? 4.0 : 1.5;
                                  return Container(
                                    width: isBlack ? width : 2,
                                    color: isBlack ? Colors.black : Colors.transparent,
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '*TXN-$truncatedId*',
                              style: const TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'THANK YOU FOR YOUR VISIT!',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Dialog buttons
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 18),
              child: _isPrinting
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Printing in progress...',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: _printProgress,
                          color: AppTheme.primaryLight,
                          backgroundColor: AppTheme.border,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Print'),
                            onPressed: _simulatePrint,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
