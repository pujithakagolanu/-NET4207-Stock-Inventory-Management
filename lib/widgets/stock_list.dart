import 'package:flutter/material.dart';
import '../models/stock_item.dart';

class StockList extends StatelessWidget {
  final List<StockItem> items;

  const StockList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _StockItemCard(item: items[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual item card
// ---------------------------------------------------------------------------

class _StockItemCard extends StatelessWidget {
  final StockItem item;
  const _StockItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = item.isLowStock;

    final cardColor =
        isLow ? colorScheme.errorContainer : colorScheme.surfaceContainerLow;
    final badgeColor = isLow ? colorScheme.error : colorScheme.primary;
    final badgeTextColor =
        isLow ? colorScheme.onError : colorScheme.onPrimary;

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
            // ── Top row: SKU badge + item name + low-stock chip ──
            Row(
              children: [
                _Pill(
                  label: item.sku,
                  color: badgeColor,
                  textColor: badgeTextColor,
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
                  _Chip(
                    label: 'LOW STOCK',
                    color: colorScheme.error,
                    textColor: colorScheme.onError,
                    icon: Icons.warning_amber_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Category tag ──
            _Chip(
              label: item.category,
              color: colorScheme.secondaryContainer,
              textColor: colorScheme.onSecondaryContainer,
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 10),
            // ── Stats grid ──
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Stat(
                  label: 'Quantity',
                  value: item.quantity.toString(),
                  icon: Icons.inventory_rounded,
                  highlight: isLow,
                  colorScheme: colorScheme,
                ),
                _Stat(
                  label: 'Unit Price',
                  value: 'RM ${item.unitPrice.toStringAsFixed(2)}',
                  icon: Icons.attach_money_rounded,
                  colorScheme: colorScheme,
                ),
                _Stat(
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

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;

  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });

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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final ColorScheme colorScheme;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    required this.colorScheme,
  });

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
            Text(
              label,
              style: TextStyle(fontSize: 10, color: colorScheme.outline),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add stock items using the form above\nor adjust your filters.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
