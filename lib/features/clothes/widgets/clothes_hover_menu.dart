import 'package:flutter/material.dart';

import '../../../core/theme/osee_theme.dart';
import '../../categories/category_catalog.dart';
import '../../categories/category_panel.dart';

class ClothesHoverMenu extends StatelessWidget {
  const ClothesHoverMenu({
    super.key,
    required this.onSelect,
    required this.onExit,
    required this.catalog,
    required this.selected,
    required this.subcategory,
    required this.onLogin,
  });
  final void Function(String, [String?]) onSelect;
  final VoidCallback onExit;
  final CategoryCatalog catalog;
  final String selected;
  final String? subcategory;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onExit: (_) => onExit(),
    child: Material(
      color: OseePalette.secondary50,
      elevation: 3,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .6,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: CategoryPanel(
                catalog: catalog,
                menu: true,
                selected: selected,
                subcategory: subcategory,
                onSelect: onSelect,
                onLogin: onLogin,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
