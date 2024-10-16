import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColumnTitlesProvider {
  final List<dynamic> originalTitles;

  ColumnTitlesProvider(this.originalTitles);
}

final columnTitlesProviderInstance = Provider<ColumnTitlesProvider>((ref) {
  return ColumnTitlesProvider([]);
});
