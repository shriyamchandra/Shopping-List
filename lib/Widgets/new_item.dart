// lib/Widgets/new_item.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:http/http.dart' as http;

class NewItem extends StatefulWidget {
  final GroceryItem? existingItem; // Optional parameter for editing

  const NewItem({super.key, this.existingItem});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> with SingleTickerProviderStateMixin {
  var _isSending = false;
  final _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  late Category _selectedCategory;
  Priority _selectedPriority = Priority.medium; // Default priority

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize selected category
    _selectedCategory = widget.existingItem?.category ??
        categories[Categories.vegetables]!; // Default to vegetables

    // Initialize entered name, quantity, and priority if editing
    if (widget.existingItem != null) {
      _enteredName = widget.existingItem!.name;
      _enteredQuantity = widget.existingItem!.quantity;
      _selectedPriority = widget.existingItem!.priority;
    }

    // Initialize AnimationController for fade-in effect
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 500), // Match the page transition duration
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _saveItem() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _isSending = true;
    });

    if (widget.existingItem == null) {
      // Adding a new item
      final url = Uri.https(
        'shopping-list-app-74492-default-rtdb.firebaseio.com',
        'shopping-list.json',
      );

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
            'isPurchased': false,
            'priority': _selectedPriority
                .toString()
                .split('.')
                .last, // Save priority as string
          }),
        );

        if (response.statusCode >= 400) {
          throw Exception('Failed to add item');
        }

        final resData = json.decode(response.body);
        if (!mounted) return;

        Navigator.of(context).pop(
          GroceryItem(
            id: resData['name'],
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory,
            isPurchased: false,
            priority: _selectedPriority,
          ),
        );
      } catch (error) {
        // Show error dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('An error occurred!'),
            content:
                const Text('Something went wrong. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    } else {
      // Editing an existing item
      final url = Uri.https(
        'shopping-list-app-74492-default-rtdb.firebaseio.com',
        'shopping-list/${widget.existingItem!.id}.json',
      );

      try {
        final response = await http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _selectedCategory.title,
            'isPurchased': widget.existingItem!.isPurchased,
            'priority':
                _selectedPriority.toString().split('.').last, // Update priority
          }),
        );

        if (response.statusCode >= 400) {
          throw Exception('Failed to update item');
        }

        Navigator.of(context).pop(
          GroceryItem(
            id: widget.existingItem!.id,
            name: _enteredName,
            quantity: _enteredQuantity,
            category: _selectedCategory,
            isPurchased: widget.existingItem!.isPurchased,
            priority: _selectedPriority,
          ),
        );
      } catch (error) {
        // Show error dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('An error occurred!'),
            content:
                const Text('Something went wrong. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Okay'),
              ),
            ],
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Background layer (optional gradient)
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
          // Foreground layer: Form inside a scrollable view
          Scaffold(
            backgroundColor: Colors.transparent, // Make Scaffold transparent
            appBar: AppBar(
              title: Text(
                  widget.existingItem == null ? "Add a New Item" : "Edit Item"),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Form Instructions
                        Text(
                          widget.existingItem == null
                              ? 'Fill in the details below to add a new grocery item to your list.'
                              : 'Update the details below to edit the grocery item.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Name Field with Icon
                              TextFormField(
                                initialValue: _enteredName,
                                maxLength: 50,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  hintText: 'e.g., Apples, Bread',
                                  prefixIcon: const Icon(Icons.shopping_bag),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      value.trim().length < 2 ||
                                      value.trim().length > 50) {
                                    return 'Must be between 2 and 50 characters.';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredName = value!.trim();
                                },
                              ),
                              const SizedBox(height: 16),
                              // Quantity and Category Row
                              Row(
                                children: [
                                  // Quantity Field with Icon
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _enteredQuantity.toString(),
                                      decoration: InputDecoration(
                                        labelText: 'Quantity',
                                        hintText: 'e.g., 2',
                                        prefixIcon: const Icon(
                                            Icons.format_list_numbered),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ], // Ensures only digits are entered
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty ||
                                            int.tryParse(value) == null ||
                                            int.parse(value) <= 0) {
                                          return 'Enter a valid positive number';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _enteredQuantity = int.parse(value!);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Category Dropdown with Icon
                                  Expanded(
                                    child: DropdownButtonFormField<Category>(
                                      isExpanded:
                                          true, // Ensures full width usage
                                      value: _selectedCategory,
                                      decoration: InputDecoration(
                                        labelText: 'Category',
                                        hintText: 'Select a category',
                                        prefixIcon: const Icon(Icons.category),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      items: categories.entries.map((entry) {
                                        return DropdownMenuItem<Category>(
                                          value: entry.value,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: entry.value.color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  entry.value.title,
                                                  overflow: TextOverflow
                                                      .ellipsis, // Truncates overflow text
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedCategory = value!;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a category';
                                        }
                                        return null;
                                      },
                                      onSaved: (value) {
                                        _selectedCategory = value!;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Priority Dropdown with Icon
                              DropdownButtonFormField<Priority>(
                                value: _selectedPriority,
                                decoration: InputDecoration(
                                  labelText: 'Priority',
                                  hintText: 'Select priority level',
                                  prefixIcon: const Icon(Icons.priority_high),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: Priority.values.map((priority) {
                                  return DropdownMenuItem<Priority>(
                                    value: priority,
                                    child: Text(
                                      priority
                                          .toString()
                                          .split('.')
                                          .last
                                          .capitalize(),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriority = value!;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a priority level';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _selectedPriority = value!;
                                },
                              ),
                              const SizedBox(height: 24),
                              // Buttons Row with Icons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Reset Button with Icon
                                  ElevatedButton.icon(
                                    onPressed: _isSending
                                        ? null
                                        : () {
                                            _formKey.currentState?.reset();
                                            setState(() {
                                              _selectedCategory = categories[
                                                  Categories.vegetables]!;
                                              _enteredQuantity = 1;
                                              _enteredName = '';
                                              _selectedPriority =
                                                  Priority.medium;
                                            });
                                          },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reset'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Add/Update Item Button with Icon
                                  ElevatedButton.icon(
                                    onPressed: _isSending ? null : _saveItem,
                                    icon: _isSending
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(widget.existingItem == null
                                            ? Icons.add
                                            : Icons.save),
                                    label: Text(widget.existingItem == null
                                        ? 'Add Item'
                                        : 'Update Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
