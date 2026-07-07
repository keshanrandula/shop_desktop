import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'utils/theme.dart';
import 'widgets/side_menu.dart';
import 'screens/dashboard.dart';
import 'screens/billing_pos.dart';
import 'screens/inventory.dart';
import 'screens/auth_screen.dart';
import 'screens/sales_history.dart';
import 'screens/suppliers.dart';
import 'screens/reports.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop POS & Inventory',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // If database connection is initializing, show a loading spinner
    if (appState.isConnectingDb) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryLight),
              SizedBox(height: 24),
              Text(
                'Connecting to MongoDB...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If connection failed, present a detailed error connection pane with a retry button
    if (!appState.isDbConnected) {
      return Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.report_problem_rounded,
                  color: AppTheme.danger,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Database Connection Error',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appState.dbError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Work offline / show app anyway
                        appState.refreshData(); // Triggers direct offline state
                      },
                      icon: const Icon(Icons.cloud_off_rounded),
                      label: const Text('Work Offline'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => appState.initDatabase(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Connection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If user is not authenticated, show Auth Screen
    if (appState.currentUser == null) {
      return const AuthScreen();
    }

    // Standard application shell with Left Sidebar Navigation & Right Page Content
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          const SideMenu(),
          // Vertical border separating menu from screen
          Container(
            width: 1,
            height: double.infinity,
            color: AppTheme.border,
          ),
          // Screen Page contents (preserves scroll state with IndexedStack)
          Expanded(
            child: IndexedStack(
              index: appState.selectedPageIndex,
              children: const [
                DashboardScreen(),
                BillingPosScreen(),
                InventoryScreen(),
                SalesHistoryScreen(),
                SuppliersScreen(),
                ReportsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
