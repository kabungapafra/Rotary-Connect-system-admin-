import 'package:flutter/material.dart';

/// A Row of equally-flexed children separated by a fixed gap, matching the
/// source design's `display:grid; grid-template-columns:repeat(n, 1fr); gap`.
class GapRow extends StatelessWidget {
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final List<int>? flexes;
  const GapRow({
    super.key,
    required this.children,
    this.gap = 14,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.flexes,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(width: gap));
      items.add(Expanded(flex: flexes != null ? flexes![i] : 1, child: children[i]));
    }
    // IntrinsicHeight gives the Row a bounded height before `stretch` is
    // applied — without it, a Row inside an unbounded-height ancestor (e.g.
    // a Column in a SingleChildScrollView) throws "BoxConstraints forces an
    // infinite height" when crossAxisAlignment is stretch.
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: crossAxisAlignment, children: items),
    );
  }
}
