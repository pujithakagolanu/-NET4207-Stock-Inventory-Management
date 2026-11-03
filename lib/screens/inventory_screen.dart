import 'package:flutter/material.dart';
import '../models/stock_item.dart';
import '../services/firestore_service.dart';
import '../widgets/stock_form.dart';

// Sort options
enum SortOrder { quantityAsc, quantityDesc }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedCategory;
  bool _lowStockOnly = false;
  SortOrder _sortOrder = SortOrder.quantityAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Filtering & sorting (in-Flutter)
  // ---------------------------------------------------------------------------

  List<StockItem> _applyFilters(List<StockItem> all) {
    final query = _searchQuery.toLowerCase().trim();

    var result = all.where((item) {
      // Search: case-insensitive partial match on itemName OR sku
      final matchesSearch = query.isEmpty ||
          item.itemName.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query);

      // Category filter
      final matchesCategory =
          _selectedCategory == null || item.category == _selectedCategory;

      // Low-stock filter
      final matchesLowStock = !_lowStockOnly || item.isLowStock;

      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();

    // Sort
    result.sort((a, b) => _sortOrder == SortOrder.quantityAsc
        ? a.quantity.compareTo(b.quantity)
        : b.quantity.compareTo(a.quantity));

    return result;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _lowStockOnly = false;
      _sortOrder = SortOrder.quantityAsc;
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _lowStockOnly ||
      _sortOrder != SortOrder.quantityAsc;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          // ── App header ──
          SliverAppBar(
            expandedHeight: 110,
            floating: true,
            snap: true,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_rounded,
                      color: colorScheme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Stock Inventory Manager',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ],
              ),
              centerTitle: false,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stock entry form ──
                  const StockForm(),
                  const SizedBox(height: 20),

                  // ── Filter panel ──
                  _FilterPanel(
                    searchController: _searchController,
                    selectedCategory: _selectedCategory,
                    lowStockOnly: _lowStockOnly,
                    sortOrder: _sortOrder,
                    hasActiveFilters: _hasActiveFilters,
                    onSearchChanged: (v) =>
                        setState(() => _searchQuery = v),
                    onCategoryChanged: (v) =>
                        setState(() => _selectedCategory = v),
                    onLowStockChanged: (v) =>
                        setState(() => _lowStockOnly = v ?? false),
                    onSortChanged: (v) =>
                        setState(() => _sortOrder = v ?? SortOrder.quantityAsc),
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Inventory list (stream) ──
          StreamBuilder<List<StockItem>>(
            stream: FirestoreService.instance.stockItemsStream(),
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              // Error
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: _ErrorState(message: snapshot.error.toString()),
                );
              }

              final allItems = snapshot.data ?? [];
              final filtered = _applyFilters(allItems);

              // ── Result count header ──
              return SliverMainAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            'Showing ${filtered.length} of ${allItems.length} items',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                          ),
                          if (_lowStockOnly) ...[
                            const SizedBox(width: 8),
                            _MiniChip(
                              label:
                                  '${allItems.where((i) => i.isLowStock).length} low-stock',
                              color: colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── Empty state ──
                  if (filtered.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyListState(),
                    )
                  else
                    // ── Item cards ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _StockItemCardWrapper(item: filtered[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter panel widget
// ---------------------------------------------------------------------------

class _FilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedCategory;
  final bool lowStockOnly;
  final SortOrder sortOrder;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<bool?> onLowStockChanged;
  final ValueChanged<SortOrder?> onSortChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.searchController,
    required this.selectedCategory,
    required this.lowStockOnly,
    required this.sortOrder,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onLowStockChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.filter_list_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Search & Filter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (hasActiveFilters)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                        foregroundColor: colorScheme.error),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Search field
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or SKU…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true,
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),

            // Category dropdown + Sort dropdown
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(12))),
                      filled: true,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All categories')),
                      ...kCategories.map((c) =>
                          DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: onCategoryChanged,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<SortOrder>(
                    // ignore: deprecated_member_use
                    value: sortOrder,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort by Quantity',
                      prefixIcon: Icon(Icons.sort_rounded),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(12))),
                      filled: true,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: SortOrder.quantityAsc,
                        child: Text('Quantity: Low → High'),
                      ),
                      DropdownMenuItem(
                        value: SortOrder.quantityDesc,
                        child: Text('Quantity: High → Low'),
                      ),
                    ],
                    onChanged: onSortChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Low-stock toggle
            CheckboxListTile(
              value: lowStockOnly,
              onChanged: onLowStockChanged,
              title: const Text('Show low-stock items only'),
              secondary:
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single item card wrapper — renders one card without a ListView wrapper
// ---------------------------------------------------------------------------

class _StockItemCardWrapper extends StatelessWidget {
  final StockItem item;
  const _StockItemCardWrapper({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = item.isLowStock;

    final cardColor =
        isLow ? colorScheme.errorContainer : colorScheme.surfaceContainerLow;

    return Card(
      color: cardColor,
      elevation: isLow ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isLow
            ? BorderSide(color: colorScheme.error, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: SKU + name + low-stock badge
            Row(
              children: [
                _ItemPill(
                  label: item.sku,
                  color: isLow ? colorScheme.error : colorScheme.primary,
                  textColor:
                      isLow ? colorScheme.onError : colorScheme.onPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.itemName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLow)
                  _ItemChip(
                    label: 'LOW STOCK',
                    color: colorScheme.error,
                    textColor: colorScheme.onError,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Category chip
            _ItemChip(
              label: item.category,
              color: colorScheme.secondaryContainer,
              textColor: colorScheme.onSecondaryContainer,
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 10),

            // Stats
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _ItemStat(
                  label: 'Quantity',
                  value: item.quantity.toString(),
                  icon: Icons.inventory_rounded,
                  highlight: isLow,
                  colorScheme: colorScheme,
                ),
                _ItemStat(
                  label: 'Unit Price',
                  value: 'RM ${item.unitPrice.toStringAsFixed(2)}',
                  icon: Icons.attach_money_rounded,
                  colorScheme: colorScheme,
                ),
                _ItemStat(
                  label: 'Reorder Level',
                  value: item.reorderLevel.toString(),
                  icon: Icons.refresh_rounded,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _ItemPill(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8)),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  const _ItemChip(
      {required this.label,
      required this.color,
      required this.textColor,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ],
      ),
    );
  }
}

class _ItemStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final ColorScheme colorScheme;
  const _ItemStat(
      {required this.label,
      required this.value,
      required this.icon,
      this.highlight = false,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final textColor =
        highlight ? colorScheme.error : colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: textColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: colorScheme.outline)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty list state (shown inside SliverFillRemaining)
// ---------------------------------------------------------------------------

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 72, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Add stock items using the form above\nor adjust your filters.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Failed to load inventory',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: colorScheme.error)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini chip (used for result count label)
// ---------------------------------------------------------------------------

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
