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
    value = newHeight.clamp(0.0, 90.0); // Mantieni l'altezza tra 0 e 90
  }
}

// Definisci il provider
final rowFiltersHeightProvider = ChangeNotifierProvider<RowFiltersHeight>(
  (ref) => RowFiltersHeight(90.0), // Altezza iniziale
);
