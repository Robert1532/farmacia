import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget que crea un grid responsivo que se adapta al tamaño de la pantalla
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding = EdgeInsets.zero,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns;
        
        // Determinar el número de columnas según el ancho disponible
        if (width < Constants.mobileBreakpoint) {
          columns = mobileColumns;
        } else if (width < Constants.tabletBreakpoint) {
          columns = tabletColumns;
        } else {
          columns = desktopColumns;
        }
        
        return Padding(
          padding: padding,
          child: Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children.map((child) {
              // Calcular el ancho de cada elemento
              final itemWidth = (width - (spacing * (columns - 1))) / columns;
              
              return SizedBox(
                width: itemWidth,
                child: child,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
