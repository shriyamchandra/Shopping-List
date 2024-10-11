// lib/Widgets/grocery_list.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/Widgets/new_item.dart';
import 'package:shopping_list/Widgets/grocery_search_delegate.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import '../models/grocery_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  var _isLoading = true;
  String? _error;
  List<GroceryItem> _groceryItems = [];
  String _selectedFilter = 'All'; // Added for filtering
  String _selectedSort = 'Name Ascending'; // Added for sorting

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// Fetches grocery items from Firebase
  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-app-74492-default-rtdb.firebaseio.com',
      'shopping-list.json',
    );
    try {
      final response = await http.get(url);

      // Check if response body is empty or 'null'
      if (response.body.isEmpty || response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fetch data. Please try again later!';
          _isLoading = false; // Stop loading on error
        });
        return; // Exit the function to prevent further processing
      }

      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];

      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
            isPurchased: item.value['isPurchased'] ?? false,
            priority: _parsePriority(item.value['priority']),
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false; // Stop loading when data is fetched
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong. Please try again later.';
        _isLoading = false; // Stop loading in case of error
      });
    }
  }

  Priority _parsePriority(String? priorityStr) {
    switch (priorityStr) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      case 'medium':
      default:
        return Priority.medium;
    }
  }

  /// Adds a new grocery item to the list
  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const NewItem(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          // Slide Animation
          const beginOffset = Offset(1.0, 0.0); // Slide from right
          const endOffset = Offset.zero;
          const curve = Curves.ease;

          final offsetTween = Tween(begin: beginOffset, end: endOffset)
              .chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(offsetTween);

          // Fade Animation
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn));
          final fadeAnimation = animation.drive(fadeTween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  /// Edits an existing grocery item
  void _editItem(int index, GroceryItem item) async {
    final updatedItem = await Navigator.of(context).push<GroceryItem>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => NewItem(
          existingItem: item,
        ),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          // Slide Animation
          const beginOffset = Offset(1.0, 0.0); // Slide from right
          const endOffset = Offset.zero;
          const curve = Curves.ease;

          final offsetTween = Tween(begin: beginOffset, end: endOffset)
              .chain(CurveTween(curve: curve));
          final offsetAnimation = animation.drive(offsetTween);

          // Fade Animation
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn));
          final fadeAnimation = animation.drive(fadeTween);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    );

    if (updatedItem == null) {
      return;
    }

    setState(() {
      _groceryItems[index] = updatedItem;
    });
  }

  /// Removes a grocery item from the list
  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
      'shopping-list-app-74492-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      // Reinsert the item if deletion failed
      setState(() {
        _groceryItems.insert(index, item);
      });

      // Show a snackbar with the failure message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete ${item.name}. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Show a snackbar with a success message and an "Undo" action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} removed'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () async {
              // Reinsert the item in the list and backend if undo is pressed
              setState(() {
                _groceryItems.insert(index, item);
              });

              final undoUrl = Uri.https(
                'shopping-list-app-74492-default-rtdb.firebaseio.com',
                'shopping-list/${item.id}.json',
              );

              final response = await http.put(
                undoUrl,
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'name': item.name,
                  'quantity': item.quantity,
                  'category': item.category.title,
                  'isPurchased': item.isPurchased,
                  'priority': item.priority.toString().split('.').last,
                }),
              );

              if (response.statusCode >= 400) {
                // Show error message if reinserting in backend fails
                setState(() {
                  _groceryItems.removeAt(index);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to undo deletion of ${item.name}. Please try again.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  /// Toggles the purchase status of a grocery item
  void _togglePurchaseStatus(GroceryItem item) async {
    final updatedItem = item.copyWith(isPurchased: !item.isPurchased);

    setState(() {
      final index = _groceryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _groceryItems[index] = updatedItem;
      }
    });

    final url = Uri.https(
      'shopping-list-app-74492-default-rtdb.firebaseio.com',
      'shopping-list/${item.id}.json',
    );

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': updatedItem.name,
          'quantity': updatedItem.quantity,
          'category': updatedItem.category.title,
          'isPurchased': updatedItem.isPurchased,
          'priority': updatedItem.priority.toString().split('.').last,
        }),
      );

      if (response.statusCode >= 400) {
        throw Exception('Failed to update purchase status');
      }
    } catch (error) {
      // Revert the change if update fails
      setState(() {
        final index = _groceryItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _groceryItems[index] = item;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update ${item.name} status. Please try again.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows the instructional dialog
  void _showInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How to Use the App'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const [
              Text('• Tap on an item to mark it as purchased.'),
              SizedBox(height: 8),
              Text('• Swipe left on an item to delete it.'),
              SizedBox(height: 8),
              Text('• Use the edit button to modify item details.'),
              SizedBox(height: 8),
              Text('• Click the "+" icon to add a new item to your list.'),
              SizedBox(height: 8),
              Text('• Use the search icon to find specific items.'),
              SizedBox(height: 8),
              Text('• Use the filter icon to view items by category or status.'),
              SizedBox(height: 8),
              Text('• Use the sort icon to organize items based on your preference.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  /// Builds the priority indicator icon
  Widget _buildPriorityIndicator(Priority priority) {
    Color color;
    IconData icon;

    switch (priority) {
      case Priority.high:
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case Priority.medium:
        color = Colors.orange;
        icon = Icons.priority_high;
        break;
      case Priority.low:
        color = Colors.green;
        icon = Icons.arrow_downward;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply filtering based on _selectedFilter
    List<GroceryItem> displayedItems = _groceryItems;
    if (_selectedFilter == 'Purchased') {
      displayedItems = _groceryItems.where((item) => item.isPurchased).toList();
    } else if (_selectedFilter == 'Unpurchased') {
      displayedItems = _groceryItems.where((item) => !item.isPurchased).toList();
    }

    // Apply sorting based on _selectedSort
    if (_selectedSort == 'Name Ascending') {
      displayedItems.sort((a, b) => a.name.compareTo(b.name));
    } else if (_selectedSort == 'Name Descending') {
      displayedItems.sort((a, b) => b.name.compareTo(a.name));
    } else if (_selectedSort == 'Quantity Ascending') {
      displayedItems.sort((a, b) => a.quantity.compareTo(b.quantity));
    } else if (_selectedSort == 'Quantity Descending') {
      displayedItems.sort((a, b) => b.quantity.compareTo(a.quantity));
    } else if (_selectedSort == 'Priority Ascending') {
      displayedItems.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    } else if (_selectedSort == 'Priority Descending') {
      displayedItems.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    }

    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 20, color: Colors.red),
        ),
      );
    } else if (displayedItems.isEmpty) {
      String message;
      if (_selectedFilter == 'All') {
        message = 'Your grocery list is empty!';
      } else {
        message = 'No items match your filter.';
      }

      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optional: Add an illustration or icon
              Icon(
                Icons.shopping_cart_outlined,
                size: 100,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (_selectedFilter == 'All') ...[
                const SizedBox(height: 12),
                const Text(
                  'Tap the "+" button below to add your first item.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayedItems.length,
        itemBuilder: (ctx, index) {
          final item = displayedItems[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _removeItem(item);
            },
            background: Container(
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 30,
              ),
            ),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Theme.of(context).cardColor,
              child: ListTile(
                title: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: item.isPurchased ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.bold,
                    decoration: item.isPurchased
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text(
                  'Category: ${item.category.title}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: item.category.color,
                      radius: 12,
                    ),
                    const SizedBox(height: 4),
                    _buildPriorityIndicator(item.priority),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display quantity
                    Text(
                      'Qty: ${item.quantity}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Edit Icon
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        _editItem(_groceryItems.indexOf(item), item);
                      },
                      tooltip: 'Edit ${item.name}',
                    ),
                  ],
                ),
                onTap: () {
                  _togglePurchaseStatus(item);
                },
              ),
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        // Background layer (gradient)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF93E5FA),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Foreground layer with transparent scaffold
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Your Groceries'),
            actions: [
              IconButton(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                tooltip: 'Add Item',
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search Items',
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: GrocerySearchDelegate(_groceryItems, _editItem, _removeItem, _togglePurchaseStatus),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Items',
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'All',
                      child: Text('All Items'),
                    ),
                    const PopupMenuItem(
                      value: 'Purchased',
                      child: Text('Purchased'),
                    ),
                    const PopupMenuItem(
                      value: 'Unpurchased',
                      child: Text('Unpurchased'),
                    ),
                  ];
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Items',
                onSelected: (value) {
                  setState(() {
                    _selectedSort = value;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(
                      value: 'Name Ascending',
                      child: Text('Name (A-Z)'),
                    ),
                    const PopupMenuItem(
                      value: 'Name Descending',
                      child: Text('Name (Z-A)'),
                    ),
                    const PopupMenuItem(
                      value: 'Quantity Ascending',
                      child: Text('Quantity (Low to High)'),
                    ),
                    const PopupMenuItem(
                      value: 'Quantity Descending',
                      child: Text('Quantity (High to Low)'),
                    ),
                    const PopupMenuItem(
                      value: 'Priority Ascending',
                      child: Text('Priority (Low to High)'),
                    ),
                    const PopupMenuItem(
                      value: 'Priority Descending',
                      child: Text('Priority (High to Low)'),
                    ),
                  ];
                },
              ),
            ],
            // The AppBarTheme in main.dart handles text and icon colors
          ),
          body: content,
          floatingActionButton: FloatingActionButton(
            onPressed: _addItem,
            heroTag: 'addItemFAB',
            child: const Icon(Icons.add), // **Unique heroTag**
            tooltip: 'Add Item',
          ),
          floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
          // Positioned Information Icon at Bottom Left
          bottomNavigationBar: SizedBox(
            height: 80, // Increased height to accommodate the button
            child: Stack(
              children: [
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Tooltip(
                    message: 'How to Use',
                    child: IconButton(
                      icon: const Icon(Icons.help_outline),
                      color: Colors.blue,
                      iconSize: 30,
                      onPressed: _showInstructions,
                      tooltip: 'How to Use', // Tooltip added here
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
