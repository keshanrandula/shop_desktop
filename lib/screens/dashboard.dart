import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_state.dart';
import '../utils/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // M3 Summary calculations
    final todaySales = appState.todayTotalSales;
    final itemsSold = appState.todayItemsSold;
    final lowStockCount = appState.lowStockProducts.length;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real-time overview of your shop sales activity and catalog status.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // summary cards row
          Row(
            children: [
              // 1. Today's Total Sales
              Expanded(
                child: _SummaryStatCard(
                  title: "Today's Total Sales",
                  value: currencyFormat.format(todaySales),
                  icon: Icons.payments_rounded,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  iconColor: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 20),

              // 2. Items Sold
              Expanded(
                child: _SummaryStatCard(
                  title: 'Items Sold Today',
                  value: '$itemsSold units',
                  icon: Icons.shopping_basket_rounded,
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, Color(0xFF0891B2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  iconColor: AppTheme.secondary,
                ),
              ),
              const SizedBox(width: 20),

              // 3. Low Stock Alerts
              Expanded(
                child: _SummaryStatCard(
                  title: 'Low Stock Alerts',
                  value: lowStockCount.toString(),
                  icon: Icons.warning_amber_rounded,
                  gradient: LinearGradient(
                    colors: lowStockCount > 0
                        ? [AppTheme.danger, const Color(0xFFDC2626)]
                        : [AppTheme.surfaceSecondary, AppTheme.surfaceSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  iconColor: lowStockCount > 0 ? Colors.white : AppTheme.textSecondary,
                  textColor: lowStockCount > 0 ? Colors.white : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bottom Area: Chart + Lists
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart Widget
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Weekly Sales Performance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.trending_up_rounded, color: AppTheme.success, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active Week',
                                    style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          Expanded(
                            child: _WeeklyBarChart(trendData: appState.recentSalesTrend),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Transactions and Alerts list
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Recent sales list
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recent Sales Log',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: appState.sales.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No sales recorded today.',
                                            style: TextStyle(color: AppTheme.textMuted),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: appState.sales.length > 4
                                              ? 4
                                              : appState.sales.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(color: AppTheme.border, height: 16),
                                          itemBuilder: (context, index) {
                                            final sale = appState.sales[index];
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Receipt #${sale.id.toString().substring(sale.id.toString().length - 6).toUpperCase()}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${dateFormat.format(sale.dateTime)} • ${sale.paymentMethod}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  currencyFormat.format(sale.total),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppTheme.secondary,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Low Stock panel
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Inventory Low Stock Warns',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: appState.lowStockProducts.isEmpty
                                      ? const Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check_circle_outline_rounded,
                                                  color: AppTheme.success, size: 16),
                                              SizedBox(width: 8),
                                              Text(
                                                'Inventory counts healthy',
                                                style: TextStyle(
                                                    color: AppTheme.success,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: appState.lowStockProducts.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(color: AppTheme.border, height: 16),
                                          itemBuilder: (context, index) {
                                            final product =
                                                appState.lowStockProducts[index];
                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'SKU: ${product.sku}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: product.stock == 0
                                                        ? AppTheme.danger.withOpacity(0.15)
                                                        : AppTheme.warning.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    product.stock == 0
                                                        ? 'OUT'
                                                        : '${product.stock} units',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w900,
                                                      color: product.stock == 0
                                                          ? AppTheme.danger
                                                          : AppTheme.warning,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
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
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final Color iconColor;
  final Color? textColor;

  const _SummaryStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Row(
          children: [
            // Circular Icon Background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 20),

            // Card details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor?.withOpacity(0.8) ?? AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor ?? AppTheme.textPrimary,
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

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, double> trendData;

  const _WeeklyBarChart({Key? key, required this.trendData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return const Center(child: Text('No sales trend records available.'));
    }

    final keys = trendData.keys.toList();
    final values = trendData.values.toList();
    final double maxVal = values.fold(0.0, (max, val) => val > max ? val : max);
    final double maxY = maxVal == 0 ? 100.0 : maxVal * 1.15; // Give 15% padding at top

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.surfaceSecondary,
            tooltipBorder: const BorderSide(color: AppTheme.border, width: 1),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '\$${rod.toY.toStringAsFixed(2)}',
                const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int idx = value.toInt();
                if (idx < 0 || idx >= keys.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    keys[idx],
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const Text('\$0');
                if (value >= 1000) {
                  return Text('\$${(value / 1000).toStringAsFixed(1)}k');
                }
                return Text('\$${value.toInt()}');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppTheme.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(trendData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
