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
    // Recuperiamo gli elementi filtrati in base ai filtri selezionati
    if (filters.selectedFilters.isEmpty) {
      // Restituiamo tutti gli elementi se non ci sono filtri selezionati
      return filters.elements;
    }
    
    // Applichiamo i filtri agli elementi
    return filters.elements.where((element) {
      return filters.selectedFilters.entries.every((filterEntry) {
        final columnName = filterEntry.key;
        final selectedValues = filterEntry.value;
        // Verifichiamo che l'elemento corrisponda a tutti i filtri selezionati
        return selectedValues.contains(element.details[columnName]);
      });
    }).toList();
  }
}
