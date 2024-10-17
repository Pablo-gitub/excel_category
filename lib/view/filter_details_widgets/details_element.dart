import 'package:exel_category/provider/elements_provider.dart';
import 'package:exel_category/provider/row_filters_height_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailsElement extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const DetailsElement({super.key, required this.scrollController});

  @override
  // ignore: library_private_types_in_public_api
  _DetailsElementState createState() => _DetailsElementState();
}

class _DetailsElementState extends ConsumerState<DetailsElement> {
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (widget.scrollController.offset > 100) {
      if (!_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = true;
        });
      }
    } else {
      if (_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = false;
        });
      }
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredElements = ref.watch(elementsProviderInstance).filteredElements;
    final rowFiltersHeight = ref.watch(rowFiltersHeightProvider);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.pixels > 0) {
                rowFiltersHeight.updateHeight(90 - notification.metrics.pixels.clamp(0, 90));
              } else {
                rowFiltersHeight.updateHeight(90);
              }
            }
            return true;
          },
          child: ListView.builder(
            controller: widget.scrollController,
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
        ),
        if (_showScrollToTopButton)
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              backgroundColor: Colors.white70,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            ),
          ),
      ],
    );
  }
}
