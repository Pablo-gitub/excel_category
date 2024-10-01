import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';

class FilterDetails extends StatelessWidget {
  final List<ExcelElement> filteredVehicles;

  const FilterDetails({super.key, required this.filteredVehicles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtered Vehicle Details'),
      ),
      body: ListView.builder(
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          var element = filteredVehicles[index];
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
