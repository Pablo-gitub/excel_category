import 'package:exel_category/provider/elements_provider.dart';
import 'package:exel_category/provider/row_filters_height_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsElement extends ConsumerWidget {
  final ScrollController scrollController;

  const DetailsElement({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredElements = ref.watch(elementsProviderInstance).filteredElements;
    final rowFiltersHeight = ref.watch(rowFiltersHeightProvider);
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels > 0) {
            // L'utente sta scrollando verso il basso
            rowFiltersHeight.updateHeight(90 - notification.metrics.pixels.clamp(0, 90));
          } else {
            // L'utente sta scrollando verso l'alto
            rowFiltersHeight.updateHeight(90);
          }
        }
        return true; // Continua la propagazione dell'evento
      },
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemCount: filteredElements.length,
        itemBuilder: (context, index) {
          var element = filteredElements[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: element.details.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value}');
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
