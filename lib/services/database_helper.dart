import 'package:mongo_dart/mongo_dart.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/user_model.dart';
import '../models/supplier_model.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  // Singleton Pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Db? _db;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Initialize and connect to database
  Future<bool> init() async {
    if (_isConnected && _db != null) return true;

    try {
      _db = await Db.create(AppConstants.mongoDbUri);
      await _db!.open();
      _isConnected = true;
      print('Successfully connected to MongoDB.');

      // Check if seeding is needed
      await _seedIfEmpty();
      return true;
    } catch (e) {
      _isConnected = false;
      _db = null;
      print('Error connecting to MongoDB: $e');
      return false;
    }
  }

  // Get collection reference helper
  DbCollection _getCollection(String name) {
    if (!_isConnected || _db == null) {
      throw Exception('Database not connected. Please start your MongoDB server.');
    }
    return _db!.collection(name);
  }

  // Close connection
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _isConnected = false;
      _db = null;
    }
  }

  // --- PRODUCT CRUD OPERATIONS ---

  // Get all products
  Future<List<Product>> getProducts() async {
    try {
      final collection = _getCollection(AppConstants.productsCollection);
      final list = await collection.find().toList();
      return list.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Insert a new product
  Future<bool> insertProduct(Product product) async {
    try {
      final collection = _getCollection(AppConstants.productsCollection);
      final result = await collection.insertOne(product.toMap());
      return result.isSuccess;
    } catch (e) {
      print('Error inserting product: $e');
      return false;
    }
  }

  // Update product details
  Future<bool> updateProduct(Product product) async {
    if (product.id == null) return false;
    try {
      final collection = _getCollection(AppConstants.productsCollection);
      final result = await collection.replaceOne(
        where.eq('_id', product.id),
        product.toMap(),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(ObjectId id) async {
    try {
      final collection = _getCollection(AppConstants.productsCollection);
      final result = await collection.deleteOne(where.eq('_id', id));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // --- SALES OPERATIONS ---

  // Get all recorded sales
  Future<List<Sale>> getSales() async {
    try {
      final collection = _getCollection(AppConstants.salesCollection);
      // Sort sales by date descending (recent first)
      final list = await collection.find(where.sortBy('dateTime', descending: true)).toList();
      return list.map((map) => Sale.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching sales: $e');
      return [];
    }
  }

  // Record a new sale transaction and update product stock levels
  Future<bool> recordSale(Sale sale) async {
    try {
      final salesCollection = _getCollection(AppConstants.salesCollection);
      final productsCollection = _getCollection(AppConstants.productsCollection);

      // 1. Insert the sale record
      final saleResult = await salesCollection.insertOne(sale.toMap());
      if (!saleResult.isSuccess) return false;

      // 2. Decrement stock levels for each item in the sale
      for (var item in sale.items) {
        if (item.product.id != null) {
          // Use standard atomic $inc operator to decrement stock
          await productsCollection.updateOne(
            where.eq('_id', item.product.id),
            modify.inc('stock', -item.quantity),
          );
        }
      }

      return true;
    } catch (e) {
      print('Error recording sale: $e');
      return false;
    }
  }

  // Refund a sale transaction and increment product stock levels back
  Future<bool> refundSale(Sale sale) async {
    if (sale.id == null) return false;
    try {
      final salesCollection = _getCollection(AppConstants.salesCollection);
      final productsCollection = _getCollection(AppConstants.productsCollection);

      // 1. Update the sale status to 'Refunded'
      final saleResult = await salesCollection.updateOne(
        where.eq('_id', sale.id),
        modify.set('status', 'Refunded'),
      );
      if (!saleResult.isSuccess) return false;

      // 2. Increment stock levels back for each item in the sale
      for (var item in sale.items) {
        if (item.product.id != null) {
          await productsCollection.updateOne(
            where.eq('_id', item.product.id),
            modify.inc('stock', item.quantity),
          );
        }
      }

      return true;
    } catch (e) {
      print('Error refunding sale: $e');
      return false;
    }
  }

  // --- DATABASE SEEDING ---

  Future<void> _seedIfEmpty() async {
    try {
      // 1. Seed suppliers first if empty
      final suppliersCollection = _getCollection(AppConstants.suppliersCollection);
      final suppliersCount = await suppliersCollection.count();
      ObjectId? apexSupplierId;
      ObjectId? supremeSupplierId;

      if (suppliersCount == 0) {
        print('Suppliers table is empty. Seeding initial suppliers...');
        final s1 = Supplier(
          id: ObjectId(),
          name: 'Apex Distributors',
          phone: '+94 77 123 4567',
          email: 'orders@apexdistributors.com',
          address: '45 Galle Road, Colombo 03',
        );
        final s2 = Supplier(
          id: ObjectId(),
          name: 'Supreme Electro Trade',
          phone: '+94 71 987 6543',
          email: 'sales@supremeelectro.lk',
          address: '78 Kandy Road, Kadawatha',
        );

        await suppliersCollection.insertOne(s1.toMap());
        await suppliersCollection.insertOne(s2.toMap());
        apexSupplierId = s1.id;
        supremeSupplierId = s2.id;
      } else {
        final list = await suppliersCollection.find().toList();
        if (list.isNotEmpty) {
          apexSupplierId = list[0]['_id'] as ObjectId?;
          supremeSupplierId = list.length > 1 ? list[1]['_id'] as ObjectId? : list[0]['_id'] as ObjectId?;
        }
      }

      // 2. Seed products
      final collection = _getCollection(AppConstants.productsCollection);
      final count = await collection.count();
      if (count == 0) {
        print('Database is empty. Seeding initial products...');
        final seedProducts = [
          Product(
            sku: 'PROD-001',
            name: 'Apple iPhone 15 Pro',
            price: 999.99,
            costPrice: 750.00,
            stock: 25,
            category: 'Electronics',
            supplierId: apexSupplierId,
          ),
          Product(
            sku: 'PROD-002',
            name: 'Samsung Galaxy S24 Ultra',
            price: 1199.99,
            costPrice: 900.00,
            stock: 18,
            category: 'Electronics',
            supplierId: supremeSupplierId,
          ),
          Product(
            sku: 'PROD-003',
            name: 'Sony WH-1000XM5 Headphones',
            price: 399.99,
            costPrice: 280.00,
            stock: 35,
            category: 'Audio',
            supplierId: apexSupplierId,
          ),
          Product(
            sku: 'PROD-004',
            name: 'Logitech MX Master 3S Mouse',
            price: 99.99,
            costPrice: 65.00,
            stock: 50,
            category: 'Accessories',
            supplierId: supremeSupplierId,
          ),
          Product(
            sku: 'PROD-005',
            name: 'Dell UltraSharp 27" 4K Monitor',
            price: 499.99,
            costPrice: 380.00,
            stock: 12,
            category: 'Electronics',
            supplierId: apexSupplierId,
          ),
          Product(
            sku: 'PROD-006',
            name: 'Anker PowerCore 24K Power Bank',
            price: 149.99,
            costPrice: 95.00,
            stock: 8,
            category: 'Accessories',
            supplierId: supremeSupplierId,
          ),
          Product(
            sku: 'PROD-007',
            name: 'Mechanical Gaming Keyboard',
            price: 129.99,
            costPrice: 85.00,
            stock: 4,
            category: 'Accessories',
            supplierId: supremeSupplierId,
          ),
        ];

        for (var prod in seedProducts) {
          await collection.insertOne(prod.toMap());
        }
        print('Successfully seeded database.');
      }

      // Check and seed default admin user
      final usersCollection = _getCollection(AppConstants.usersCollection);
      final usersCount = await usersCollection.count();
      if (usersCount == 0) {
        print('Users table is empty. Seeding default admin user...');
        await usersCollection.insertOne(
          User(username: 'admin', password: 'admin123', role: 'Admin').toMap(),
        );
      }
    } catch (e) {
      print('Seeding failed: $e');
    }
  }

  // --- SUPPLIER CRUD OPERATIONS ---

  // Get all suppliers
  Future<List<Supplier>> getSuppliers() async {
    try {
      final collection = _getCollection(AppConstants.suppliersCollection);
      final list = await collection.find().toList();
      return list.map((map) => Supplier.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching suppliers: $e');
      return [];
    }
  }

  // Insert a new supplier
  Future<bool> insertSupplier(Supplier supplier) async {
    try {
      final collection = _getCollection(AppConstants.suppliersCollection);
      final result = await collection.insertOne(supplier.toMap());
      return result.isSuccess;
    } catch (e) {
      print('Error inserting supplier: $e');
      return false;
    }
  }

  // Update supplier details
  Future<bool> updateSupplier(Supplier supplier) async {
    if (supplier.id == null) return false;
    try {
      final collection = _getCollection(AppConstants.suppliersCollection);
      final result = await collection.replaceOne(
        where.eq('_id', supplier.id),
        supplier.toMap(),
      );
      return result.isSuccess;
    } catch (e) {
      print('Error updating supplier: $e');
      return false;
    }
  }

  // Delete supplier
  Future<bool> deleteSupplier(ObjectId id) async {
    try {
      final collection = _getCollection(AppConstants.suppliersCollection);
      final result = await collection.deleteOne(where.eq('_id', id));
      return result.isSuccess;
    } catch (e) {
      print('Error deleting supplier: $e');
      return false;
    }
  }

  // --- USER AUTHENTICATION & REGISTRATION ---

  // Verify username and password
  Future<User?> authenticateUser(String username, String password) async {
    try {
      final collection = _getCollection(AppConstants.usersCollection);
      final map = await collection.findOne(
        where.eq('username', username).eq('password', password),
      );
      if (map != null) {
        return User.fromMap(map);
      }
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  // Register a new user
  Future<bool> registerUser(User user) async {
    try {
      final collection = _getCollection(AppConstants.usersCollection);
      // Check if user already exists
      final existing = await collection.findOne(where.eq('username', user.username));
      if (existing != null) {
        return false; // User already exists
      }
      final result = await collection.insertOne(user.toMap());
      return result.isSuccess;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }
}
