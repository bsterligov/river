import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../theme/app_theme.dart';
import '../pages/logs/logs_controller.dart';

class FacetPanel extends StatefulWidget {
  const FacetPanel({
    super.key,
    required this.controller,
    required this.searchController,
    required this.manualFilter,
    required this.expanded,
    required this.onToggle,
  });

  final LogsController controller;
  final TextEditingController searchController;
  final String manualFilter;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<FacetPanel> createState() => _FacetPanelState();
}

class _FacetPanelState extends State<FacetPanel> {
  List<FacetField> _facets = [];
  bool _loading = false;

  // Tokens checked via the facet panel checkboxes.
  // Also pre-populated from manualFilter on init/update.
  final Set<String> _selected = {};

  int _lastRangeVersion = -1;

  // Counts pending self-initiated controller updates to suppress re-fetch
  int _selfUpdateDepth = 0;

  @override
  void initState() {
    super.initState();
    _selected.addAll(_tokensFromFilter(widget.manualFilter));
    _lastRangeVersion = widget.controller.rangeVersion;
    widget.controller.addListener(_onControllerChanged);
    _fetch();
  }

  @override
  void didUpdateWidget(FacetPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manualFilter != widget.manualFilter) {
      // User submitted a new manual filter — re-derive checked state from it.
      setState(() {
        _selected
          ..clear()
          ..addAll(_tokensFromFilter(widget.manualFilter));
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  // Parse simple "field:value" tokens from a filter string.
  // Ignores AND/OR/NOT keywords and parentheses.
  static Set<String> _tokensFromFilter(String filter) {
    final result = <String>{};
    for (final part in filter.split(RegExp(r'\s+'))) {
      final clean = part.replaceAll(RegExp(r'[()]'), '');
      if (clean.contains(':') &&
          !const {'AND', 'OR', 'NOT'}.contains(clean.toUpperCase())) {
        result.add(clean);
      }
    }
    return result;
  }

  void _onControllerChanged() {
    if (_selfUpdateDepth > 0) return;
    final v = widget.controller.rangeVersion;
    if (v == _lastRangeVersion) return;
    _lastRangeVersion = v;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final results = await widget.controller.apiClient.getLogsFacets(
        filter: widget.manualFilter.isEmpty ? null : widget.manualFilter,
        from: widget.controller.from.toIso8601String(),
        to: widget.controller.to.toIso8601String(),
      );
      if (!mounted) return;
      setState(() {
        _facets = results ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('FacetPanel: failed to fetch facets: $e');
      if (!mounted) return;
      setState(() {
        _facets = [];
        _loading = false;
      });
    }
  }

  String _buildFacetFilter() {
    final byField = <String, List<String>>{};
    for (final token in _selected) {
      final colon = token.indexOf(':');
      final f = token.substring(0, colon);
      final v = token.substring(colon + 1);
      byField.putIfAbsent(f, () => []).add(v);
    }
    final groups = byField.entries.map((e) {
      final parts = e.value.map((v) => '${e.key}:$v').join(' OR ');
      return e.value.length > 1 ? '($parts)' : parts;
    }).toList();
    return groups.join(' AND ');
  }

  String _combineFilters(String manual, String facets) {
    if (manual.isEmpty) return facets;
    if (facets.isEmpty) return manual;
    return '$manual AND $facets';
  }

  Future<void> _onToggle(String field, String value) async {
    final token = '$field:$value';
    setState(() {
      if (_selected.contains(token)) {
        _selected.remove(token);
      } else {
        _selected.add(token);
      }
    });

    final facetFilter = _buildFacetFilter();
    final combined = _combineFilters(widget.manualFilter, facetFilter);
    _selfUpdateDepth++;
    try {
      widget.controller.setFilter(combined);
      widget.searchController.text = combined;
      await widget.controller.reload();
    } finally {
      _selfUpdateDepth--;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('facet_panel'),
      color: Colors.white,
      child: SizedBox(
      width: AppLayout.facetPanelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: widget.onToggle,
            child: Padding(
              padding: AppLayout.tilePadding.add(const EdgeInsets.symmetric(vertical: 12)),
              child: Row(
                children: [
                  Icon(
                    widget.expanded ? Icons.chevron_left : Icons.chevron_right,
                    size: AppIcons.sizeL,
                    color: Colors.black54,
                  ),
                  if (widget.expanded) ...[
                    const SizedBox(width: AppLayout.gapM),
                    Text('Filters', style: AppText.label),
                  ],
                ],
              ),
            ),
          ),
          if (widget.expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: _loading
                  ? const _Shimmer()
                  : _FacetList(
                      facets: _facets,
                      selected: Set.unmodifiable(_selected),
                      onToggle: _onToggle,
                    ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('facet_shimmer'),
      decoration: BoxDecoration(
        color: AppColors.shimmer,
        borderRadius: BorderRadius.circular(AppLayout.radius),
      ),
    );
  }
}

class _FacetList extends StatelessWidget {
  const _FacetList({
    required this.facets,
    required this.selected,
    required this.onToggle,
  });

  final List<FacetField> facets;
  final Set<String> selected;
  final Future<void> Function(String field, String value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (facets.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppLayout.radius),
      child: ListView(
        children: facets
            .map((f) => _FacetGroup(field: f, selected: selected, onToggle: onToggle))
            .toList(),
      ),
    );
  }
}

class _FacetGroup extends StatelessWidget {
  const _FacetGroup({
    required this.field,
    required this.selected,
    required this.onToggle,
  });

  final FacetField field;
  final Set<String> selected;
  final Future<void> Function(String field, String value) onToggle;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: AppLayout.tilePadding,
      title: Text(field.field, style: AppText.label),
      children: field.values
          .map((v) => _FacetValueRow(
                field: field.field,
                facetValue: v,
                checked: selected.contains('${field.field}:${v.value}'),
                onToggle: onToggle,
              ))
          .toList(),
    );
  }
}

class _FacetValueRow extends StatelessWidget {
  const _FacetValueRow({
    required this.field,
    required this.facetValue,
    required this.checked,
    required this.onToggle,
  });

  final String field;
  final FacetValue facetValue;
  final bool checked;
  final Future<void> Function(String field, String value) onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(field, facetValue.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.gapM, vertical: AppLayout.gapS),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: (_) => onToggle(field, facetValue.value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(
                facetValue.value,
                style: AppText.mono,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.gapM, vertical: AppLayout.gapS),
              decoration: BoxDecoration(
                color: AppColors.tableHeader,
                borderRadius: BorderRadius.circular(AppLayout.radiusBadge),
              ),
              child: Text('${facetValue.count}', style: AppText.label),
            ),
          ],
        ),
      ),
    );
  }
}
