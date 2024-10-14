import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exel_category/provider/filters_provider.dart';

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
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final filtersProvider = ref.watch(filtersProviderInstance);

    final uniqueItems = filtersProvider.filters.availableFilters[widget.columnName] ?? [];
    final selectedItems = filtersProvider.filters.selectedFilters[widget.columnName] ?? [];

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
                for (var item in uniqueItems)
                  CheckboxListTile(
                    title: Text(item.toString()),
                    value: selectedItems.contains(item),
                    onChanged: (bool? value) {
                      if (value == true) {
                        filtersProvider.addFilter(widget.columnName, item);
                      } else {
                        filtersProvider.removeFilter(widget.columnName, item);
                      }
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
