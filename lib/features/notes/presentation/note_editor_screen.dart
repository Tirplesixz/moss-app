import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/validation/input_limits.dart';
import '../../../core/utils/moss_haptics.dart';
import '../domain/note.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.note});
  final Note? note;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late int _color;
  late bool _pinned;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _content = TextEditingController(text: widget.note?.content ?? '');
    _color = widget.note?.colorValue ?? 0xFFFFF4CC;
    _pinned = widget.note?.pinned ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาใส่ชื่อโน้ต')));
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final note = widget.note == null
        ? Note(
            id: const Uuid().v4(),
            title: title,
            content: _content.text.trim(),
            colorValue: _color,
            pinned: _pinned,
            createdAt: now,
            updatedAt: now,
          )
        : widget.note!.copyWith(
            title: title,
            content: _content.text.trim(),
            colorValue: _color,
            pinned: _pinned,
            updatedAt: now,
          );
    await ref.read(notesViewModelProvider).save(note);
    if (!mounted) return;
    MossHaptics.success();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.note == null ? 'โน้ตใหม่' : 'แก้ไขโน้ต'),
      actions: [
        IconButton(
          tooltip: _pinned ? 'เลิกปักหมุด' : 'ปักหมุด',
          onPressed: () => setState(() => _pinned = !_pinned),
          icon: Icon(
            _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          ),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'กำลังบันทึก…' : 'บันทึก'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _title,
                maxLength: InputLimits.noteTitle,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                autofocus: widget.note == null,
                textInputAction: TextInputAction.next,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโน้ต',
                  hintText: 'เช่น ไอเดียสำหรับโปรเจกต์',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _content,
                maxLength: InputLimits.noteContent,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด',
                  alignLabelWithHint: true,
                  hintText: 'เขียนสิ่งที่ต้องการจำ…',
                ),
              ),
              const SizedBox(height: 20),
              Text('สีโน้ต', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [
                  for (final value in const [
                    0xFFFFF4CC,
                    0xFFE1F5E9,
                    0xFFE8E7FF,
                    0xFFFFE6E2,
                    0xFFE7F1FF,
                  ])
                    Semantics(
                      button: true,
                      selected: _color == value,
                      label: 'เลือกสีโน้ต',
                      child: InkWell(
                        onTap: () => setState(() => _color = value),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(value),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == value
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _color == value
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.black87,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
