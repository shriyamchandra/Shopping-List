// lib/Widgets/grocery_search_delegate.dart
import 'package:flutter/material.dart';
import '../models/grocery_item.dart';

class GrocerySearchDelegate extends SearchDelegate<GroceryItem?> {
  final List<GroceryItem> items;
  final Function(int, GroceryItem) editItem;
  final Function(GroceryItem) removeItem;
  final Function(GroceryItem) togglePurchaseStatus;

  GrocerySearchDelegate(this.items, this.editItem, this.removeItem, this.togglePurchaseStatus);

  @override
  String get searchFieldLabel => 'Search groceries';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
          tooltip: 'Clear Search',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Back',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = items.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();

    return _buildList(results, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = items.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();

    return _buildList(suggestions, context);
  }

  Widget _buildList(List<GroceryItem> list, BuildContext context) {
    if (list.isEmpty) {
      return const Center(
        child: Text('No items found.'),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final item = list[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text('Qty: ${item.quantity}'),
          trailing: Icon(
            item.isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
            color: item.isPurchased ? Colors.green : Colors.grey,
          ),
          onTap: () {
            togglePurchaseStatus(item);
          },
          onLongPress: () {
            // Optionally, provide options to edit or delete
            showModalBottomSheet(
              context: context,
              builder: (_) => Container(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit'),
                      onTap: () {
                        Navigator.of(context).pop();
                        final originalIndex = items.indexOf(item);
                        editItem(originalIndex, item);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Delete'),
                      onTap: () {
                        Navigator.of(context).pop();
                        removeItem(item);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
