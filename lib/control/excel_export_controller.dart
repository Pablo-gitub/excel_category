import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:exel_category/provider/column_titles_provider.dart';
import 'package:exel_category/provider/elements_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;

class ExcelExportController {
  Future<void> exportToExcel(
      ColumnTitlesProvider titlesProvider, WidgetRef ref) async {
    final filteredElements =
        ref.watch(elementsProviderInstance).filteredElements;
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
      const String fileName = 'filtered_data';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: excelData,
        ext: 'xlsx',
        mimeType: MimeType.other,
      );
    } else {
      // Mobile platforms: Use File Picker to save the file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/filtered_data.xlsx';
      final file = await io.File(filePath).writeAsBytes(fileBytes!);

      // Usa share_plus per condividere o salvare il file
      await Share.shareXFiles(
        [XFile(file.path)],
      );
    }
  }

  Future<void> exportToPdf(
      ColumnTitlesProvider titlesProvider, WidgetRef ref) async {
    // Create a new PDF document
    final filteredElements =
        ref.watch(elementsProviderInstance).filteredElements;

    final pdf = pw.Document();

    // Define headers based on your data model
    List<dynamic> headers = titlesProvider.originalTitles;

    // Prepare data for the PDF table
    List<List<String>> data = [];
    for (var element in filteredElements) {
      List<String> row = [];
      element.details.forEach((key, value) {
        row.add(value.toString());
      });
      data.add(row);
    }

    // Maximum number of rows per page (adjust as needed)
    const int rowsPerPage = 12;
    final int totalRows = data.length;

    // Add pages with tables to the PDF document
    for (int startRow = 0; startRow < totalRows; startRow += rowsPerPage) {
      final endRow = (startRow + rowsPerPage < totalRows)
          ? startRow + rowsPerPage
          : totalRows;

      // Create a page for the current set of rows
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Add headers
                    pw.TableRow(
                      children: headers
                          .map((header) => pw.Padding(
                                padding: const pw.EdgeInsets.all(3.0),
                                child: pw.Text(
                                  header.toString(),
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ))
                          .toList(),
                    ),
                    // Add rows for the current page
                    for (var rowIndex = startRow; rowIndex < endRow; rowIndex++)
                      pw.TableRow(
                        children: data[rowIndex]
                            .map((cell) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(3.0),
                                  child: pw.Text(cell),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // Save the PDF document
    final output = await pdf.save();

    if (kIsWeb) {
      // Web specific saving logic
      await FileSaver.instance.saveFile(
        name: 'filtered_data',
        bytes: output,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    } else {
      // Mobile specific saving logic
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/filtered_data.pdf';
      final file = await io.File(filePath).writeAsBytes(output);

      // Share or save the file
      await Share.shareXFiles(
        [XFile(file.path)],
      );
    }
  }
}
