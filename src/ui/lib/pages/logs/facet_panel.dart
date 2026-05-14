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

  void _onValueTap(String field, String value) {
    final token = '$field:$value';
    widget.controller.appendFilter(token);
    widget.searchController.text = widget.controller.filter;
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
      child: _loading ? _Shimmer() : _FacetList(facets: _facets, onTap: _onValueTap),
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
  const _FacetList({required this.facets, required this.onTap});

  final List<FacetField> facets;
  final void Function(String field, String value) onTap;

  @override
  Widget build(BuildContext context) {
    if (facets.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ListView(
        children: facets
            .map((f) => _FacetGroup(field: f, onTap: onTap))
            .toList(),
      ),
    );
  }
}

class _FacetGroup extends StatelessWidget {
  const _FacetGroup({required this.field, required this.onTap});

  final FacetField field;
  final void Function(String field, String value) onTap;

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
                onTap: onTap,
              ))
          .toList(),
    );
  }
}

class _FacetValueRow extends StatelessWidget {
  const _FacetValueRow({
    required this.field,
    required this.facetValue,
    required this.onTap,
  });

  final String field;
  final FacetValue facetValue;
  final void Function(String field, String value) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(field, facetValue.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(facetValue.value, style: AppText.mono, overflow: TextOverflow.ellipsis),
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
