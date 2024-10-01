import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';

class ColumnFilterCard extends StatefulWidget {
  final String columnName;
  final List<ExcelElement> loadedElements;
  final Function(String, List<String>) onSelectionChanged; // Funzione callback per comunicare i valori selezionati

  const ColumnFilterCard({
    Key? key,
    required this.columnName,
    required this.loadedElements,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  _ColumnFilterCardState createState() => _ColumnFilterCardState();
}

class _ColumnFilterCardState extends State<ColumnFilterCard> {
  List<String> selectedItems = []; // Per tenere traccia degli elementi selezionati

  @override
  Widget build(BuildContext context) {
    // Estrai i valori unici per la colonna specificata
    final uniqueItems = widget.loadedElements
        .map((element) => element.details[widget.columnName]?.toString())
        .toSet() // Usa un Set per ottenere valori unici
        .where((value) => value != null) // Filtra i valori null
        .cast<String>() // Cast al tipo String
        .toList();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(widget.columnName),
        children: [
          // Mostra le checkbox per i valori unici
          for (var item in uniqueItems)
            CheckboxListTile(
              title: Text(item),
              value: selectedItems.contains(item),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                  widget.onSelectionChanged(widget.columnName, selectedItems); // Comunica i valori selezionati
                });
              },
            ),
        ],
      ),
    );
  }
}
