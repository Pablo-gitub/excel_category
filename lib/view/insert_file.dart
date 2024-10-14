// Import for mobile file handling
import 'package:excel/excel.dart';
import 'package:exel_category/control/file_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:exel_category/model/excel_element.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class InsertFile extends StatefulWidget {
  final Function(Map<String, List<String>>, List<ExcelElement>) onFileLoaded;

  const InsertFile({super.key, required this.onFileLoaded});

  @override
  State<InsertFile> createState() => _InsertFileState();
}

class _InsertFileState extends State<InsertFile> {
  final FileController fileController = FileController();
  String? fileName;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    translate('Insert File Here:'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          fileName ?? translate('No file selected'),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();

                          if (result != null && result.files.isNotEmpty) {
                            if (await fileController.isValidExcelFile(result.files.single.name)) {
                              setState(() {
                                fileName = result.files.single.name;
                              });
                              Excel file;
                              if (kIsWeb) {
                                file = await fileController.loadExcelFileFromBytes(result.files.single.bytes!);
                              } else {
                                file = await fileController.loadExcelFileFromPath(result.files.single.path!);
                              }
                              Map<String, List<String>> columnItems = await fileController.processExcelFile(file, ref);
                              widget.onFileLoaded(columnItems, []);
                            } else {
                              _showInvalidFileDialog(context);
                            }
                          }
                        },
                        child: Text(translate('Select File')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  void _showInvalidFileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(translate('Invalid File')),
          content: Text(translate('Invalid File Selection')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(translate('OK')),
            ),
          ],
        );
      },
    );
  }
}
