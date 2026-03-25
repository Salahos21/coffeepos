# Tactile POS Prototype

Tactile POS is a responsive, Flutter-based Point of Sale (POS) prototype designed primarily for tablets but responsive enough to work on smaller, portrait screens. It features a modern, clean UI, local data persistence using SQLite, and a reactive cart system.

## 🚀 Key Features

*   **Responsive Layout:**
    *   Wide Screens (Tablets/Web): Displays a persistent left navigation rail, central product grid, and an always-visible right sidebar for the active order.
    *   Narrow Screens (Mobile): Condenses the active order sidebar into a slide-out drawer accessible via an app bar icon, ensuring the center catalog remains usable.
*   **Local Database:** Uses `sqflite` to persistently store and retrieve the product catalog locally on the device.
*   **Auto-Seeding:** Automatically populates the SQLite database with a default menu if it is initially empty.
*   **State Management:** Utilizes a custom `ChangeNotifier` (`CartState`) combined with `ListenableBuilder` to handle cart updates, subtotal, tax calculation, and triggering UI rebuilds efficiently and robustly without using heavy external dependencies.
*   **Dynamic Filtering & Search:**
    *   Filter products by categories (e.g., Espresso, Brew, Pastry, etc.).
    *   Search products by name dynamically.

## 🛠 Tech Stack & Dependencies

*   [Flutter](https://flutter.dev/) - Framework
*   [Dart](https://dart.dev/) - Programming Language
*   [sqflite](https://pub.dev/packages/sqflite) - SQLite plugin for Flutter used for local databases.
*   [path_provider](https://pub.dev/packages/path_provider) - Used to find appropriate local directories for the database file.
*   [path](https://pub.dev/packages/path) - A comprehensive, cross-platform path manipulation library.

## 📁 Project Structure

The key source files are located in the `lib` directory:

*   **`main.dart`**: Contains the vast majority of the UI logic, the application entry point, state management (`CartState`), data models (`Product`, `CartItem`), and layout components. Key widgets include:
    *   `TactilePOSApp`: Root application widget setting up the theme.
    *   `POSMainLayout`: Controls the high-level responsive screen structure (Nav / Center / Sidebar or Drawer).
    *   `POSCenterArea`: Handles the database fetching, UI filtering (search & categories), and building out the product grid.
    *   `POSActiveOrderSidebar`: Renders the shopping cart items, recalculates totals, checkout dialog logic, and modifier info.
*   **`database_helper.dart`**: A Singleton pattern class managing the SQLite database instance, table creation, and performing asynchronous CRUD operations (like `insertProduct` and `getAllProducts`).

## ⚙️ Getting Started

To get started with this application, ensure you have Flutter installed on your machine.

1.  Clone this repository or maintain it in your local workspace.
2.  Install all the Pub dependencies.
    ```bash
    flutter pub get
    ```
3.  Run the application on an emulator, physical device, or desktop (macOS/Windows/Linux).
    ```bash
    flutter run
    ```

## 📝 Future Improvements

*   Implement the Orders / Receipts tables in the database to record transaction history post-checkout.
*   Complete the implementation for nested side navigation routes (Orders, Inventory, Customers, Reports).
*   Add customizable product modifiers (e.g., Milk substitutions, sizing).
*   Persistent Cart state tracking.
