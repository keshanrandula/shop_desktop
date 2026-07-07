import 'dart:io';
import 'package:intl/intl.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';

class ReportHelper {
  // Ensure the exports directory exists
  static Future<Directory> _getExportDirectory() async {
    final dir = Directory('exports');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Escape CSV field if it contains commas or quotes
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Export Sales Report to CSV
  static Future<File> exportSalesReportCsv(List<Sale> sales, String rangeLabel) async {
    final dir = await _getExportDirectory();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final filenameFormat = DateFormat('yyyy_MM_dd_HHmmss');
    final String filename = 'sales_report_${filenameFormat.format(DateTime.now())}.csv';
    final File file = File('${dir.path}/$filename');

    final StringBuffer buffer = StringBuffer();
    
    // Header Info
    buffer.writeln('SALES SUMMARY REPORT');
    buffer.writeln('Date Range,${_escapeCsvField(rangeLabel)}');
    buffer.writeln('Generated At,${_escapeCsvField(dateFormat.format(DateTime.now()))}');
    buffer.writeln('Total Transactions,${sales.length}');
    buffer.writeln();

    // Table Headers
    buffer.writeln('Sale ID,Date Time,Payment Method,Status,Items Sold,Subtotal,Discount,Grand Total,Profit');

    // Data rows
    for (var sale in sales) {
      final saleId = sale.id?.oid ?? 'N/A';
      final dateTime = dateFormat.format(sale.dateTime);
      final paymentMethod = sale.paymentMethod;
      final status = sale.status;
      final itemsCount = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);
      final subtotal = sale.subTotal.toStringAsFixed(2);
      final discount = sale.discount.toStringAsFixed(2);
      final total = sale.total.toStringAsFixed(2);
      final profit = sale.profit.toStringAsFixed(2);

      buffer.writeln(
        '$saleId,'
        '${_escapeCsvField(dateTime)},'
        '${_escapeCsvField(paymentMethod)},'
        '${_escapeCsvField(status)},'
        '$itemsCount,'
        '$subtotal,'
        '$discount,'
        '$total,'
        '$profit'
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  // Export Inventory Valuation Report to CSV
  static Future<File> exportInventoryReportCsv(List<Product> products) async {
    final dir = await _getExportDirectory();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final filenameFormat = DateFormat('yyyy_MM_dd_HHmmss');
    final String filename = 'inventory_report_${filenameFormat.format(DateTime.now())}.csv';
    final File file = File('${dir.path}/$filename');

    final StringBuffer buffer = StringBuffer();

    // Header Info
    buffer.writeln('INVENTORY VALUATION REPORT');
    buffer.writeln('Generated At,${_escapeCsvField(dateFormat.format(DateTime.now()))}');
    buffer.writeln('Total Unique Products,${products.length}');
    
    final int totalStock = products.fold<int>(0, (sum, p) => sum + p.stock);
    final double totalCost = products.fold<double>(0.0, (sum, p) => sum + (p.stock * p.costPrice));
    final double totalRetail = products.fold<double>(0.0, (sum, p) => sum + (p.stock * p.price));

    buffer.writeln('Total Stock Units,$totalStock');
    buffer.writeln('Total Cost Value,${totalCost.toStringAsFixed(2)}');
    buffer.writeln('Total Retail Value,${totalRetail.toStringAsFixed(2)}');
    buffer.writeln();

    // Table Headers
    buffer.writeln('SKU,Product Name,Category,Stock Level,Cost Price,Retail Price,Total Cost Value,Total Retail Value');

    // Data rows
    for (var product in products) {
      final sku = product.sku;
      final name = product.name;
      final category = product.category;
      final stock = product.stock;
      final costPrice = product.costPrice.toStringAsFixed(2);
      final price = product.price.toStringAsFixed(2);
      final totalCostVal = (product.stock * product.costPrice).toStringAsFixed(2);
      final totalRetailVal = (product.stock * product.price).toStringAsFixed(2);

      buffer.writeln(
        '${_escapeCsvField(sku)},'
        '${_escapeCsvField(name)},'
        '${_escapeCsvField(category)},'
        '$stock,'
        '$costPrice,'
        '$price,'
        '$totalCostVal,'
        '$totalRetailVal'
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }
}
