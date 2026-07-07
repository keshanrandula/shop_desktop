import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../models/supplier_model.dart';
import 'database_helper.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Authentication State
  User? _currentUser;
  User? get currentUser => _currentUser;

  // Navigation State
  int _selectedPageIndex = 0;
  int get selectedPageIndex => _selectedPageIndex;

  void setPageIndex(int index) {
    _selectedPageIndex = index;
    notifyListeners();
  }

  // Database Connection State
  bool _isConnectingDb = false;
  bool _isDbConnected = false;
  String _dbError = '';

  bool get isConnectingDb => _isConnectingDb;
  bool get isDbConnected => _isDbConnected;
  String get dbError => _dbError;

  // Catalog State
  List<Product> _products = [];
  bool _isLoadingProducts = false;
  List<Product> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;

  // Sales History State
  List<Sale> _sales = [];
  bool _isLoadingSales = false;
  List<Sale> get sales => _sales;
  bool get isLoadingSales => _isLoadingSales;

  // Suppliers State
  List<Supplier> _suppliers = [];
  bool _isLoadingSuppliers = false;
  List<Supplier> get suppliers => _suppliers;
  bool get isLoadingSuppliers => _isLoadingSuppliers;

  // POS State
  final List<CartItem> _cart = [];
  double _posDiscount = 0.0; // Fixed amount discount
  String _posSearchQuery = '';
  String _posSelectedCategory = 'All';
  String _posSelectedPaymentMethod = 'Cash';

  List<CartItem> get cart => _cart;
  double get posDiscount => _posDiscount;
  String get posSearchQuery => _posSearchQuery;
  String get posSelectedCategory => _posSelectedCategory;
  String get posSelectedPaymentMethod => _posSelectedPaymentMethod;

  // Constructor
  AppState() {
    initDatabase();
  }

  // Initialize Database and Load Data
  Future<void> initDatabase() async {
    _isConnectingDb = true;
    _dbError = '';
    notifyListeners();

    bool connected = await _dbHelper.init();
    _isDbConnected = connected;
    _isConnectingDb = false;

    if (connected) {
      await refreshData();
    } else {
      _dbError = 'Could not connect to MongoDB database at ${_dbHelper.isConnected ? "configured URI" : "mongodb://127.0.0.1:27017/shop_desktop_db"}. Please make sure MongoDB is running.';
    }
    notifyListeners();
  }

  // --- USER AUTHENTICATION & MANAGEMENT ---

  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.authenticateUser(username, password);
    if (user != null) {
      _currentUser = user;
      _selectedPageIndex = 0; // Redirect to Dashboard on login
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String username, String password, String role) async {
    final user = User(username: username, password: password, role: role);
    return await _dbHelper.registerUser(user);
  }

  void logout() {
    _currentUser = null;
    clearCart();
    notifyListeners();
  }

  // Refresh all products, sales, and suppliers
  Future<void> refreshData() async {
    if (!_isDbConnected) return;

    _isLoadingProducts = true;
    _isLoadingSales = true;
    _isLoadingSuppliers = true;
    notifyListeners();

    _products = await _dbHelper.getProducts();
    _isLoadingProducts = false;
    notifyListeners();

    _sales = await _dbHelper.getSales();
    _isLoadingSales = false;
    notifyListeners();

    _suppliers = await _dbHelper.getSuppliers();
    _isLoadingSuppliers = false;
    notifyListeners();
  }

  // Get distinct categories in products
  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  // --- PRODUCT MANAGEMENT (INVENTORY) ---

  Future<bool> addProduct(Product product) async {
    bool success = await _dbHelper.insertProduct(product);
    if (success) {
      await refreshData();
    }
    return success;
  }

  Future<bool> updateProduct(Product product) async {
    bool success = await _dbHelper.updateProduct(product);
    if (success) {
      // Update item inside cart if it's currently in cart
      final cartIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (cartIndex != -1) {
        _cart[cartIndex] = CartItem(product: product, quantity: _cart[cartIndex].quantity);
      }
      await refreshData();
    }
    return success;
  }

  Future<bool> deleteProduct(ObjectId id) async {
    bool success = await _dbHelper.deleteProduct(id);
    if (success) {
      // Remove item from cart if it's in the cart
      _cart.removeWhere((item) => item.product.id == id);
      await refreshData();
    }
    return success;
  }

  // --- SUPPLIER MANAGEMENT ---

  Future<bool> addSupplier(Supplier supplier) async {
    bool success = await _dbHelper.insertSupplier(supplier);
    if (success) {
      await refreshData();
    }
    return success;
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    bool success = await _dbHelper.updateSupplier(supplier);
    if (success) {
      await refreshData();
    }
    return success;
  }

  Future<bool> deleteSupplier(ObjectId id) async {
    bool success = await _dbHelper.deleteSupplier(id);
    if (success) {
      // Set supplierId to null for products supplied by this deleted supplier
      final affectedProducts = _products.where((p) => p.supplierId == id);
      for (var product in affectedProducts) {
        await _dbHelper.updateProduct(product.copyWith(supplierId: null));
      }
      await refreshData();
    }
    return success;
  }

  // --- POS CART OPERATIONS ---

  void setPosSearchQuery(String query) {
    _posSearchQuery = query;
    notifyListeners();
  }

  void setPosCategory(String category) {
    _posSelectedCategory = category;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _posSelectedPaymentMethod = method;
    notifyListeners();
  }

  void setDiscount(double discount) {
    if (discount >= 0 && discount <= cartSubtotal) {
      _posDiscount = discount;
      notifyListeners();
    }
  }

  // List of products filtered by category and search query
  List<Product> get filteredProducts {
    return _products.where((product) {
      final matchesCategory = _posSelectedCategory == 'All' || product.category == _posSelectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(_posSearchQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(_posSearchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void addToCart(Product product) {
    // Check if product is out of stock
    if (product.stock <= 0) return;

    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      // Check if we have enough stock to increment
      if (_cart[existingIndex].quantity < product.stock) {
        _cart[existingIndex].quantity++;
      }
    } else {
      _cart.add(CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  void decrementCartItem(CartItem item) {
    final index = _cart.indexOf(item);
    if (index != -1) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
      // Re-verify discount limits
      if (_posDiscount > cartSubtotal) {
        _posDiscount = cartSubtotal;
      }
      notifyListeners();
    }
  }

  void removeCartItem(CartItem item) {
    _cart.remove(item);
    // Re-verify discount limits
    if (_posDiscount > cartSubtotal) {
      _posDiscount = cartSubtotal;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _posDiscount = 0.0;
    _posSearchQuery = '';
    _posSelectedCategory = 'All';
    _posSelectedPaymentMethod = 'Cash';
    notifyListeners();
  }

  // Checkout process
  Future<bool> checkout() async {
    if (_cart.isEmpty) return false;

    final subtotal = cartSubtotal;
    final total = cartTotal;

    final sale = Sale(
      items: List.from(_cart),
      subTotal: subtotal,
      discount: _posDiscount,
      total: total,
      paymentMethod: _posSelectedPaymentMethod,
      dateTime: DateTime.now(),
    );

    final success = await _dbHelper.recordSale(sale);
    if (success) {
      clearCart();
      await refreshData();
    }
    return success;
  }

  // Refund a sale and update app data
  Future<bool> refundSale(Sale sale) async {
    if (!_isDbConnected || sale.id == null) return false;
    final success = await _dbHelper.refundSale(sale);
    if (success) {
      await refreshData();
    }
    return success;
  }

  // --- STATS & ANALYTICS GETTERS (DASHBOARD) ---

  double get cartSubtotal => _cart.fold(0.0, (sum, item) => sum + item.total);
  double get cartTotal => cartSubtotal - _posDiscount < 0 ? 0.0 : cartSubtotal - _posDiscount;

  // Total sales revenue
  double get totalRevenue => _sales
      .where((sale) => sale.status != 'Refunded')
      .fold(0.0, (sum, sale) => sum + sale.total);

  // Today's total sales
  double get todayTotalSales {
    final now = DateTime.now();
    return _sales.where((sale) =>
        sale.status != 'Refunded' &&
        sale.dateTime.year == now.year &&
        sale.dateTime.month == now.month &&
        sale.dateTime.day == now.day
    ).fold(0.0, (sum, sale) => sum + sale.total);
  }

  // Items sold today
  int get todayItemsSold {
    final now = DateTime.now();
    return _sales.where((sale) =>
        sale.status != 'Refunded' &&
        sale.dateTime.year == now.year &&
        sale.dateTime.month == now.month &&
        sale.dateTime.day == now.day
    ).fold(0, (sum, sale) => sum + sale.items.fold(0, (itemSum, item) => itemSum + item.quantity));
  }

  // Total profits
  double get totalProfit => _sales
      .where((sale) => sale.status != 'Refunded')
      .fold(0.0, (sum, sale) => sum + sale.profit);

  // Total orders count
  int get totalSalesCount => _sales.where((sale) => sale.status != 'Refunded').length;

  // Products running low on stock (stock <= 5)
  List<Product> get lowStockProducts {
    return _products.where((p) => p.stock <= 5).toList();
  }

  // Grouped sales for simple trend chart (last 7 days)
  Map<String, double> get recentSalesTrend {
    final Map<String, double> trend = {};
    
    // Initialize last 7 days with 0.0
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = "${date.day}/${date.month}";
      trend[key] = 0.0;
    }

    // Populate actual sales data
    for (var sale in _sales) {
      if (sale.status == 'Refunded') continue; // Skip refunded sales
      final date = sale.dateTime;
      // Only include sales within the last 7 days
      if (DateTime.now().difference(date).inDays < 7) {
        final key = "${date.day}/${date.month}";
        if (trend.containsKey(key)) {
          trend[key] = trend[key]! + sale.total;
        }
      }
    }

    return trend;
  }
}
