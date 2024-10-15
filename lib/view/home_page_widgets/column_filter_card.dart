import 'dart:math';

import 'package:exel_category/model/excel_element.dart';
import 'package:exel_category/provider/elements_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';
import 'package:flutter_translate/flutter_translate.dart';

class ColumnFilterCard extends ConsumerStatefulWidget {
  final String columnName;

  const ColumnFilterCard({
    Key? key,
    required this.columnName,
  }) : super(key: key);

  @override
  _ColumnFilterCardState createState() => _ColumnFilterCardState();
}

class _ColumnFilterCardState extends ConsumerState<ColumnFilterCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final elementsProvider = ref.watch(elementsProviderInstance);
    final filtersProvider = ref.watch(filtersProviderInstance);

    final uniqueItems =
        filtersProvider.filters.availableFilters[widget.columnName] ?? [];
    final selectedItems =
        filtersProvider.filters.selectedFilters[widget.columnName] ?? [];

    // Calculate percentages
    final percentages =
        _calculatePercentages(elementsProvider.filteredElements, uniqueItems);

    // Normalize percentages to ensure they sum to less than 1
    final totalPercentage =
        percentages.fold(0.0, (sum, element) => sum + element);
    final normalizedPercentages =
        percentages.map((p) => p / totalPercentage).toList();

    // Generate random colors for each percentage
    final colors = generateRandomColors(uniqueItems.length);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.columnName),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
            ),
          ),
          if (isExpanded)
            Column(
              children: [
                _buildBarChart(uniqueItems, normalizedPercentages, colors),
                for (var i = 0; i < uniqueItems.length; i++)
                  CheckboxListTile(
                    title: Text(uniqueItems[i].toString()),
                    value: selectedItems.contains(uniqueItems[i]),
                    onChanged: (bool? value) {
                      if (value == true) {
                        filtersProvider.addFilter(
                            widget.columnName, uniqueItems[i]);
                      } else {
                        filtersProvider.removeFilter(
                            widget.columnName, uniqueItems[i]);
                      }
                    },
                    subtitle: Text(
                      '${_countMatchingElements(elementsProvider.filteredElements, uniqueItems[i])} ${translate('items match')}',
                      style: TextStyle(
                          color: colors[i]), // Applica il colore qui
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  int _countMatchingElements(List<ExcelElement> elements, dynamic item) {
    // Conta il numero di elementi corrispondenti all'item selezionato
    return elements
        .where((element) => element.details[widget.columnName] == item)
        .length;
  }

  List<double> _calculatePercentages(
      List<ExcelElement> elements, List<dynamic> uniqueItems) {
    int totalElements = elements.length;
    return uniqueItems.map((item) {
      int count = _countMatchingElements(elements, item);
      return totalElements > 0 ? (count / totalElements) : 0.0;
    }).toList();
  }

  Widget _buildBarChart(
      List<dynamic> uniqueItems, List<double> percentages, List<Color> colors) {
    final totalWidth =
        MediaQuery.of(context).size.width - 32; // Adjust for card's margin

    // Limita il numero di elementi visualizzati
    const maxVisibleItems = 5;
    List<double> relevantPercentages;
    List<dynamic> relevantItems;
    List<Color> relevantColors;

    if (percentages.length > maxVisibleItems) {
      // Ordina gli elementi per percentuale (decrescente)
      final sortedIndexes = List<int>.generate(percentages.length, (i) => i)
        ..sort((a, b) => percentages[b].compareTo(percentages[a]));

      // Seleziona i primi maxVisibleItems
      relevantPercentages = sortedIndexes
          .take(maxVisibleItems)
          .map((index) => percentages[index])
          .toList();
      relevantItems = sortedIndexes
          .take(maxVisibleItems)
          .map((index) => uniqueItems[index])
          .toList();
      relevantColors = sortedIndexes
          .take(maxVisibleItems)
          .map((index) => colors[index])
          .toList();

      // Aggiungi una voce "Altri" per i rimanenti
      final othersPercentage = sortedIndexes
          .skip(maxVisibleItems)
          .map((index) => percentages[index])
          .fold(0.0, (sum, p) => sum + p);

      relevantPercentages.add(othersPercentage);
      relevantItems.add("Altri");
      relevantColors.add(Colors.grey); // Colore fisso per "Altri"
    } else {
      relevantPercentages = percentages;
      relevantItems = uniqueItems;
      relevantColors = colors;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: List.generate(relevantItems.length, (index) {
          double barWidth = (relevantPercentages[index] * totalWidth);

          return Flexible(
            flex: (relevantPercentages[index] * 100).toInt(),
            child: Container(
              height: 30,
              width: barWidth,
              margin: const EdgeInsets.only(right: 2.0),
              decoration: BoxDecoration(
                color: relevantColors[index],
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Color> generateRandomColors(int count) {
    final random = Random();
    return List<Color>.generate(count, (_) {
      return Color.fromARGB(
        255, // Full opacity
        random.nextInt(256), // Random value for R
        random.nextInt(256), // Random value for G
        random.nextInt(256), // Random value for B
      );
    });
  }
}
