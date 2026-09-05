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
import 'segmented_tabs.dart';

class CollectionSidebar extends GetView<CollectionController> {
  const CollectionSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
            child: Row(
              children: [
                const Text(
                  'COLLECTIONS',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${controller.collections.length}',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                const Spacer(),
                IconButton(
                  tooltip: 'Tambah collection',
                  onPressed: showCollectionDialog,
                  icon: const Icon(LucideIcons.plus, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 34,
              child: TextField(
                onChanged: controller.updateSearch,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(LucideIcons.search, size: 17),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.collections.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.folderKanban,
                        size: 36,
                        color: AppColors.comment,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada collection',
                        style: TextStyle(
                          color: AppColors.comment,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.collections.length,
                itemBuilder: (_, i) {
                  final c = controller.collections[i];
                  final selected =
                      controller.selectedCollectionId.value == c.id;
                  return _CollectionTile(
                    collectionId: c.id,
                    selected: selected,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CollectionTile extends GetView<CollectionController> {
  final String collectionId;
  final bool selected;
  const _CollectionTile({required this.collectionId, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = controller.collections.firstWhere((e) => e.id == collectionId);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        key: ValueKey(
          'col-$collectionId-${controller.folders.length}-${controller.requests.length}',
        ),
        initiallyExpanded: selected,
        onExpansionChanged: (exp) {
          if (exp) controller.selectCollection(collectionId);
        },
        leading: const Icon(
          LucideIcons.folderKanban,
          size: 18,
          color: AppColors.yellow,
        ),
        title: Text(
          c.name,
          style: TextStyle(
            color: selected ? AppColors.blue : AppColors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: _CollectionMenu(collectionId: collectionId),
        children: [
          Obx(() {
            if (controller.selectedCollectionId.value != collectionId) {
              return const SizedBox.shrink();
            }
            final folders = controller.rootFolders;
            final reqs = controller.rootRequests;
            return DragTarget<String>(
              onAcceptWithDetails: (d) => controller.moveRequest(d.data, ''),
              builder: (context, candidate, rejected) => Container(
                decoration: BoxDecoration(
                  color: candidate.isNotEmpty
                      ? AppColors.green.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    ...folders.map(
                      (f) => _FolderTile(folderId: f.id, depth: 1),
                    ),
                    ...reqs.map((r) => _RequestTile(requestId: r.id, depth: 1)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 28, bottom: 6),
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => showFolderDialog(parentId: ''),
                              icon: const Icon(
                                LucideIcons.folderPlus,
                                size: 15,
                              ),
                              label: const Text(
                                'Folder',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => showRequestDialog(folderId: ''),
                              icon: const Icon(LucideIcons.plus, size: 15),
                              label: const Text(
                                'Request',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FolderTile extends GetView<CollectionController> {
  final String folderId;
  final int depth;
  const _FolderTile({required this.folderId, required this.depth});

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
      return Padding(
        padding: EdgeInsets.only(left: 12.0 * depth),
        child: DragTarget<String>(
          onWillAcceptWithDetails: (d) => d.data != folderId,
          onAcceptWithDetails: (d) => controller.moveRequest(d.data, folderId),
          builder: (context, candidate, rejected) => Container(
            color: candidate.isNotEmpty
                ? AppColors.green.withValues(alpha: 0.08)
                : Colors.transparent,
            child: ExpansionTile(
              leading: const Icon(
                LucideIcons.folder,
                size: 17,
                color: AppColors.blue,
              ),
              title: Text(
                f.name,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 13,
                ),
              ),
              trailing: _FolderMenu(folderId: folderId),
              children: [
                ...subs.map(
                  (s) => _FolderTile(folderId: s.id, depth: depth + 1),
                ),
                ...reqs.map(
                  (r) => _RequestTile(requestId: r.id, depth: depth + 1),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 28, bottom: 4),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => showFolderDialog(parentId: folderId),
                          icon: const Icon(
                            LucideIcons.folderPlus,
                            size: 14,
                          ),
                          label: const Text(
                            'Sub',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              showRequestDialog(folderId: folderId),
                          icon: const Icon(LucideIcons.plus, size: 14),
                          label: const Text(
                            'Req',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _RequestTile extends GetView<CollectionController> {
  final String requestId;
  final int depth;
  const _RequestTile({required this.requestId, required this.depth});

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
      final tile = ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        leading: _MethodBadge(method: r.method),
        title: Text(
          r.name,
          style: TextStyle(
            color: selected ? AppColors.blue : AppColors.foreground,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _RequestMenu(requestId: requestId),
        onTap: () => controller.selectRequest(requestId),
      );
      return Padding(
        padding: EdgeInsets.only(left: 12.0 * depth, right: 8),
        child: Draggable<String>(
          data: requestId,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                r.name,
                style: const TextStyle(
                  color: AppColors.foreground,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: tile),
          child: tile,
        ),
      );
    });
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: DetaskBadge(text: method, color: httpMethodColor(method)),
    );
  }
}

class _CollectionMenu extends GetView<CollectionController> {
  final String collectionId;
  const _CollectionMenu({required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreHorizontal, size: 17),
      onSelected: (v) {
        if (v == 'edit') {
          showCollectionDialog(editId: collectionId);
        } else if (v == 'delete') {
          AppDialog.confirm(
            title: 'Hapus collection?',
            message: 'Folder & request di dalamnya ikut terhapus.',
            onConfirm: () => controller.deleteCollection(collectionId),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
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
      icon: const Icon(LucideIcons.moreHorizontal, size: 16),
      onSelected: (v) {
        if (v == 'edit') {
          showFolderDialog(editId: folderId);
        } else if (v == 'delete') {
          AppDialog.confirm(
            title: 'Hapus folder?',
            message: 'Sub-folder & request di dalamnya ikut terhapus.',
            onConfirm: () => controller.deleteFolder(folderId),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
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
      icon: const Icon(LucideIcons.moreHorizontal, size: 16),
      onSelected: (v) {
        if (v == 'duplicate') {
          controller.duplicateRequest(requestId);
        } else if (v == 'delete') {
          AppDialog.confirm(
            title: 'Hapus request?',
            message: 'Request akan dihapus permanen.',
            onConfirm: () => controller.deleteRequest(requestId),
          );
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    );
  }
}
