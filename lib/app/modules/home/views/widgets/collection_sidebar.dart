import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_dialog.dart';
import '../../../../core/utils/method_colors.dart';
import '../../../../data/models/api_request_model.dart';
import '../../../../data/models/folder_model.dart';
import '../../controllers/collection_controller.dart';
import 'entity_dialogs.dart';

class CollectionSidebar extends GetView<CollectionController> {
  const CollectionSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 16, 20, 6),
            child: Row(
              children: <Widget>[
                const Icon(
                  LucideIcons.layers,
                  size: 20,
                  color: AppColors.comment,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Collections',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${controller.collections.length}',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _IconAction(
                  tooltip: 'Add collection',
                  icon: LucideIcons.plus,
                  onPressed: showCollectionDialog,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 6, 20, 10),
            child: SizedBox(
              height: 50,
              child: TextField(
                onChanged: controller.updateSearch,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12.5,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Filter...',
                  hintStyle: TextStyle(
                    color: AppColors.comment,
                    fontSize: 12.5,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 14,
                    color: AppColors.comment,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
          const _TreeDivider(),
          Expanded(
            child: Obx(() {
              if (controller.collections.isEmpty) {
                return const _EmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: controller.collections.length,
                itemBuilder: (BuildContext _, int i) {
                  final c = controller.collections[i];
                  return _CollectionNode(collectionId: c.id);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------- Root collection node ----------

class _CollectionNode extends GetView<CollectionController> {
  final String collectionId;
  const _CollectionNode({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = controller.collections.firstWhere((e) => e.id == collectionId);
      final expanded = controller.expandedCollections.contains(collectionId);
      final selected = controller.selectedCollectionId.value == collectionId;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TreeRow(
            depth: 0,
            expanded: expanded,
            selected: selected,
            hoverAccent: AppColors.yellow,
            leadingIcon: LucideIcons.folder,
            leadingColor: AppColors.yellow,
            label: c.name,
            onTap: () {
              controller.toggleCollection(collectionId);
              if (!selected) controller.selectCollection(collectionId);
            },
            onChevron: () => controller.toggleCollection(collectionId),
            trailing: _CollectionMenu(collectionId: collectionId),
          ),
          if (expanded) _CollectionChildren(collectionId: collectionId),
        ],
      );
    });
  }
}

class _CollectionChildren extends GetView<CollectionController> {
  final String collectionId;
  const _CollectionChildren({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedCollectionId.value != collectionId) {
        return const SizedBox.shrink();
      }
      final folders = controller.rootFolders;
      final reqs = controller.rootRequests;
      return DragTarget<String>(
        onAcceptWithDetails: (d) => controller.moveRequest(d.data, ''),
        builder: (context, candidate, rejected) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: candidate.isNotEmpty
                ? AppColors.green.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...folders.map((f) => _FolderNode(folderId: f.id, depth: 1)),
              ...reqs.map((r) => _RequestNode(requestId: r.id, depth: 1)),
              _AddRow(
                depth: 1,
                items: [
                  _AddItem(
                    icon: LucideIcons.folderPlus,
                    label: 'Folder',
                    onTap: () => showFolderDialog(parentId: ''),
                  ),
                  _AddItem(
                    icon: LucideIcons.plus,
                    label: 'Request',
                    onTap: () => showRequestDialog(folderId: ''),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ---------- Folder node ----------

class _FolderNode extends GetView<CollectionController> {
  final String folderId;
  final int depth;
  const _FolderNode({required this.folderId, required this.depth});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      FolderModel f;
      try {
        f = controller.folders.firstWhere((e) => e.id == folderId);
      } catch (_) {
        return const SizedBox.shrink();
      }
      final subs = controller.subFolders(folderId);
      final reqs = controller.folderRequests(folderId);
      final expanded = controller.expandedFolders.contains(folderId);
      final hasChildren = subs.isNotEmpty || reqs.isNotEmpty;
      return Padding(
        padding: EdgeInsets.only(right: 6),
        child: DragTarget<String>(
          onWillAcceptWithDetails: (d) => d.data != folderId,
          onAcceptWithDetails: (d) => controller.moveRequest(d.data, folderId),
          builder: (context, candidate, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: candidate.isNotEmpty
                  ? AppColors.green.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TreeRow(
                  depth: depth,
                  expanded: expanded,
                  chevronEnabled: hasChildren,
                  hoverAccent: AppColors.green,
                  leadingIcon: expanded
                      ? LucideIcons.folderOpen
                      : LucideIcons.folder,
                  leadingColor: AppColors.green,
                  label: f.name,
                  onTap: () => controller.toggleFolder(folderId),
                  onChevron: hasChildren
                      ? () => controller.toggleFolder(folderId)
                      : null,
                  trailing: _FolderMenu(folderId: folderId),
                ),
                if (expanded) ...[
                  ...subs.map(
                    (s) => _FolderNode(folderId: s.id, depth: depth + 1),
                  ),
                  ...reqs.map(
                    (r) => _RequestNode(requestId: r.id, depth: depth + 1),
                  ),
                  _AddRow(
                    depth: depth + 1,
                    items: [
                      _AddItem(
                        icon: LucideIcons.folderPlus,
                        label: 'Sub',
                        onTap: () => showFolderDialog(parentId: folderId),
                      ),
                      _AddItem(
                        icon: LucideIcons.plus,
                        label: 'Request',
                        onTap: () => showRequestDialog(folderId: folderId),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ---------- Request node ----------

class _RequestNode extends GetView<CollectionController> {
  final String requestId;
  final int depth;
  const _RequestNode({required this.requestId, required this.depth});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      ApiRequestModel r;
      try {
        r = controller.requests.firstWhere((e) => e.id == requestId);
      } catch (_) {
        return const SizedBox.shrink();
      }
      final selected = controller.selectedRequestId.value == requestId;
      final tile = _TreeRow(
        depth: depth,
        expanded: false,
        showChevron: false,
        selected: selected,
        hoverAccent: httpMethodColor(r.method),
        leading: _MethodBadge(method: r.method),
        label: r.name,
        onTap: () => controller.selectRequest(requestId),
        trailing: _RequestMenu(requestId: requestId),
      );
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Draggable<String>(
          data: requestId,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.backgroundDark),
              ),
              child: Text(
                r.name,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: tile),
          child: tile,
        ),
      );
    });
  }
}

// ---------- Tree row primitive ----------

class _TreeRow extends StatefulWidget {
  final int depth;
  final bool expanded;
  final bool selected;
  final bool showChevron;
  final bool chevronEnabled;
  final String label;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onChevron;
  final Color? hoverAccent;

  const _TreeRow({
    required this.depth,
    required this.expanded,
    required this.label,
    this.selected = false,
    this.showChevron = true,
    this.chevronEnabled = true,
    this.leadingIcon,
    this.leadingColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.onChevron,
    this.hoverAccent,
  });

  @override
  State<_TreeRow> createState() => _TreeRowState();
}

class _TreeRowState extends State<_TreeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final indent = 18.0 + widget.depth * 14.0;
    Color? bg;
    Color labelColor = AppColors.foreground;
    Color iconColor = widget.leadingColor ?? AppColors.mutedForeground;

    if (widget.selected) {
      bg = AppColors.backgroundDark;
      labelColor = AppColors.white;
    } else if (_hovered) {
      bg = AppColors.surface.withValues(alpha: 0.55);
    }

    final leadingWidget =
        widget.leading ??
        Icon(
          widget.leadingIcon ?? LucideIcons.file,
          size: 14,
          color: iconColor,
        );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          padding: EdgeInsets.only(left: indent, right: 4),
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (widget.showChevron)
                _Chevron(
                  expanded: widget.expanded,
                  enabled: widget.chevronEnabled,
                  onTap: widget.onChevron,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 4),
              SizedBox(
                width: 16,
                height: 16,
                child: Center(child: leadingWidget),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.5,
                    fontWeight: widget.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.trailing != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: (_hovered || widget.selected) ? 1 : 0,
                  child: widget.trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  final bool expanded;
  final bool enabled;
  final VoidCallback? onTap;
  const _Chevron({required this.expanded, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            turns: expanded ? 0.25 : 0,
            child: Icon(
              LucideIcons.chevronRight,
              size: 12,
              color: enabled
                  ? AppColors.mutedForeground
                  : AppColors.comment.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Method badge ----------

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = httpMethodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.2,
        ),
      ),
    );
  }
}

// ---------- Add row ----------

class _AddRow extends StatelessWidget {
  final int depth;
  final List<_AddItem> items;
  const _AddRow({required this.depth, required this.items});

  @override
  Widget build(BuildContext context) {
    final indent = 8.0 + depth * 14.0 + 16; // align under chevron slot
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 2, bottom: 2, right: 8),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _AddItemButton(item: items[i]),
            if (i != items.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _AddItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _AddItem({required this.icon, required this.label, required this.onTap});
}

class _AddItemButton extends StatefulWidget {
  final _AddItem item;
  const _AddItemButton({required this.item});

  @override
  State<_AddItemButton> createState() => _AddItemButtonState();
}

class _AddItemButtonState extends State<_AddItemButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.item.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: _h
                ? AppColors.surface.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.item.icon, size: 11, color: AppColors.comment),
              const SizedBox(width: 4),
              Text(
                widget.item.label,
                style: const TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Misc ----------

class _TreeDivider extends StatelessWidget {
  const _TreeDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.surface,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.folderOpen,
              size: 18,
              color: AppColors.comment,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No collections yet',
            style: TextStyle(color: AppColors.comment, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: AppColors.mutedForeground),
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
      style: IconButton.styleFrom(
        hoverColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

// ---------- Menus (unchanged behavior) ----------

class _CollectionMenu extends GetView<CollectionController> {
  final String collectionId;
  const _CollectionMenu({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreHorizontal, size: 14),
      padding: EdgeInsets.zero,
      splashRadius: 12,
      onSelected: (v) {
        if (v == 'edit') {
          showCollectionDialog(editId: collectionId);
        } else if (v == 'delete') {
          AppDialog.confirm(
            title: 'Delete collection?',
            message: 'Folders & requests inside will also be deleted.',
            onConfirm: () => controller.deleteCollection(collectionId),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _FolderMenu extends GetView<CollectionController> {
  final String folderId;
  const _FolderMenu({required this.folderId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreHorizontal, size: 14),
      padding: EdgeInsets.zero,
      splashRadius: 12,
      onSelected: (v) {
        if (v == 'edit') {
          showFolderDialog(editId: folderId);
        } else if (v == 'delete') {
          AppDialog.confirm(
            title: 'Delete folder?',
            message: 'Sub-folder & request will be deleted too.',
            onConfirm: () => controller.deleteFolder(folderId),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _RequestMenu extends GetView<CollectionController> {
  final String requestId;
  const _RequestMenu({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreHorizontal, size: 14),
      padding: EdgeInsets.zero,
      splashRadius: 12,
      onSelected: (v) {
        if (v == 'duplicate') {
          controller.duplicateRequest(requestId);
        } else if (v == 'delete') {
          AppDialog.confirm(
            title: 'Delete request?',
            message: 'Request will be permanently deleted.',
            onConfirm: () => controller.deleteRequest(requestId),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}
