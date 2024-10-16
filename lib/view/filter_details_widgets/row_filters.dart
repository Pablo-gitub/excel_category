import 'package:exel_category/provider/row_filters_height_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';

class RowFilters extends ConsumerWidget {
  final String columnName;

  const RowFilters({
    Key? key,
    required this.columnName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider =
        ref.watch(filtersProviderInstance); // Access the FiltersProvider

    // Get the available items for this column from availableFilters
    final uniqueItems =
        filtersProvider.filters.availableFilters[columnName] ?? [];

    // Get currently selected items for this column
    final selectedItems =
        filtersProvider.filters.selectedFilters[columnName] ?? [];

    final heightProvider = ref.watch(rowFiltersHeightProvider);

    return SingleChildScrollView(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SizedBox(
          width: 200,
          child: ExpansionTile(
            title: Text(columnName),
            onExpansionChanged: (isExpanded) {
              // Update the height in the provider based on expansion state
              heightProvider.setHeight(isExpanded);
            },
            children: [
              // Show checkboxes for unique values
              for (var item in uniqueItems)
                CheckboxListTile(
                  title: Text(
                      item.toString()), // Convert item to String for display
                  value: selectedItems.contains(item),
                  onChanged: (bool? value) {
                    if (value == true) {
                      // Add item if checked
                      filtersProvider.addFilter(columnName, item);
                    } else {
                      // Remove item if unchecked
                      filtersProvider.removeFilter(columnName, item);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
