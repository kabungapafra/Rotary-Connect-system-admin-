import 'package:flutter/material.dart';
import '../theme.dart';

class ActionsMenuItem {
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const ActionsMenuItem(this.label, this.onTap, {this.color});
}

/// Row-level "Actions ▾" dropdown, matching the source design's floating
/// menu (white card, border, shadow, divider between rows) — implemented
/// with [OverlayPortal] so it floats above table rows instead of being
/// clipped by them.
class ActionsMenu extends StatefulWidget {
  final List<ActionsMenuItem> items;
  const ActionsMenu({super.key, required this.items});

  @override
  State<ActionsMenu> createState() => _ActionsMenuState();
}

class _ActionsMenuState extends State<ActionsMenu> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _controller.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 6),
                child: _MenuBody(items: widget.items, onSelect: _controller.hide),
              ),
            ],
          );
        },
        child: _ActionsButton(onTap: _controller.toggle),
      ),
    );
  }
}

class _ActionsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ActionsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AdminColors.buttonBorder),
            borderRadius: BorderRadius.circular(7),
            color: Colors.white,
          ),
          child: const Text(
            'Actions ▾',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.buttonText),
          ),
        ),
      ),
    );
  }
}

class _MenuBody extends StatelessWidget {
  final List<ActionsMenuItem> items;
  final VoidCallback onSelect;
  const _MenuBody({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      // IntrinsicWidth gives the Column a bounded width (the widest item's
      // natural width) before `stretch` is applied — otherwise, inside the
      // Overlay's unconstrained Stack, `width: double.infinity` items would
      // expand to fill the whole screen instead of the menu's own content.
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(minWidth: 174),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AdminColors.buttonBorder),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: AdminColors.dropdownShadow, blurRadius: 28, offset: const Offset(0, 12))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++)
                InkWell(
                  onTap: () {
                    onSelect();
                    items[i].onTap();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      border: i > 0 ? const Border(top: BorderSide(color: AdminColors.rowBorder)) : null,
                    ),
                    child: Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: items[i].color ?? AdminColors.textBase,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
