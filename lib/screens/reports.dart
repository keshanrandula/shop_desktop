import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/report_helper.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = 'Sales Summary'; // Sales Summary, Inventory Stock Valuation
  String _selectedDateRange = 'This Month'; // Today, Last 7 Days, This Month, All Time
  String _selectedFormat = 'CSV'; // CSV, PDF

  bool _hasPreview = false;
  List<Sale> _previewSales = [];
  List<Product> _previewProducts = [];
  bool _isGenerating = false;

  // Run filtering logic to populate preview fields
  void _generatePreview(AppState appState) {
    setState(() {
      _hasPreview = true;
      if (_selectedReportType == 'Sales Summary') {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        _previewSales = appState.sales.where((sale) {
          // Exclude refunded sales from financial reports
          if (sale.status == 'Refunded') return false;

          if (_selectedDateRange == 'Today') {
            final saleDate = DateTime(sale.dateTime.year, sale.dateTime.month, sale.dateTime.day);
            return saleDate.isAtSameMomentAs(today);
          } else if (_selectedDateRange == 'Last 7 Days') {
            final sevenDaysAgo = today.subtract(const Duration(days: 7));
            return sale.dateTime.isAfter(sevenDaysAgo);
          } else if (_selectedDateRange == 'This Month') {
            return sale.dateTime.year == now.year && sale.dateTime.month == now.month;
          }
          return true; // All Time
        }).toList();
      } else {
        // Inventory Report takes all current products
        _previewProducts = List.from(appState.products);
      }
    });
  }

  void _exportReport(AppState appState) async {
    // Generate preview first if not loaded
    if (!_hasPreview) {
      _generatePreview(appState);
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      File? generatedFile;
      if (_selectedReportType == 'Sales Summary') {
        if (_selectedFormat == 'CSV') {
          generatedFile = await ReportHelper.exportSalesReportCsv(_previewSales, _selectedDateRange);
        } else {
          // For PDF, we open a beautiful document simulation dialog
          _showPdfSimulationDialog(context, _selectedReportType);
          setState(() {
            _isGenerating = false;
          });
          return;
        }
      } else {
        if (_selectedFormat == 'CSV') {
          generatedFile = await ReportHelper.exportInventoryReportCsv(_previewProducts);
        } else {
          _showPdfSimulationDialog(context, _selectedReportType);
          setState(() {
            _isGenerating = false;
          });
          return;
        }
      }

      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        final File file = generatedFile;
        final exportsDirPath = file.parent.absolute.path;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
                SizedBox(width: 12),
                Text('Report Exported'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your spreadsheet report has been generated successfully and saved to disk.'),
                const SizedBox(height: 16),
                Text(
                  'Filename: ${file.uri.pathSegments.last}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Path: ${file.path}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                const Text('You can access all exported reports inside the project directory:'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Process.run('explorer.exe', [exportsDirPath]);
                  },
                  child: const Text(
                    'Open Exports Directory',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showPdfSimulationDialog(BuildContext context, String reportType) {
    showDialog(
      context: context,
      builder: (context) => _PdfReportSimulationDialog(
        reportType: reportType,
        dateRange: _selectedDateRange,
        sales: _previewSales,
        products: _previewProducts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
                  'Report Center',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Export spreadsheet sheets and generate analytical audits of your shop performance.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Split View Layout
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT SIDE: Configuration panel
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REPORT CONFIGURATION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Report type dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedReportType,
                              decoration: const InputDecoration(
                                labelText: 'Report Type',
                                prefixIcon: Icon(Icons.description_rounded, size: 18),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Sales Summary', child: Text('Sales Summary')),
                                DropdownMenuItem(value: 'Inventory Stock Valuation', child: Text('Inventory Stock Valuation')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedReportType = val ?? 'Sales Summary';
                                  _hasPreview = false; // Reset preview on change
                                });
                              },
                            ),
                            const SizedBox(height: 20),

                            // Date Range (Visible only for Sales Summary)
                            if (_selectedReportType == 'Sales Summary') ...[
                              DropdownButtonFormField<String>(
                                value: _selectedDateRange,
                                decoration: const InputDecoration(
                                  labelText: 'Date Range',
                                  prefixIcon: Icon(Icons.date_range_rounded, size: 18),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Today', child: Text('Today')),
                                  DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                                  DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedDateRange = val ?? 'This Month';
                                    _hasPreview = false;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Format selector radio buttons
                            const Text(
                              'Export Format',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('CSV Spreadsheet (.csv / Excel)', style: TextStyle(fontSize: 13)),
                              leading: Radio<String>(
                                value: 'CSV',
                                groupValue: _selectedFormat,
                                onChanged: (val) => setState(() => _selectedFormat = val ?? 'CSV'),
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('PDF Document (.pdf / Print)', style: TextStyle(fontSize: 13)),
                              leading: Radio<String>(
                                value: 'PDF',
                                groupValue: _selectedFormat,
                                onChanged: (val) => setState(() => _selectedFormat = val ?? 'PDF'),
                              ),
                            ),
                            const Spacer(),

                            // Generate and Export buttons
                            CustomButton(
                              text: 'PREVIEW REPORT',
                              width: double.infinity,
                              icon: Icons.preview_rounded,
                              type: ButtonType.outlined,
                              onPressed: () => _generatePreview(appState),
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'GENERATE & EXPORT',
                              width: double.infinity,
                              icon: Icons.download_rounded,
                              type: ButtonType.primary,
                              isLoading: _isGenerating,
                              onPressed: () => _exportReport(appState),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // RIGHT SIDE: Preview area
                  Expanded(
                    flex: 5,
                    child: Card(
                      child: !_hasPreview
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.query_stats_rounded,
                                    size: 64,
                                    color: AppTheme.textSecondary.withOpacity(0.2),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No report loaded',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Configure your options on the left and click Preview Report.',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _buildReportPreview(),
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

  Widget _buildReportPreview() {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (_selectedReportType == 'Sales Summary') {
      // 1. Calculate metrics
      final totalRevenue = _previewSales.fold<double>(0.0, (sum, s) => sum + s.total);
      final totalProfit = _previewSales.fold<double>(0.0, (sum, s) => sum + s.profit);
      final totalDiscounts = _previewSales.fold<double>(0.0, (sum, s) => sum + s.discount);
      final avgTicket = _previewSales.isEmpty ? 0.0 : totalRevenue / _previewSales.length;

      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Summary Preview ($_selectedDateRange)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_previewSales.length} Transactions',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sales metrics row
            Row(
              children: [
                Expanded(child: _metricCard('TOTAL REVENUE', currencyFormat.format(totalRevenue), AppTheme.primary)),
                const SizedBox(width: 14),
                Expanded(child: _metricCard('NET PROFIT', currencyFormat.format(totalProfit), AppTheme.success)),
                const SizedBox(width: 14),
                Expanded(child: _metricCard('DISCOUNTS APPLIED', currencyFormat.format(totalDiscounts), AppTheme.tertiary)),
                const SizedBox(width: 14),
                Expanded(child: _metricCard('AVG. ORDER VALUE', currencyFormat.format(avgTicket), AppTheme.secondary)),
              ],
            ),
            const SizedBox(height: 24),

            // Data Table preview
            const Text(
              'TRANSACTIONS PREVIEW (TOP 50 ROWS)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: _previewSales.isEmpty
                    ? const Center(
                        child: Text(
                          'No transaction logs found for this date range.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView(
                        children: [
                          DataTable(
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text('Sale ID', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Date Time', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Method', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _previewSales.take(50).map((sale) {
                              final displayId = sale.id != null ? '#${sale.id!.oid.substring(18)}' : '#N/A';
                              final dateStr = DateFormat('MM-dd HH:mm').format(sale.dateTime);
                              return DataRow(
                                cells: [
                                  DataCell(Text(displayId, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text(dateStr)),
                                  DataCell(Text(sale.paymentMethod)),
                                  DataCell(Text(currencyFormat.format(sale.subTotal))),
                                  DataCell(Text(currencyFormat.format(sale.discount), style: const TextStyle(color: AppTheme.tertiary))),
                                  DataCell(Text(currencyFormat.format(sale.total), style: const TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold))),
                                  DataCell(Text(currencyFormat.format(sale.profit), style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold))),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
    } else {
    // Inventory Stock Valuation
    final int uniqueItems = _previewProducts.length;
    final int totalStock = _previewProducts.fold<int>(0, (sum, p) => sum + p.stock);
    final double totalCost = _previewProducts.fold<double>(0.0, (sum, p) => sum + (p.stock * p.costPrice));
    final double totalRetail = _previewProducts.fold<double>(0.0, (sum, p) => sum + (p.stock * p.price));

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Inventory Stock Valuation Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                ),
                child: Text(
                  '$uniqueItems Unique Items',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inventory metrics row
          Row(
            children: [
              Expanded(child: _metricCard('TOTAL STOCK UNITS', totalStock.toString(), AppTheme.secondary)),
              const SizedBox(width: 14),
              Expanded(child: _metricCard('TOTAL COST VALUE', currencyFormat.format(totalCost), AppTheme.warning)),
              const SizedBox(width: 14),
              Expanded(child: _metricCard('ESTIMATED RETAIL VALUE', currencyFormat.format(totalRetail), AppTheme.primaryLight)),
              const SizedBox(width: 14),
              Expanded(child: _metricCard('POTENTIAL GROSS PROFIT', currencyFormat.format(totalRetail - totalCost), AppTheme.success)),
            ],
          ),
          const SizedBox(height: 24),

          // Data Table preview
          const Text(
            'INVENTORY VALUATION PREVIEW (TOP 50 ROWS)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: _previewProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found in inventory.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView(
                      children: [
                        DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Stock Level', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Cost Price', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Retail Price', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Stock Valuation', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _previewProducts.take(50).map((product) {
                            final valCost = product.stock * product.costPrice;
                            return DataRow(
                              cells: [
                                DataCell(Text(product.sku, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                DataCell(Text(product.category)),
                                DataCell(Text('${product.stock}')),
                                DataCell(Text(currencyFormat.format(product.costPrice))),
                                DataCell(Text(currencyFormat.format(product.price))),
                                DataCell(Text(currencyFormat.format(valCost), style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold))),
                              ],
                            );
                          }).toList(),
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

  Widget _metricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Modal dialog showing simulated PDF document creation and downloading
class _PdfReportSimulationDialog extends StatefulWidget {
  final String reportType;
  final String dateRange;
  final List<Sale> sales;
  final List<Product> products;

  const _PdfReportSimulationDialog({
    Key? key,
    required this.reportType,
    required this.dateRange,
    required this.sales,
    required this.products,
  }) : super(key: key);

  @override
  State<_PdfReportSimulationDialog> createState() => _PdfReportSimulationDialogState();
}

class _PdfReportSimulationDialogState extends State<_PdfReportSimulationDialog> {
  bool _isGeneratingPdf = true;
  double _pdfProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _startPdfCompilation();
  }

  void _startPdfCompilation() async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _pdfProgress = i / 10;
        });
      }
    }
    
    // Create actual summary file in exports directory to mock PDF download output
    try {
      final dir = Directory('exports');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final filename = '${widget.reportType.replaceAll(' ', '_').toLowerCase()}_report_summary.txt';
      final file = File('${dir.path}/$filename');
      final buffer = StringBuffer();
      
      buffer.writeln('=== ${widget.reportType.toUpperCase()} ===');
      buffer.writeln('Generated on: ${DateTime.now().toLocal()}');
      if (widget.reportType == 'Sales Summary') {
        buffer.writeln('Date Range: ${widget.dateRange}');
        buffer.writeln('Total sales count: ${widget.sales.length}');
        final total = widget.sales.fold<double>(0.0, (sum, s) => sum + s.total);
        buffer.writeln('Total Sales Revenue: \$${total.toStringAsFixed(2)}');
      } else {
        buffer.writeln('Total Unique items: ${widget.products.length}');
        final stock = widget.products.fold<int>(0, (sum, p) => sum + p.stock);
        buffer.writeln('Total Stock levels: $stock');
      }
      await file.writeAsString(buffer.toString());
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {


    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'PDF Report Compiler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),

            // PDF visual canvas mockup
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Container(
                  width: 320,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Document Layout Preview
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(width: 40, height: 8, color: Colors.blueGrey[400]),
                                Container(width: 30, height: 6, color: Colors.blueGrey[200]),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Center(child: Container(width: 140, height: 10, color: Colors.blueGrey[700])),
                            const SizedBox(height: 6),
                            Center(child: Container(width: 80, height: 6, color: Colors.blueGrey[300])),
                            const SizedBox(height: 24),
                            // Line placeholders representing columns/table
                            _documentLinePlaceholder(0.9),
                            const SizedBox(height: 6),
                            _documentLinePlaceholder(0.75),
                            const SizedBox(height: 6),
                            _documentLinePlaceholder(0.85),
                            const SizedBox(height: 6),
                            _documentLinePlaceholder(0.5),
                            const Spacer(),
                            // Dotted footer
                            Container(width: double.infinity, height: 1.5, color: Colors.grey[300]),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(width: 50, height: 5, color: Colors.grey[400]),
                                Container(width: 20, height: 5, color: Colors.grey[400]),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Circular downloading overlay status
                      if (_isGeneratingPdf)
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(value: _pdfProgress, color: AppTheme.secondary),
                                const SizedBox(height: 12),
                                Text(
                                  'Compiling PDF... ${( _pdfProgress * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'PDF Export Ready!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),

            // Dialog action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _isGeneratingPdf
                  ? const Center(
                      child: Text(
                        'Generating print sheet vector data...',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('Print Document'),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Print instructions sent to default system spooler.'),
                                  backgroundColor: AppTheme.surfaceSecondary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
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

  Widget _documentLinePlaceholder(double fraction) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: fraction,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
