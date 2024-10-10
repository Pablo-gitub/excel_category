import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/model/filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filtersProviderInstance = ChangeNotifierProvider<FiltersProvider>((ref) {
  // Initialize with an empty list or provide a way to load initial elements
  return FiltersProvider([]); // Adjust the initial elements as needed
});

class FiltersProvider with ChangeNotifier {
  Filters _filters;

  // Constructor to initialize the Filters instance
  FiltersProvider(List<ExcelElement> elements) : _filters = Filters(elements: elements);

  // Getter for filters
  Filters get filters => _filters;

  void updateFilters(List<ExcelElement> elements) {
    _filters = Filters(elements: elements); // Update the Filters instance
    notifyListeners(); // Notify listeners about the change
  }

  // Method to initialize available filters
  void initializeFilters() {
    _filters.initializeAvailableFilters(_filters.elements);
    notifyListeners(); // Notify listeners about the change
  }

  // Method to add a filter
  void addFilter(String key, dynamic value) {
    print('Adding filter: $key - $value');
    _filters.addFilter(key, value);
    print('Aveilable filters: ${_filters.availableFilters}');
    notifyListeners(); // Notify listeners about the change
  }

  // Method to remove a filter
  void removeFilter(String key, dynamic value) {
    print('Removing filter: $key - $value');
    _filters.removeFilter(key, value);
    notifyListeners(); // Notify listeners about the change
  }

  // Method to update selected filters
  void updateSelectedFilters(String columnName, List<dynamic> values) {
    _filters.updateSelectedFilters(columnName, values);
    notifyListeners(); // Notify listeners about the change
  }

  // Method to reset all filters
  void resetFilters() {
    _filters.selectedFilters.clear(); // Clear selected filters
    _filters.availableFilters.clear(); // Clear available filters
    initializeFilters(); // Reinitialize available filters based on current elements
    notifyListeners(); // Notify listeners about the change
  }
}
