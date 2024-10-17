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
    final titlesProvider = ref.watch(columnTitlesProviderInstance);

    // Get the available column names for filtering
    final availableColumns =
        filtersProvider.filters.availableFilters.keys.toList();

    // Create an instance of ExcelExportController
    final excelExportController = ExcelExportController();

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Filtered Elements')),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              await excelExportController.exportToExcel(
                  filteredElements, titlesProvider);
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
                .value; // Osserva l'altezza dal provider

            return SizedBox(
              height: height, // Imposta l'altezza basata sul provider
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
}
