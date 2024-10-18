import 'package:exel_category/model/filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/provider/filters_provider.dart';

final elementsProviderInstance = Provider<ElementsProvider>((ref) {
  final filtersProvider = ref.watch(filtersProviderInstance);
  return ElementsProvider(filtersProvider.filters);
});

class ElementsProvider {
  final Filters filters;

  ElementsProvider(this.filters);

  List<ExcelElement> get filteredElements {
    // Retrieve filtered elements based on selected filters
    if (filters.selectedFilters.isEmpty) {
      // Return all elements if no filters are selected
      return filters.elements;
    }
    
    // Apply filters to the elements
    return filters.elements.where((element) {
      return filters.selectedFilters.entries.every((filterEntry) {
        final columnName = filterEntry.key;
        final selectedValues = filterEntry.value;
        // Check that the element matches all selected filters
        return selectedValues.contains(element.details[columnName]);
      });
    }).toList();
  }
}
