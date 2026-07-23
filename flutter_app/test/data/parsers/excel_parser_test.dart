import 'dart:io';

import 'package:exlser/data/adapters/parsers/excel_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExcelParser', () {
    late ExcelParser parser;

    setUp(() {
      parser = ExcelParser();
    });

    test(
      'should correctly parse a simple excel file',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/simple.xlsx',
        );

        expect(sheets.length, 1);

        final sheet = sheets.first;

        expect(sheet.name, 'Foglio1');

        expect(sheet.rows.length, 6);

        expect(sheet.rows.first['product'], 'book');
        expect(sheet.rows.first['price'], '10');
        expect(sheet.rows.first['quantity'], '20');
        expect(sheet.rows.first['brand'], 'mondadori');
      },
    );

    test(
      'should correctly parse excel bytes',
      () async {
        final bytes =
            await File('test/fixtures/excel/simple.xlsx').readAsBytes();

        final sheets = await parser.parseBytes(bytes);

        expect(sheets.length, 1);
        expect(sheets.first.name, 'Foglio1');
        expect(sheets.first.rows.length, 6);
        expect(sheets.first.rows.first['product'], 'book');
      },
    );

    test(
      'should correctly preserve column names',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/simple.xlsx',
        );

        final firstRow = sheets.first.rows.first;

        expect(firstRow.keys.contains('product'), true);
        expect(firstRow.keys.contains('price'), true);
        expect(firstRow.keys.contains('quantity'), true);
        expect(firstRow.keys.contains('brand'), true);
      },
    );

    test(
      'should correctly parse multiple sheets',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/multi_sheet.xlsx',
        );

        expect(sheets.length, 3);

        expect(sheets[0].rows.isNotEmpty, true);
        expect(sheets[1].rows.isNotEmpty, true);
        expect(sheets[2].rows.isNotEmpty, true);
      },
    );

    test(
      'should parse absolute workbook relationship targets',
      () async {
        final bytes = await File(
          'test/fixtures/excel/absolute_relationship_targets.xlsx',
        ).readAsBytes();
        final sheets = await parser.parseBytes(bytes);

        expect(
          sheets.map((sheet) => sheet.name),
          ['Sales', 'Products', 'Regions'],
        );
        expect(sheets.first.rows, hasLength(6));
      },
    );

    test(
      'should preserve sheet names',
      () async {
        final sheets = await parser.parsePath(
          'test/fixtures/excel/multi_sheet.xlsx',
        );

        expect(sheets[0].name, 'Foglio1');
        expect(sheets[1].name, 'Foglio2');
        expect(sheets[2].name, 'Foglio3');
      },
    );

    test(
      'should throw when excel file is empty',
      () async {
        expect(
          () => parser.parsePath(
            'test/fixtures/excel/empty.xlsx',
          ),
          throwsException,
        );
      },
    );

    test(
      'should throw when excel file does not exist',
      () async {
        expect(
          () => parser.parsePath(
            'test/fixtures/excel/not_existing.xlsx',
          ),
          throwsException,
        );
      },
    );
  });
}
