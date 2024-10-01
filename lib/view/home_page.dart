import 'package:flutter/material.dart';
import 'package:exel_category/view/column_filter_card.dart';
import 'package:exel_category/view/insert_file.dart';
import 'package:exel_category/model/element.dart';
import 'package:exel_category/view/filter_details.dart'; // Importa la tua pagina di dettagli

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, List<String>> categoryItems = {};
  List<ExcelElement> elements = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Exceletor'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InsertFile(
                onFileLoaded: (Map<String, List<String>> columnItems, List<ExcelElement> loadedElements) {
                  setState(() {
                    categoryItems = columnItems;
                    elements = loadedElements;
                  });
                },
              ),
            ),
            if (categoryItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Mostra le carte per ogni colonna
                    for (var column in categoryItems.keys)
                      ColumnFilterCard(
                        columnName: column,
                        loadedElements: elements, // Passa gli elementi caricati
                        onFilterApplied: (filteredElements) {
                          // Naviga alla pagina dei dettagli con gli elementi filtrati
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilterDetails(
                                filteredVehicles: filteredElements, // Passa gli elementi filtrati
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
