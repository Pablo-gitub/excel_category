import 'package:exel_category/model/excel_element.dart';

class Filters {
  final List<ExcelElement> elements; // List of Excel elements to filter
  Map<String, List<dynamic>> selectedFilters =
      {}; // Holds currently selected filters
  Map<String, List<dynamic>> availableFilters =
      {}; // Holds available filter options

  // Constructor initializes the available filters with the provided elements
  Filters({required this.elements}) {
    initializeAvailableFilters(elements);
  }

  // Helper function to check if an element is present in a list
  bool _filterPresent(List<dynamic> list, dynamic element) {
    return list.contains(element);
  }

  // Initializes available filters based on the provided list of Excel elements
  void initializeAvailableFilters(List<ExcelElement> elements) {
    availableFilters.clear(); // Clear existing available filters
    for (var element in elements) {
      element.details.forEach((key, value) {
        // If the filter key doesn't exist, initialize it
        if (!availableFilters.containsKey(key)) {
          availableFilters[key] = [];
        }
        // Add the value to available filters if it's not already present
        if (!_filterPresent(availableFilters[key]!, value)) {
          availableFilters[key]!.add(value);
        }
      });
    }
    print('Aveilable filters after initialize: ${availableFilters}');
  }

  void addMissingFilters(){
    selectedFilters.forEach((k, values) {
      // If the current key exists in availableFilters
      if (availableFilters.containsKey(k)) {
        for (var value in values) {
          // If the value is not present in availableFilters, add it back
          if (!_filterPresent(availableFilters[k]!, value)) {
            availableFilters[k]!.add(value);
          }
        }
      }
    });
  }

  // Adds a filter to the selected filters map
  void addFilter(String key, dynamic value) {
    List<dynamic> temp = List.from(availableFilters[key]!);
    if (!selectedFilters.containsKey(key)) {
      selectedFilters[key] = []; // Initialize the list if the key doesn't exist
    }
    if (!_filterPresent(selectedFilters[key]!, value)) {
      selectedFilters[key]!
          .add(value); // Add the value if it's not already selected
    }
    updateAvailableFilters(); // Update available filters after adding a new one
    availableFilters[key] = temp;
    addMissingFilters();
  }

  // Removes a filter from the selected filters map
  void removeFilter(String key, dynamic value) {
    if (selectedFilters.containsKey(key)) {
      if (_filterPresent(selectedFilters[key]!, value)) {
        selectedFilters[key]!.remove(value); // Remove the value if it's present
        // Remove the key if there are no more values selected for it
        if (selectedFilters[key]!.isEmpty) {
          selectedFilters.remove(key);
        }
      }
    }
    updateAvailableFilters(); // Update available filters after removal
    // Check if any selected values are missing in available filters
    addMissingFilters();
  }

  // Updates the selected filters based on a column name and a list of values
  void updateSelectedFilters(String columnName, List<dynamic> values) {
    selectedFilters[columnName] = values; // Update the selected filters
    updateAvailableFilters(); // Update available filters based on selected filters
  }

  // Updates the available filters based on the selected filters
  void updateAvailableFilters() {
    availableFilters.clear(); // Clear existing available filters
    initializeAvailableFilters(elements);
    // Initialize available filters with all elements
    List<ExcelElement> filteredElements =
        List.from(elements); // Create a copy of all elements
    // Filter elements based on selected filters
    if (selectedFilters.isNotEmpty) {
      for (var key in selectedFilters.keys) {
        if (selectedFilters[key]!.isNotEmpty) {
          filteredElements = filteredElements.where((element) {
            return selectedFilters[key]!.contains(element.details[key]);
          }).toList(); // Keep only elements matching the selected filters
        }
      }
    }
    // Initialize available filters with filtered elements
    initializeAvailableFilters(filteredElements);
  }
}
