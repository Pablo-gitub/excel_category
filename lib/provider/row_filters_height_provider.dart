import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider per l'altezza di RowFilters
class RowFiltersHeight extends ValueNotifier<double> {
  RowFiltersHeight(double height) : super(height);

  // Method to set height when expanded or collapsed
  void setHeight(bool isExpanded) {
    value = isExpanded ? 200.0 : 90.0; // Set height based on expansion state
  }

  void updateHeight(double newHeight) {
    value = newHeight.clamp(0.0, 90.0); // kepp height between 0 and 90
  }
}

// Define the provider
final rowFiltersHeightProvider = ChangeNotifierProvider<RowFiltersHeight>(
  (ref) => RowFiltersHeight(90.0), // start height
);
