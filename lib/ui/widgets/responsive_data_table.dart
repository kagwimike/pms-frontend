import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Column descriptor for `ResponsiveDataTable`
class ResponsiveColumn {
  final String label;
  final int flex;
  final TextAlign alignment;

  const ResponsiveColumn({
    required this.label,
    this.flex = 1,
    this.alignment = TextAlign.start,
  });
}

/// A responsive table component that automatically adapts based on screen size:
/// - **Desktop / Tablet (>= breakpoint, default 650px)**: Displays a clean, structured table with a header row and aligned cells.
/// - **Mobile (< breakpoint)**: Automatically transforms each row into a beautiful, elevated Card with labeled fields.
class ResponsiveDataTable<T> extends StatelessWidget {
  final List<ResponsiveColumn> columns;
  final List<T> items;
  final List<Widget> Function(BuildContext context, T item) buildCells;
  final Widget Function(BuildContext context, T item)? buildMobileCard;
  final void Function(T item)? onItemTap;
  final Widget? emptyState;
  final double breakpoint;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.buildCells,
    this.buildMobileCard,
    this.onItemTap,
    this.emptyState,
    this.breakpoint = 650.0,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyState ?? const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final headerBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF27272A) : AppTheme.border;
    final headerTextColor = isDark ? AppTheme.darkMutedText : const Color(0xFF475569);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < breakpoint;

        if (isMobile) {
          // ── Mobile: Display as Cards ──
          return ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              if (buildMobileCard != null) {
                return buildMobileCard!(context, item);
              }

              // Default smart card builder using columns & cells
              final cells = buildCells(context, item);
              return Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onItemTap != null ? () => onItemTap!(item) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < cells.length && i < columns.length; i++) ...[
                            if (i > 0) const Divider(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  columns[i].label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: headerTextColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: cells[i],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        // ── Desktop / Tablet: Display as Structured Table ──
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table Header
              Container(
                color: headerBg,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    for (final col in columns)
                      Expanded(
                        flex: col.flex,
                        child: Text(
                          col.label,
                          textAlign: col.alignment,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: headerTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // Table Body
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final cells = buildCells(context, item);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onItemTap != null ? () => onItemTap!(item) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            for (int i = 0; i < cells.length && i < columns.length; i++)
                              Expanded(
                                flex: columns[i].flex,
                                child: Align(
                                  alignment: columns[i].alignment == TextAlign.end
                                      ? Alignment.centerRight
                                      : (columns[i].alignment == TextAlign.center
                                          ? Alignment.center
                                          : Alignment.centerLeft),
                                  child: cells[i],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
