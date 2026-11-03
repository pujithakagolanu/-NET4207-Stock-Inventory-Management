import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/stock_item.dart';
import '../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

const List<String> kCategories = [
  'Electronics',
  'Stationery',
  'Hardware',
  'Grocery',
];

// ---------------------------------------------------------------------------
// StockForm widget
// ---------------------------------------------------------------------------

class StockForm extends StatefulWidget {
  const StockForm({super.key});

  @override
  State<StockForm> createState() => _StockFormState();
}

class _StockFormState extends State<StockForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers — preserved on failed save.
  final _skuController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _reorderLevelController = TextEditingController();

  String? _selectedCategory;
  bool _isSaving = false;

  // Holds a server-confirmed duplicate SKU error to show at field level.
  String? _skuServerError;

  @override
  void dispose() {
    _skuController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _reorderLevelController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validateSku(String? value) {
    if (value == null || value.trim().isEmpty) return 'SKU is required.';
    final regex = RegExp(r'^STK-[0-9]{3}$');
    if (!regex.hasMatch(value.trim())) {
      return 'SKU must match STK-000 format (e.g. STK-001).';
    }
    // Surface server-side duplicate error at field level.
    if (_skuServerError != null &&
        value.trim() == _skuServerError!.split('"')[1]) {
      return 'SKU "${value.trim()}" is already in use. Choose a different SKU.';
    }
    return null;
  }

  String? _validateItemName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Item name is required.';
    if (trimmed.length < 3) return 'Item name must be at least 3 characters.';
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) return 'Please select a category.';
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required.';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Quantity must be a whole number.';
    if (parsed < 0) return 'Quantity must be >= 0.';
    return null;
  }

  String? _validateUnitPrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Unit price is required.';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Unit price must be a valid number.';
    if (parsed <= 0) return 'Unit price must be > 0.';
    return null;
  }

  String? _validateReorderLevel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Reorder level is required.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Reorder level must be a whole number.';
    if (parsed < 0) return 'Reorder level must be >= 0.';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    // Clear any previous server-side SKU error before revalidating.
    setState(() => _skuServerError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final item = StockItem(
      id: '',
      sku: _skuController.text.trim(),
      itemName: _itemNameController.text.trim(),
      category: _selectedCategory!,
      quantity: int.parse(_quantityController.text.trim()),
      unitPrice: double.parse(_unitPriceController.text.trim()),
      reorderLevel: int.parse(_reorderLevelController.text.trim()),
    );

    try {
      await FirestoreService.instance.addStockItem(item);
      if (!mounted) return;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Stock item saved successfully.'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on DuplicateSkuException catch (e) {
      if (!mounted) return;
      // Duplicate SKU — show orange warning. Data is preserved for correction.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Generic Firestore or network error — data is preserved for retry.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Save failed: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _skuController.clear();
    _itemNameController.clear();
    _quantityController.clear();
    _unitPriceController.clear();
    _reorderLevelController.clear();
    setState(() => _selectedCategory = null);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(Icons.add_box_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add Stock Item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 1: SKU + Item Name
              _ResponsiveRow(
                children: [
                  _buildTextField(
                    controller: _skuController,
                    label: 'SKU',
                    hint: 'STK-001',
                    icon: Icons.qr_code,
                    validator: _validateSku,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-]')),
                      LengthLimitingTextInputFormatter(7),
                    ],
                  ),
                  _buildTextField(
                    controller: _itemNameController,
                    label: 'Item Name',
                    hint: 'e.g. USB-C Cable',
                    icon: Icons.label_outline,
                    validator: _validateItemName,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Category dropdown + Quantity
              _ResponsiveRow(
                children: [
                  _buildCategoryDropdown(colorScheme),
                  _buildTextField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hint: '0',
                    icon: Icons.inventory_rounded,
                    validator: _validateQuantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 3: Unit Price + Reorder Level
              _ResponsiveRow(
                children: [
                  _buildTextField(
                    controller: _unitPriceController,
                    label: 'Unit Price (RM)',
                    hint: '0.00',
                    icon: Icons.attach_money_rounded,
                    validator: _validateUnitPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  _buildTextField(
                    controller: _reorderLevelController,
                    label: 'Reorder Level',
                    hint: '10',
                    icon: Icons.warning_amber_rounded,
                    validator: _validateReorderLevel,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetForm,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? 'Saving…' : 'Save Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper builders
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildCategoryDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
      ),
      items: kCategories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
      validator: _validateCategory,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

// ---------------------------------------------------------------------------
// Responsive two-column row
// ---------------------------------------------------------------------------

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) {
      final rowChildren = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        if (i > 0) rowChildren.add(const SizedBox(width: 12));
        rowChildren.add(Expanded(child: children[i]));
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rowChildren,
      );
    }
    final colChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) colChildren.add(const SizedBox(height: 12));
      colChildren.add(SizedBox(width: double.infinity, child: children[i]));
    }
    return Column(children: colChildren);
  }
}
