import 'package:flutter/material.dart';

class CategoryList extends StatelessWidget {
  final Map<String, List<String>> categoryItems;

  const CategoryList({Key? key, required this.categoryItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: categoryItems.length,
      itemBuilder: (context, index) {
        String category = categoryItems.keys.elementAt(index);
        List<String> items = categoryItems[category]!;
        
        return CategoryCard(category: category, items: items);
      },
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String category;
  final List<String> items;

  const CategoryCard({
    Key? key,
    required this.category,
    required this.items,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.category),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded) ...[
            for (var item in widget.items)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item),
              ),
          ],
        ],
      ),
    );
  }
}
