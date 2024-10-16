import 'package:exel_category/view/filter_details_widgets/details_element.dart';
import 'package:exel_category/view/filter_details_widgets/row_filters.dart';
import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';

class FilterDetails extends ConsumerWidget {
  final List<ExcelElement> filteredElements;

  const FilterDetails({super.key, required this.filteredElements});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider = ref.watch(filtersProviderInstance);
    
    // Get the available column names for filtering
    final availableColumns = filtersProvider.filters.availableFilters.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Filtered Elements')),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            // Horizontal scroll for filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Enable horizontal scrolling
              child: Row(
                children: availableColumns.map((columnName) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add spacing between filters
                    child: RowFilters(columnName: columnName), // Your RowFilters widget
                  );
                }).toList(),
              ),
            ),
            // Provide some spacing below the filters
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DetailsElement(),
            ),
          ],
        ),
      ),
    );
  }
}

