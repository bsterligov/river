import 'package:flutter/material.dart';
import 'package:river_api/api.dart';

import '../../theme/app_theme.dart';
import 'logs_controller.dart';

class FacetPanel extends StatefulWidget {
  const FacetPanel({
    super.key,
    required this.controller,
    required this.searchController,
  });

  final LogsController controller;
  final TextEditingController searchController;

  @override
  State<FacetPanel> createState() => _FacetPanelState();
}

class _FacetPanelState extends State<FacetPanel> {
  List<FacetField> _facets = [];
  bool _loading = false;

  // Tokens the user has checked, e.g. {"service_name:svc-a", "severity_text:ERROR"}
  final Set<String> _selected = {};

  // Counts pending self-initiated controller updates to suppress re-fetch
  int _selfUpdateDepth = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _fetch();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_selfUpdateDepth > 0) return;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final results = await widget.controller.apiClient.getLogsFacets(
        filter: widget.controller.filter.isEmpty
            ? null
            : widget.controller.filter,
        from: widget.controller.from.toIso8601String(),
        to: widget.controller.to.toIso8601String(),
      );
      if (mounted) {
        setState(() {
          _facets = results ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _facets = [];
          _loading = false;
        });
      }
    }
  }

  String _buildFilter() {
    // Group selected tokens by field, then emit field:(v1 OR v2) per group
    final byField = <String, List<String>>{};
    for (final token in _selected) {
      final colon = token.indexOf(':');
      final f = token.substring(0, colon);
      final v = token.substring(colon + 1);
      byField.putIfAbsent(f, () => []).add(v);
    }
    return byField.entries.map((e) {
      final values = e.value;
      return values.length == 1
          ? '${e.key}:${values.first}'
          : '${e.key}:(${values.join(' OR ')})';
    }).join(' AND ');
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

    final newFilter = _buildFilter();
    _selfUpdateDepth++;
    try {
      widget.controller.setFilter(newFilter);
      widget.searchController.text = newFilter;
      await widget.controller.reload();
    } finally {
      _selfUpdateDepth--;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('facet_panel'),
      width: 220,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: _loading
          ? _Shimmer()
          : _FacetList(
              facets: _facets,
              selected: Set.unmodifiable(_selected),
              onToggle: _onToggle,
            ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('facet_shimmer'),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(6),
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
      borderRadius: BorderRadius.circular(6),
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
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tableHeader,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${facetValue.count}', style: AppText.label),
            ),
          ],
        ),
      ),
    );
  }
}
