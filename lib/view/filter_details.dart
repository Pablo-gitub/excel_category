import 'package:exel_category/control/excel_export_controller.dart';
import 'package:exel_category/provider/column_titles_provider.dart';
import 'package:exel_category/provider/row_filters_height_provider.dart';
import 'package:exel_category/view/filter_details_widgets/details_element.dart';
import 'package:exel_category/view/filter_details_widgets/row_filters.dart';
import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';

class FilterDetails extends ConsumerWidget {
  final List<ExcelElement> filteredElements;
  final ScrollController _scrollController = ScrollController();

  FilterDetails({super.key, required this.filteredElements});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider = ref.watch(filtersProviderInstance);

    // Get the available column names for filtering
    final availableColumns =
        filtersProvider.filters.availableFilters.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Filtered Elements')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              _showExportOptions(context, ref); // Show popup
            },
            tooltip: 'Esporta in Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal scroll for filters
          Consumer(builder: (context, ref, child) {
            final height = ref
                .watch(rowFiltersHeightProvider)
                .value; // watch height from provider

            return SizedBox(
              height: height, // Personalize height based on provider
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                child: Row(
                  children: availableColumns.map((columnName) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0), // Add spacing between filters
                      child: RowFilters(
                          columnName: columnName), // Your RowFilters widget
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DetailsElement(scrollController: _scrollController),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    final titlesProvider = ref.watch(columnTitlesProviderInstance);
    // Create an instance of ExcelExportController
    final excelExportController = ExcelExportController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text(translate('FormatSelection')),
          content:  Text(translate('HowDownload')),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await excelExportController.exportToExcel(
                    titlesProvider, ref);
              },
              child: Text(translate('ExcelExport')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); //  Close dialog
                await excelExportController.exportToPdf(
                    titlesProvider, ref);
              },
              child: Text(translate('ExportPDF')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); //  Close dialog
              },
              child: Text(translate('cancel')),
            ),
          ],
        );
      },
    );
  }
}
