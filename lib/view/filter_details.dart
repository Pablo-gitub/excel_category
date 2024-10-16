import 'dart:io';

import 'package:excel/excel.dart';
import 'package:exel_category/provider/column_titles_provider.dart';
import 'package:exel_category/view/filter_details_widgets/details_element.dart';
import 'package:exel_category/view/filter_details_widgets/row_filters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';


class FilterDetails extends ConsumerWidget {
  final List<ExcelElement> filteredElements;

  const FilterDetails({super.key, required this.filteredElements});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider = ref.watch(filtersProviderInstance);
    final titlesProvider = ref.watch(columnTitlesProviderInstance);
    
    // Get the available column names for filtering
    final availableColumns = filtersProvider.filters.availableFilters.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Filtered Elements')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              await exportToExcel(filteredElements, titlesProvider);
            },
            tooltip: 'Esporta in Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal scroll for filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
            child: Row(
              children: availableColumns.map((columnName) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add spacing between filters
                  child: RowFilters(columnName: columnName), // Your RowFilters widget
                );
              }).toList(),
            ),
          ),
          // Provide some spacing below the filters
          const SizedBox(height: 16.0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DetailsElement(),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> exportToExcel(List<ExcelElement> filteredElements, ColumnTitlesProvider titlesProvider) async {
  // Create a new Excel file
  var excel = Excel.createExcel(); // Create a new Excel instance
  Sheet sheet = excel['Filtered Data']; // Create a new sheet

  // Define headers based on your data model
  List<dynamic> headers = filteredElements.first.details.keys.toList();

  List<dynamic> originalTitles = titlesProvider.originalTitles;
  
  // Add headers to the sheet
  for (var i = 0; i < originalTitles.length; i++) {
    var cell = sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + i)}1')); // A1, B1, C1, etc.
    cell.value = originalTitles[i]; // Set the header value
  }

  // Add data to the sheet
  for (var rowIndex = 0; rowIndex < filteredElements.length; rowIndex++) {
    var element = filteredElements[rowIndex];
    for (var colIndex = 0; colIndex < headers.length; colIndex++) {
      var cell = sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + colIndex)}${rowIndex + 2}')); // A2, B2, C2, etc.
      cell.value = element.details[headers[colIndex]]; // Set cell value from the element
    }
  }

  // Add data to the sheet
  for (var rowIndex = 0; rowIndex < filteredElements.length; rowIndex++) {
    var element = filteredElements[rowIndex];
    for (var colIndex = 0; colIndex < headers.length; colIndex++) {
      var cell = sheet.cell(CellIndex.indexByString('${String.fromCharCode(65 + colIndex)}${rowIndex + 2}')); // A2, B2, C2, etc.
      cell.value = element.details[headers[colIndex]]; // Set cell value from the element
    }
  }

  // Determine the platform and get the appropriate directory to save the file
  String path;

  if (kIsWeb) {
    // Handle web platform: Generate a downloadable link
    // Note: You may need to implement a method to export the Excel file as a Blob and download it
    // This will require using `html` package to trigger downloads
    // Example:
    // final excelBytes = excel.save();
    // final blob = html.Blob([excelBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    // final url = html.Url.createObjectUrlFromBlob(blob);
    // final anchor = html.AnchorElement(href: url)
    //   ..setAttribute('download', 'filtered_data.xlsx')
    //   ..click();
    // html.Url.revokeObjectUrl(url);
    return; // Temporarily return to avoid execution
  } else if (Platform.isAndroid || Platform.isIOS) {
    // Mobile platforms
    Directory directory = await getApplicationDocumentsDirectory();
    path = join(directory.path, 'filtered_data.xlsx');
  } else {
    // For desktop platforms (Windows, macOS, Linux)
    Directory directory = await getApplicationDocumentsDirectory();
    path = join(directory.path, 'filtered_data.xlsx');
  }

  // Save the file
  var fileBytes = excel.save();
  File(path)..createSync(recursive: true)..writeAsBytesSync(fileBytes!);

  // Optionally, show a snackbar or dialog indicating the file has been saved
  print('Excel file saved at: $path');
}

}

