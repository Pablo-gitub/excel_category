import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/provider/column_titles_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';

class ExcelExportController {
  Future<void> exportToExcel(
      List<ExcelElement> filteredElements,
      ColumnTitlesProvider titlesProvider) async {
    // Create a new Excel file
    var excel = Excel.createExcel(); // Create a new Excel instance
    Sheet sheet = excel['Filtered Data']; // Create a new sheet

    // Define headers based on your data model
    List<dynamic> headers = filteredElements.first.details.keys.toList();
    List<dynamic> originalTitles = titlesProvider.originalTitles;

    // Add headers to the sheet
    for (var i = 0; i < originalTitles.length; i++) {
      var cell = sheet.cell(CellIndex.indexByString(
          '${String.fromCharCode(65 + i)}1')); // A1, B1, C1, etc.
      cell.value = originalTitles[i]; // Set the header value
    }

    // Add data to the sheet
    for (var rowIndex = 0; rowIndex < filteredElements.length; rowIndex++) {
      var element = filteredElements[rowIndex];
      for (var colIndex = 0; colIndex < headers.length; colIndex++) {
        var cell = sheet.cell(CellIndex.indexByString(
            '${String.fromCharCode(65 + colIndex)}${rowIndex + 2}')); // A2, B2, C2, etc.
        cell.value = element.details[headers[colIndex]]; // Set cell value
      }
    }

    // Get the bytes of the file
    var fileBytes = excel.save();

    if (kIsWeb) {
      // Web specific code for file saving
      final Uint8List excelData = Uint8List.fromList(fileBytes!);
      final String fileName = 'filtered_data.xlsx';

      // Save the file using FileSaver
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: excelData,
        ext: 'xlsx',
        mimeType: MimeType.other,
      );

      print('File saved successfully on web.');
    } else {
      // Mobile platforms: Use File Picker to save the file
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: 'filtered_data.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (filePath != null) {
        io.File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes!);
        print('Excel file saved at: $filePath');
      } else {
        print('File save operation was cancelled.');
      }
    }
  }
}
