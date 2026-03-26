# Tactile POS - Point of Sale Application

Tactile POS is a modern, tablet-optimized Point of Sale (POS) application built with Flutter. It utilizes a local SQLite database for offline-first performance and features a responsive layout designed for high-traffic retail environments like coffee shops or small restaurants.

## 1. Key Features
*   **PIN-Based Authentication**: Secure login system with unique 4-digit PINs for different staff members.
*   **Role-Based Access Control (RBAC)**: Tailored UI experiences for **Managers** and **Baristas**.
*   **Digital Register**: Product grid with category filtering, search, and a real-time order sidebar.
*   **Business Analytics**: A visual dashboard using `fl_chart` showing daily revenue and top-selling items.
*   **Store Management**: Admin tools to manage staff members, product inventory, and categories.
*   **Persistent Storage**: Full SQLite integration for orders, products, and user data.

## 2. Architecture & State Management
*   **Persistence Layer (`sqflite`)**: Handles all CRUD operations. The `DatabaseHelper` follows a Singleton pattern and manages schema migrations.
*   **State Management**: 
    *   **Global States**: Located in `app_models.dart`, providing easy access to `currentUser` and the `cartState`.
    *   **Reactivity**: Uses `ListenableBuilder` and `ChangeNotifier` for the shopping cart to ensure the UI updates instantly when items are added or quantities change.
*   **Responsive Layout**: Uses a `Row` based layout for wide screens (tablets) with a `POSSideNav` and `POSActiveOrderSidebar`, while falling back to a `Drawer` for smaller portrait orientations.

## 3. Data Models (`lib/models/app_models.dart`)
| Model | Description |
| :--- | :--- |
| `PosUser` | Staff data: name, role (Manager/Barista), and 4-digit PIN. |
| `Product` | Item details: name, price, category, image path (local/web), and description. |
| `ProductCategory` | Organizational labels for the product grid. |
| `PosOrder` | Completed transaction: date, total, items summary, and the `cashierName`. |
| `CartItem` | Temporary item in the active order, tracking quantity and modifiers. |

## 4. Role-Based Access Control (RBAC)
The application dynamically adjusts the UI based on the `currentUser.role`:

### Barista Privileges:
*   **Register**: Full access to take orders and checkout.
*   **Orders**: Can see **only their own** past orders and personal performance metrics.
*   **Security**: The **Config** (Settings) tab is hidden.

### Manager Privileges:
*   **Full Register Access**: Can perform all barista tasks.
*   **Store Analytics**: Can view total store revenue and all-time history for all staff.
*   **Configuration**: Exclusive access to the "Staff" management tab (add/delete employees) and Inventory management (products/categories).

## 5. Project Structure

```
lib/
├── components/           # Reusable UI widgets
│   ├── side_nav.dart     # Role-based navigation & Logout
│   ├── center_area.dart  # Product grid & Search
│   └── active_order_sidebar.dart # Cart & Checkout logic
├── models/
│   └── app_models.dart   # Data structures & Global states
├── screens/
│   ├── login_screen.dart # PIN entry & Authentication
│   ├── orders_screen.dart# Analytics & History
│   └── config_screen.dart# Staff & Inventory Management
├── database_helper.dart  # SQLite Singleton & SQL Queries
└── main.dart             # App entry & Main layout routing
```

## 6. Configuration & Setup
The project depends on the following key packages:
*   `sqflite` & `path_provider`: Local database storage.
*   `fl_chart`: Business intelligence visualizations.
*   `image_picker`: For uploading product photos from the gallery.

### Database Seeding
Upon first launch (or database version upgrade), the system automatically creates default accounts:
*   **Manager**: Alice (PIN: `1234`)
*   **Barista**: Bob (PIN: `0000`)

---
*Documentation Generated: October 2023*
