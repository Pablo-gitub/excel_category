import 'dart:typed_data';
import 'dart:io' show File;
import 'package:excel/excel.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';

class FileController {
  Future<bool> isValidExcelFile(String name) async {
    return name.endsWith('.xls') || name.endsWith('.xlsx');
  }

  Future<Excel> loadExcelFileFromBytes(Uint8List bytes) async {
    return Excel.decodeBytes(bytes);
  }

  Future<Excel> loadExcelFileFromPath(String path) async {
    return Excel.decodeBytes(await File(path).readAsBytes());
  }

  Future<Map<String, List<String>>> processExcelFile(Excel file, WidgetRef ref) async {
    List<ExcelElement> elements = [];
    Map<String, List<String>> columnItems = {};

    for (var table in file.tables.keys) {
      var headerRow = file.tables[table]?.rows[0];
      List<String> columnTitles =
          headerRow?.map((cell) => cell?.value?.toString() ?? '').toList() ??
          [];

      for (var row in file.tables[table]!.rows.skip(1)) {
        if (row.isNotEmpty) {
          Map<String, dynamic> rowDetails = {};
          for (var i = 0; i < row.length; i++) {
            if (i < columnTitles.length) {
              rowDetails[columnTitles[i]] = row[i]?.value;
              columnItems
                  .putIfAbsent(columnTitles[i], () => [])
                  .add(row[i]?.value.toString() ?? '');
            }
          }
          elements.add(ExcelElement(details: rowDetails));
        }
      }
    }

    // Update the filters provider
    ref.read(filtersProviderInstance).updateFilters(elements);

    return columnItems;
  }
}
