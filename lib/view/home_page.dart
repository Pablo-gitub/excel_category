import 'package:flutter/material.dart';
import 'package:exel_category/view/column_filter_card.dart';
import 'package:exel_category/view/insert_file.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/view/filter_details.dart';
import 'package:flutter_translate/flutter_translate.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<String>> selectedFilters = {}; // Filtri selezionati
  List<ExcelElement> elements = [];
  bool filtersApplied = false; // Traccia lo stato dei filtri

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Exceletor'),
        actions: [
          // IconButton per la lingua inglese
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
          // IconButton per la lingua italiana
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
          
          if (elements.isNotEmpty && filtersApplied)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                resetFilters(); // Resetta i filtri quando si clicca su "Refresh"
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
                  setState(() {
                    elements = loadedElements; // Carica gli elementi Excel
                    resetFilters(); // Resetta i filtri quando si carica un nuovo file
                  });
                },
              ),
            ),
            if (selectedFilters.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mostra i filtri selezionati per ogni colonna
                    Expanded(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: selectedFilters.entries.map((entry) {
                          return Chip(
                            label: Text(
                              '${entry.key}: ${entry.value.join(', ')}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () {
                              // Rimuove il filtro selezionato per una colonna specifica
                              setState(() {
                                selectedFilters.remove(entry.key);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    // Pulsante per resettare tutti i filtri
                    TextButton(
                      onPressed: resetFilters,
                      child: Text(translate('Reset All')),
                    ),
                  ],
                ),
              ),
            if (elements.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Mostra le carte per ogni colonna
                    for (var column in elements.first.details.keys)
                      ColumnFilterCard(
                        columnName: column,
                        loadedElements: elements,
                        onSelectionChanged: (columnName, selectedItems) {
                          setState(() {
                            selectedFilters[columnName] = selectedItems;
                          });
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      // BottomSheet con il pulsante "Filter"
      bottomSheet: elements.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Filtra gli elementi in base ai filtri selezionati
                  final filteredElements = elements.where((element) {
                    bool matchesAllFilters = true;
                    selectedFilters.forEach((columnName, selectedValues) {
                      if (!selectedValues
                          .contains(element.details[columnName]?.toString())) {
                        matchesAllFilters = false;
                      }
                    });
                    return matchesAllFilters;
                  }).toList();

                  // Verifica se ci sono filtri applicati
                  if (selectedFilters.isNotEmpty &&
                      filteredElements.isNotEmpty) {
                    setState(() {
                      filtersApplied =
                          true; // Imposta lo stato come "filtri applicati"
                    });

                    // Naviga alla pagina dei dettagli con gli elementi filtrati
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FilterDetails(
                          filteredVehicles: filteredElements,
                        ),
                      ),
                    );
                  } else {
                    // Mostra un messaggio se nessun filtro è stato applicato o nessun risultato è stato trovato
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translate('No results match the selected filters.')),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.black, // Colore dell'ombra
                  elevation: 5, // Livello di elevazione
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 12), // Padding interno
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(25), // Angoli arrotondati
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

  void resetFilters() {
    setState(() {
      selectedFilters.clear(); // Resetta i filtri selezionati
      filtersApplied = false; // Rimuove lo stato "filtri applicati"
    });
  }
}
