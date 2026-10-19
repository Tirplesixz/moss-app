import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/moss_page_route.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/note.dart';
import 'note_editor_screen.dart';
import 'notes_view_model.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(notesViewModelProvider);
    final theme = context.mossTheme;
    final normalized = _query.trim().toLowerCase();
    final visibleNotes = normalized.isEmpty
        ? model.notes
        : model.notes
              .where(
                (note) =>
                    note.title.toLowerCase().contains(normalized) ||
                    note.content.toLowerCase().contains(normalized),
              )
              .toList(growable: false);
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: model.load,
          child: CustomScrollView(
            key: const PageStorageKey('notes'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'โน้ต',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'เก็บไอเดียแยกจากงานที่ต้องลงมือทำ',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: theme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'เพิ่มโน้ต',
                        onPressed: () => _openEditor(context),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'ค้นหาโน้ต',
                    leading: const Icon(Icons.search_rounded),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
              if (model.loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (model.error != null)
                SliverFillRemaining(
                  child: _NotesMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'เปิดโน้ตไม่ได้',
                    actionLabel: 'ลองอีกครั้ง',
                    onAction: model.load,
                  ),
                )
              else if (model.notes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NotesMessage(
                    icon: Icons.note_add_outlined,
                    title: 'ยังไม่มีโน้ต',
                    subtitle:
                        'จดไอเดีย รายละเอียด หรือสิ่งที่ไม่จำเป็นต้องจัดตาราง',
                    actionLabel: 'สร้างโน้ตแรก',
                    onAction: () => _openEditor(context),
                  ),
                )
              else if (visibleNotes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NotesMessage(
                    icon: Icons.search_off_rounded,
                    title: 'ไม่พบโน้ตที่ค้นหา',
                    subtitle: 'ลองใช้คำค้นที่สั้นลงหรือคำอื่น',
                    actionLabel: 'ล้างคำค้น',
                    onAction: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 180,
                        ),
                    itemCount: visibleNotes.length,
                    itemBuilder: (context, index) {
                      final note = visibleNotes[index];
                      return _NoteCard(
                        note: note,
                        onOpen: () => _openEditor(context, note),
                        onPin: () => model.togglePin(note),
                        onCopy: () => _copyNote(context, note),
                        onDelete: () => _confirmDelete(context, model, note),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, [Note? note]) => Navigator.of(
    context,
  ).push(mossPageRoute<void>(context, NoteEditorScreen(note: note)));

  Future<void> _confirmDelete(
    BuildContext context,
    NotesViewModel model,
    Note note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบโน้ตนี้?'),
        content: Text('“${note.title}” จะถูกนำออกจากรายการ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await model.delete(note);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ลบโน้ตแล้ว'),
          action: SnackBarAction(
            label: 'เลิกทำ',
            onPressed: () => model.restore(note),
          ),
        ),
      );
    }
  }

  Future<void> _copyNote(BuildContext context, Note note) async {
    await Clipboard.setData(
      ClipboardData(text: '${note.title}\n\n${note.content}'.trim()),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('คัดลอกโน้ตแล้ว')));
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onOpen,
    required this.onPin,
    required this.onCopy,
    required this.onDelete,
  });
  final Note note;
  final VoidCallback onOpen;
  final VoidCallback onPin;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    color: Color(note.colorValue),
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.black87),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'ตัวเลือกโน้ต',
                  iconColor: Colors.black54,
                  onSelected: (value) {
                    if (value == 'pin') onPin();
                    if (value == 'copy') onCopy();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(note.pinned ? 'เลิกปักหมุด' : 'ปักหมุด'),
                    ),
                    const PopupMenuItem(value: 'copy', child: Text('คัดลอก')),
                    const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content.isEmpty ? 'ไม่มีรายละเอียด' : note.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, height: 1.45),
              ),
            ),
            if (note.pinned)
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.push_pin_rounded,
                  size: 18,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _NotesMessage extends StatelessWidget {
  const _NotesMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 18),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
