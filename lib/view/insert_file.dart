import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_translate/flutter_translate.dart';

class InsertFile extends StatefulWidget {
  final Function(Map<String, List<String>>, List<ExcelElement>) onFileLoaded;

  const InsertFile({super.key, required this.onFileLoaded});

  @override
  State<InsertFile> createState() => _InsertFileState();
}

class _InsertFileState extends State<InsertFile> {
  String? fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translate('Insert File Here:'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        fileName ?? translate('No file selected'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform.pickFiles();

                        if (result != null) {
                          setState(() {
                            fileName = result.files.single.name;
                          });
                          await loadExcelFile(result.files.single.path!);
                        }
                      },
                      child: Text(translate('Select File')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadExcelFile(String path) async {
    var file = Excel.decodeBytes(await File(path).readAsBytes());
    List<ExcelElement> elements = [];
    Map<String, List<String>> columnItems = {}; // Per salvare gli oggetti per le colonne

    for (var table in file.tables.keys) {
      // Assumiamo che la prima riga contenga i titoli delle colonne
      var headerRow = file.tables[table]?.rows[0];

      // Salva i titoli delle colonne in una lista
      List<String> columnTitles =
          headerRow?.map((cell) => cell?.value?.toString() ?? '').toList() ?? [];

      // Inizia a iterare sulle righe dopo la prima
      for (var row in file.tables[table]!.rows.skip(1)) {
        // Salta la prima riga
        if (row.isNotEmpty) {
          Map<String, dynamic> rowDetails = {};

          // Popola il Map utilizzando i titoli delle colonne come chiavi
          for (var i = 0; i < row.length; i++) {
            if (i < columnTitles.length) {
              rowDetails[columnTitles[i]] =
                  row[i]?.value; // Associa il valore della cella alla chiave
              // Aggiungi il valore alla mappa di colonne
              columnItems.putIfAbsent(columnTitles[i], () => []).add(row[i]?.value.toString() ?? '');
            }
          }

          elements.add(ExcelElement(details: rowDetails));
        }
      }
    }

    // Passa i dati al widget genitore
    widget.onFileLoaded(columnItems, elements);
  }
}
