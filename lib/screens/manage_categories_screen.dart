import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_scanner_flutter/providers/category_provider.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ManageCategoriesScreen extends StatefulWidget {
  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    Provider.of<CategoryProvider>(context, listen: false).loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Gérer les catégories')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
            ),
            Row(
              children: [
                const Text('Icon :'),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () async {
                    final emoji = await showDialog<String>(
                      context: context,
                      builder: (context) => EmojiPickerDialog(selected: _selectedEmoji),
                    );
                    if (emoji != null) {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                    }
                  },
                  child: Text(
                    _selectedEmoji ?? '+',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Couleur :'),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Choisir une couleur'),
                        content: SingleChildScrollView(
                          child: BlockPicker(
                            pickerColor: _selectedColor,
                            onColorChanged: (color) {
                              Navigator.of(context).pop(color);
                            },
                          ),
                        ),
                      ),
                    );
                    if (color != null) {
                      setState(() {
                        _selectedColor = color;
                      });
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty || _selectedEmoji == null) return;
                final newCategory = Category(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text.trim(),
                  icon: _selectedEmoji!,
                  color: _selectedColor,
                  isCustom: true,
                );
                await categoryProvider.addCategory(newCategory);
                _nameController.clear();
                setState(() {
                  _selectedColor = Colors.blue;
                  _selectedEmoji = null;
                });
              },
              child: const Text('Ajouter la catégorie'),
            ),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: Text(cat.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(cat.name),
                    trailing: cat.isCustom
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await categoryProvider.deleteCategory(cat.id);
                            },
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiPickerDialog extends StatelessWidget {
  final String? selected;
  EmojiPickerDialog({this.selected});

  static const emojis = [
    '🛒', '🍽️', '🏠', '🚗', '🏥', '🎉', '👔', '🧾', '🛍️', '💡',
    '📚', '🏦', '🏖️', '🐾', '🧸', '🎁', '🛠️', '📱', '💻', '🏫'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choisir un emoji'),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis.map((e) => GestureDetector(
            onTap: () => Navigator.of(context).pop(e),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected == e ? Colors.blue.withOpacity(0.2) : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected == e ? Colors.blue : Colors.grey.shade300,
                  width: selected == e ? 2 : 1,
                ),
              ),
              child: Text(e, style: const TextStyle(fontSize: 28)),
            ),
          )).toList(),
        ),
      ),
    );
  }
}

// Nécessite d'ajouter flutter_colorpicker dans pubspec.yaml 