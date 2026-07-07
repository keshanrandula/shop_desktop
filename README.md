# Shop POS & Inventory Management System

A premium, modern desktop Point of Sale (POS) and Inventory Management system built with **Flutter** and powered by **MongoDB**. Designed specifically for retail shop owners to streamline billing, track stock levels, manage suppliers, and analyze sales.

---

## 🌟 Features

*   **🔒 Authentication:** Secure user authentication (Login/Signup) for staff and admins.
*   **📊 Interactive Dashboard:** Real-time business insights, key metrics (sales, revenue, low stock alerts), and graphical statistics.
*   **🛒 Point of Sale (POS) Billing:** Clean, intuitive shopping cart interface to process transactions quickly with automatic inventory deductions.
*   **📦 Inventory Management:** Add, update, view, and restock products. Features search, categorizations, and low stock thresholds.
*   **👥 Supplier Management:** Manage suppliers, contact details, and inventory supplies history.
*   **📈 Sales History & Reports:** Detailed sales records list with filters, revenue analytics, and comprehensive reports.

---

## 🛠️ Tech Stack

*   **Frontend Framework:** Flutter (Windows Native & Desktop platforms)
*   **Database:** MongoDB (Local instance)
*   **State Management:** Provider
*   **Database Connector:** `mongo_dart`

---

## 🚀 Setup & Installation

### 1. Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.
*   [MongoDB Community Server](https://www.mongodb.com/try/download/community) installed and running locally on default port `27017`.

### 2. Enable Windows Developer Mode
Because building Flutter apps with plugins on Windows requires symbolic link permissions:
1. Open Windows Search and type **"Developer settings"**.
2. Toggle **Developer Mode** to **On**.

### 3. Run MongoDB Server
Make sure your local MongoDB instance is started:
```powershell
# If registered as a service (Windows)
net start MongoDB
```

### 4. Clone and Run the App
```powershell
# Get dependencies
flutter pub get

# Run on Windows
flutter run -d windows
```

---

## 📁 Project Structure

```
lib/
├── models/         # Data models (Product, Sale, Supplier, User)
├── screens/        # UI Screen layouts (POS, Inventory, Dashboard, Reports, etc.)
├── services/       # Database & Business logic handlers (MongoDB Helper, Report Helper)
├── utils/          # App constants, Theme, and Styles configuration
└── widgets/        # Reusable custom UI components (Product Cards, Side Menu, Buttons)
```
