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
  final _iconController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    Provider.of<CategoryProvider>(context, listen: false).loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
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
            TextField(
              controller: _iconController,
              decoration: const InputDecoration(labelText: 'Emoji/Icone (ex: 🍔)'),
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
                if (_nameController.text.trim().isEmpty || _iconController.text.trim().isEmpty) return;
                final newCategory = Category(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _nameController.text.trim(),
                  icon: _iconController.text.trim(),
                  color: _selectedColor,
                  isCustom: true,
                );
                await categoryProvider.addCategory(newCategory);
                _nameController.clear();
                _iconController.clear();
                setState(() {
                  _selectedColor = Colors.blue;
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

// Nécessite d'ajouter flutter_colorpicker dans pubspec.yaml 