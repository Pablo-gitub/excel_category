import 'dart:io' show File; // Import for mobile file handling
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:exel_category/provider/filters_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    return Consumer(
      builder: (context, ref, child) => Center(
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
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
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();

                          if (result != null && result.files.isNotEmpty) {
                            setState(() {
                              fileName = result.files.single.name;
                            });

                            // Check if we are on the web or mobile
                            if (kIsWeb) {
                              // For web, use bytes
                              await loadExcelFileFromBytes(result.files.single.bytes!, ref);
                            } else {
                              // For mobile, use path
                              await loadExcelFileFromPath(result.files.single.path!, ref);
                            }
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
      ),
    );
  }

  Future<void> loadExcelFileFromBytes(Uint8List bytes, WidgetRef ref) async {
    // Decode the Excel file from bytes
    var file = Excel.decodeBytes(bytes);
    await processExcelFile(file, ref);
  }

  Future<void> loadExcelFileFromPath(String path, WidgetRef ref) async {
    // Decode the Excel file from the file path
    var file = Excel.decodeBytes(await File(path).readAsBytes());
    await processExcelFile(file, ref);
  }

  Future<void> processExcelFile(Excel file, WidgetRef ref) async {
    List<ExcelElement> elements = [];
    Map<String, List<String>> columnItems = {}; // To save column items

    for (var table in file.tables.keys) {
      var headerRow = file.tables[table]?.rows[0];

      // Save column titles in a list
      List<String> columnTitles =
          headerRow?.map((cell) => cell?.value?.toString() ?? '').toList() ??
              [];

      // Start iterating over rows after the header
      for (var row in file.tables[table]!.rows.skip(1)) {
        if (row.isNotEmpty) {
          Map<String, dynamic> rowDetails = {};

          // Populate the Map using column titles as keys
          for (var i = 0; i < row.length; i++) {
            if (i < columnTitles.length) {
              rowDetails[columnTitles[i]] =
                  row[i]?.value; // Associate cell value with key
              columnItems
                  .putIfAbsent(columnTitles[i], () => [])
                  .add(row[i]?.value.toString() ?? '');
            }
          }

          elements.add(ExcelElement(details: rowDetails));
        }
      }
    }

    // Initialize Filters with the loaded elements and update the provider
    ref.read(filtersProviderInstance).updateFilters(elements);

    // Pass the data to the parent widget
    widget.onFileLoaded(columnItems, elements);
  }
}
