import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/view/column_filter_card.dart';
import 'package:exel_category/view/insert_file.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/view/filter_details.dart';
import 'package:exel_category/provider/filters_provider.dart'; // Import the FiltersProvider

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider =
        ref.watch(filtersProviderInstance); // Watch the FiltersProvider

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Exceletor'),
        actions: [
          // IconButton for English language
          IconButton(
            icon: Image.asset(
              'assets/uk_flag.png',
              width: 30,
              height: 20,
              fit: BoxFit.cover,
              semanticLabel: translate('en'),
            ),
            onPressed: () => changeLocale(context, 'en'),
            tooltip: translate('en'),
          ),
          // IconButton for Italian language
          IconButton(
            icon: Image.asset(
              'assets/it_flag.png',
              width: 30,
              height: 20,
              fit: BoxFit.cover,
              semanticLabel: translate('it'),
            ),
            onPressed: () => changeLocale(context, 'it'),
            tooltip: translate('it'),
          ),
          if (filtersProvider.filters.elements.isNotEmpty &&
              filtersProvider.filters.selectedFilters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                filtersProvider
                    .resetFilters(); // Reset filters when clicking "Refresh"
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InsertFile(
                onFileLoaded: (Map<String, List<String>> columnItems,
                    List<ExcelElement> loadedElements) {
                  filtersProvider
                      .initializeFilters(); // Initialize filters when a file is loaded
                },
              ),
            ),
            if (filtersProvider.filters.selectedFilters.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Show selected filters for each column
                    Expanded(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: filtersProvider
                            .filters.selectedFilters.entries
                            .map((entry) {
                          return Chip(
                            label: Text(
                              '${entry.key}: ${entry.value.join(', ')}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () {
                              // Remove the selected filter for a specific column
                              filtersProvider.removeFilter(
                                  entry.key, entry.value.first);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    // Button to reset all filters
                    TextButton(
                      onPressed: filtersProvider.resetFilters,
                      child: Text(translate('Reset All')),
                    ),
                  ],
                ),
              ),
            if (filtersProvider.filters.elements.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Show cards for each column
                    for (var column
                        in filtersProvider.filters.elements.first.details.keys)
                      ColumnFilterCard(
                        columnName: column,
                        // Removed the onSelectionChanged parameter
                      ),
                  ],
                ),
              ),
            const SizedBox(
              height: 55,
            ),
          ],
        ),
      ),
      // BottomSheet with the "Filter" button
      bottomSheet: filtersProvider.filters.elements.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Filter elements based on selected filters
                  final filteredElements =
                      filtersProvider.filters.elements.where((element) {
                    bool matchesAllFilters = true;
                    filtersProvider.filters.selectedFilters
                        .forEach((columnName, selectedValues) {
                      // Check only active filters
                      if (selectedValues.isNotEmpty &&
                          !selectedValues
                              .contains(element.details[columnName])) {
                        matchesAllFilters = false;
                      }
                    });
                    return matchesAllFilters;
                  }).toList();

                  print(
                      'first check ${filtersProvider.filters.selectedFilters.isNotEmpty}');
                  print('Second check ${filteredElements.isNotEmpty}');

                  // Check if any filters are applied
                  if (filtersProvider.filters.selectedFilters.isNotEmpty &&
                      filteredElements.isNotEmpty) {
                    // Navigate to the details page with the filtered elements
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FilterDetails(
                          filteredElements: filteredElements,
                        ),
                      ),
                    );
                  } else {
                    // Show a message if no results are found
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translate(
                            'No results match the selected filters.')),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.black,
                  elevation: 5,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  translate('Apply Filters'),
                  style: TextStyle(fontSize: 22),
                ),
              ),
            )
          : null,
    );
  }
}
