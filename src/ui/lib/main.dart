import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:river_api/api.dart';

import 'pages/logs/logs.dart';
import 'theme/app_theme.dart';
import 'controllers/time_range_controller.dart';
import 'widgets/top_panel.dart';

void main() {
  runApp(const RiverApp());
}

class RiverApp extends StatelessWidget {
  const RiverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'River Dashboard',
      theme: appTheme,
      home: const _Shell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum _Page { logs }

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  _Page _selected = _Page.logs;
  bool _sidebarExpanded = true;

  late final DefaultApi _api = _buildApi();
  final _rangeController = TimeRangeController();

  static DefaultApi _buildApi() {
    final inner = HttpClient()..findProxy = (_) => 'DIRECT';
    return DefaultApi(ApiClient(
      basePath: 'http://localhost:8080',
      authentication: null,
    )..client = IOClient(inner));
  }

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TopPanel(rangeController: _rangeController),
          Expanded(
            child: Row(
              children: [
                _Sidebar(
                  selected: _selected,
                  expanded: _sidebarExpanded,
                  onSelect: (page) => setState(() => _selected = page),
                  onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _pageFor(_selected),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFor(_Page page) {
    return switch (page) {
      _Page.logs => LogsPage(apiClient: _api, rangeController: _rangeController),
    };
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggle,
  });

  final _Page selected;
  final bool expanded;
  final void Function(_Page) onSelect;
  final VoidCallback onToggle;

  static const _expandedWidth = 160.0;
  static const _collapsedWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: expanded ? _expandedWidth : _collapsedWidth,
      color: AppColors.sidebar,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _expandedWidth,
          maxWidth: _expandedWidth,
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          _NavItem(
            icon: Icons.list_alt_outlined,
            label: 'Logs',
            page: _Page.logs,
            selected: selected,
            expanded: expanded,
            onTap: onSelect,
          ),
          const Spacer(),
          _ToggleButton(expanded: expanded, onTap: onToggle),
          const SizedBox(height: 8),
        ],
      ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              expanded ? Icons.chevron_left : Icons.chevron_right,
              size: 18,
              color: AppColors.sidebarText,
            ),
            if (expanded) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Collapse',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.navItem.copyWith(color: AppColors.sidebarText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _Page page;
  final _Page selected;
  final bool expanded;
  final void Function(_Page) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = page == selected;
    return GestureDetector(
      onTap: () => onTap(page),
      child: Container(
        color: isSelected ? AppColors.sidebarSelectedBg : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.sidebarSelected : AppColors.sidebarText,
            ),
            if (expanded) ...[
              const SizedBox(width: 10),
              Text(
                label,
                style: AppText.navItem.copyWith(
                  color: isSelected ? AppColors.sidebarSelected : AppColors.sidebarText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
