import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/provider/column_titles_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportController {
  Future<void> exportToExcel(List<ExcelElement> filteredElements,
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
    excel.delete('Sheet1');

    // Get the bytes of the file
    var fileBytes = excel.save();

    if (kIsWeb) {
      // Web specific code for file saving
      final Uint8List excelData = Uint8List.fromList(fileBytes!);
      const String fileName = 'filtered_data.xlsx';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: excelData,
        ext: 'xlsx',
        mimeType: MimeType.other,
      );
      print('File salvato con successo su web.');
    } else {
      // Mobile platforms: Use File Picker to save the file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/filtered_data.xlsx';
      final file = await io.File(filePath).writeAsBytes(fileBytes!);

      // Usa share_plus per condividere o salvare il file
      await Share.shareXFiles(
        [XFile(file.path)],
      );
      print('Pannello di condivisione aperto.');
    }
  }
}
