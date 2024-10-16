import 'package:exel_category/provider/elements_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsElement extends ConsumerWidget {

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredElements = ref.watch(elementsProviderInstance).filteredElements;
    
    return ListView.builder(
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
    );
  }
}
