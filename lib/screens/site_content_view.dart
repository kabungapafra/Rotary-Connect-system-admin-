import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// The three editable content sections of the public marketing site:
/// events, news and projects.
///
/// They share this file because they are the same screen with different
/// fields — a list of rows, an "add" button, and an edit dialog. Nothing
/// here notifies anyone; publishing only changes what the website serves.

// ── Events ─────────────────────────────────────────────────────────────

class SiteEventsView extends StatelessWidget {
  const SiteEventsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return _ContentScaffold(
      blurb:
          'Shown in the Events section of the public site. Past events drop '
          'off automatically — no need to delete them.',
      addLabel: 'Add event',
      loading: state.siteEventsLoading,
      isEmpty: state.siteEvents.isEmpty,
      emptyText: 'No events on the website yet.',
      onAdd: () => _openEventEditor(context, state, null),
      children: [
        for (final e in state.siteEvents)
          _Row(
            leading: _DateChip(iso: e.eventDate),
            title: e.title,
            subtitle: [
              if (e.kind.isNotEmpty) e.kind,
              if (e.meta.isNotEmpty) e.meta,
            ].join(' · '),
            published: e.published,
            onEdit: () => _openEventEditor(context, state, e),
            onDelete: () => state.deleteSiteEvent(e.id),
          ),
      ],
    );
  }
}

void _openEventEditor(
  BuildContext context,
  DashboardState state,
  SiteEvent? existing,
) {
  final isNew = existing == null;
  final title = TextEditingController(text: existing?.title ?? '');
  final meta = TextEditingController(text: existing?.meta ?? '');
  final kind = TextEditingController(text: existing?.kind ?? '');
  final date = TextEditingController(
    text: existing?.eventDate ?? _todayIso(),
  );
  var published = existing?.published ?? true;

  _showEditor(
    context: context,
    heading: isNew ? 'Add website event' : 'Edit website event',
    fieldsBuilder: (setLocal) => [
      _Field(label: 'Title', controller: title),
      _Field(label: 'Date (YYYY-MM-DD)', controller: date),
      _Field(
        label: 'Kind',
        controller: kind,
        hint: 'Weekly, Service, Fundraiser…',
      ),
      _Field(
        label: 'Details',
        controller: meta,
        hint: 'Every Tuesday · 7pm · QR check-in at the door',
      ),
      _PublishedToggle(
        value: published,
        onChanged: (v) => setLocal(() => published = v),
      ),
    ],
    onSave: () {
      if (title.text.trim().isEmpty || !_isIsoDate(date.text.trim())) {
        return 'Enter a title and a date as YYYY-MM-DD.';
      }
      state.saveSiteEvent(
        SiteEvent(
          id: existing?.id ?? 0,
          eventDate: date.text.trim(),
          title: title.text.trim(),
          meta: meta.text.trim(),
          kind: kind.text.trim(),
          published: published,
        ),
        isNew: isNew,
      );
      return null;
    },
  );
}

// ── News ───────────────────────────────────────────────────────────────

class SiteNewsView extends StatelessWidget {
  const SiteNewsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return _ContentScaffold(
      blurb:
          'Shown in the News section of the public site, newest first. '
          'Unlike events, old news stays up.',
      addLabel: 'Add news item',
      loading: state.siteNewsLoading,
      isEmpty: state.siteNews.isEmpty,
      emptyText: 'No news items yet.',
      onAdd: () => _openNewsEditor(context, state, null),
      children: [
        for (final n in state.siteNews)
          _Row(
            leading: _DateChip(iso: n.publishedOn),
            title: n.title,
            subtitle: n.body,
            published: n.published,
            onEdit: () => _openNewsEditor(context, state, n),
            onDelete: () => state.deleteSiteNews(n.id),
          ),
      ],
    );
  }
}

void _openNewsEditor(
  BuildContext context,
  DashboardState state,
  SiteNews? existing,
) {
  final isNew = existing == null;
  final title = TextEditingController(text: existing?.title ?? '');
  final body = TextEditingController(text: existing?.body ?? '');
  final date = TextEditingController(
    text: existing?.publishedOn ?? _todayIso(),
  );
  var published = existing?.published ?? true;

  _showEditor(
    context: context,
    heading: isNew ? 'Add news item' : 'Edit news item',
    fieldsBuilder: (setLocal) => [
      _Field(label: 'Headline', controller: title),
      _Field(label: 'Date (YYYY-MM-DD)', controller: date),
      _Field(label: 'Body', controller: body, lines: 4),
      _PublishedToggle(
        value: published,
        onChanged: (v) => setLocal(() => published = v),
      ),
    ],
    onSave: () {
      if (title.text.trim().isEmpty || !_isIsoDate(date.text.trim())) {
        return 'Enter a headline and a date as YYYY-MM-DD.';
      }
      state.saveSiteNews(
        SiteNews(
          id: existing?.id ?? 0,
          publishedOn: date.text.trim(),
          title: title.text.trim(),
          body: body.text.trim(),
          published: published,
        ),
        isNew: isNew,
      );
      return null;
    },
  );
}

// ── Projects ───────────────────────────────────────────────────────────

class SiteProjectsView extends StatelessWidget {
  const SiteProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return _ContentScaffold(
      blurb:
          'The showcase projects on the public site. These are marketing '
          'copy — unrelated to the real projects clubs track in the app.',
      addLabel: 'Add project',
      loading: state.siteProjectsLoading,
      isEmpty: state.siteProjects.isEmpty,
      emptyText: 'No showcase projects yet.',
      onAdd: () => _openProjectEditor(context, state, null),
      children: [
        for (final p in state.siteProjects)
          _Row(
            leading: p.photo == null
                ? _TagChip(tag: p.tag)
                : _Thumb(url: p.photo!),
            title: p.title,
            subtitle: [
              if (p.area.isNotEmpty) p.area,
              '${p.progressPercent}% complete',
              if (p.deadline != null) 'Due ${p.deadline}',
            ].join(' · '),
            published: p.published,
            onEdit: () => _openProjectEditor(context, state, p),
            onDelete: () => state.deleteSiteProject(p.id),
          ),
      ],
    );
  }
}

void _openProjectEditor(
  BuildContext context,
  DashboardState state,
  SiteProject? existing,
) {
  final isNew = existing == null;
  final title = TextEditingController(text: existing?.title ?? '');
  final tag = TextEditingController(text: existing?.tag ?? '');
  final area = TextEditingController(text: existing?.area ?? '');
  final body = TextEditingController(text: existing?.body ?? '');
  final progress = TextEditingController(
    text: '${existing?.progressPercent ?? 0}',
  );
  final deadline = TextEditingController(text: existing?.deadline ?? '');
  final photo = TextEditingController(text: existing?.photoCaption ?? '');
  var published = existing?.published ?? true;
  var photoUrl = existing?.photo;
  var photoChanged = false;

  _showEditor(
    context: context,
    heading: isNew ? 'Add showcase project' : 'Edit showcase project',
    fieldsBuilder: (setLocal) => [
      _Field(label: 'Title', controller: title),
      _Field(label: 'Tag', controller: tag, hint: 'WAT, EDU, ENV…'),
      _Field(
        label: 'Area of focus',
        controller: area,
        hint: 'Water & sanitation',
      ),
      _Field(label: 'Description', controller: body, lines: 3),
      _Field(label: 'Progress %', controller: progress),
      _Field(
        label: 'Deadline (YYYY-MM-DD, optional)',
        controller: deadline,
      ),
      _PhotoPicker(
        value: photoUrl,
        onPicked: (v) => setLocal(() {
          photoUrl = v;
          photoChanged = true;
        }),
      ),
      _Field(label: 'Photo caption', controller: photo),
      _PublishedToggle(
        value: published,
        onChanged: (v) => setLocal(() => published = v),
      ),
    ],
    onSave: () {
      if (title.text.trim().isEmpty) return 'Enter a title.';
      final deadlineText = deadline.text.trim();
      if (deadlineText.isNotEmpty && !_isIsoDate(deadlineText)) {
        return 'Deadline must be YYYY-MM-DD, or left blank.';
      }
      state.saveSiteProject(
        SiteProject(
          id: existing?.id ?? 0,
          tag: tag.text.trim(),
          area: area.text.trim(),
          title: title.text.trim(),
          body: body.text.trim(),
          progressPercent: int.tryParse(progress.text.trim()) ?? 0,
          deadline: deadlineText.isEmpty ? null : deadlineText,
          photoCaption: photo.text.trim(),
          published: published,
          photo: photoUrl,
          photoChanged: photoChanged,
        ),
        isNew: isNew,
      );
      return null;
    },
  );
}

// ── Shared pieces ──────────────────────────────────────────────────────

class _ContentScaffold extends StatelessWidget {
  final String blurb;
  final String addLabel;
  final bool loading;
  final bool isEmpty;
  final String emptyText;
  final VoidCallback onAdd;
  final List<Widget> children;

  const _ContentScaffold({
    required this.blurb,
    required this.addLabel,
    required this.loading,
    required this.isEmpty,
    required this.emptyText,
    required this.onAdd,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                blurb,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AdminColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  addLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (loading && isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (isEmpty)
          Container(
            decoration: cardDecoration(),
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                emptyText,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AdminColors.textMuted,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final bool published;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _Row({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.published,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.rowBorder)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textBase,
                        ),
                      ),
                    ),
                    // Only drafts get a badge: marking every live row
                    // "Published" would be noise on a page where that is
                    // the norm.
                    if (!published) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.dueSoonTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Draft',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.dueSoonColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _TextButton(label: 'Edit', onTap: onEdit),
          const SizedBox(width: 8),
          _TextButton(label: 'Delete', onTap: onDelete, danger: true),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String iso;
  const _DateChip({required this.iso});

  @override
  Widget build(BuildContext context) {
    final parsed = DateTime.tryParse(iso);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AdminColors.clubInitialsBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            parsed == null ? '—' : months[parsed.month - 1],
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AdminColors.clubInitialsText,
            ),
          ),
          Text(
            parsed == null ? '' : '${parsed.day}'.padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AdminColors.clubInitialsText,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AdminColors.clubInitialsBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag.isEmpty ? '—' : tag.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AdminColors.clubInitialsText,
        ),
      ),
    );
  }
}

/// Project rows show the card photo where other lists show a chip, so the
/// admin can tell at a glance which projects still need one.
class _Thumb extends StatelessWidget {
  final String url;
  const _Thumb({required this.url});


  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        base64Decode(url.split(',').last),
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 46,
          height: 46,
          color: AdminColors.statsPlaceholderBg,
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _TextButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: danger
                ? AdminColors.overdueDot.withValues(alpha: 0.4)
                : AdminColors.buttonBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: danger ? AdminColors.overdueColor : AdminColors.buttonText,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int lines;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminColors.textBase,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: lines,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AdminColors.inputBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishedToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PublishedToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(
          value ? 'Live on the website' : 'Draft — hidden from the website',
          style: const TextStyle(fontSize: 13, color: AdminColors.textMuted),
        ),
      ],
    );
  }
}

/// The editor dialog. [onSave] returns an error message to show inline, or
/// null when the save was accepted and the dialog should close.
///
/// Deliberately not built on ModalScrim: that widget is a Positioned.fill
/// meant to be stacked over a view, and showDialog gives it no Stack to
/// sit in.
void _showEditor({
  required BuildContext context,
  required String heading,
  required List<Widget> Function(void Function(void Function())) fieldsBuilder,
  required String? Function() onSave,
}) {
  showDialog<void>(
    context: context,
    barrierColor: AdminColors.modalOverlay,
    builder: (dialogContext) {
      String? error;
      return StatefulBuilder(
        builder: (builderContext, setLocal) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 460,
              constraints: const BoxConstraints(maxHeight: 640),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      heading,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.textBase,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...fieldsBuilder(setLocal),
                    if (error != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AdminColors.overdueColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _TextButton(
                          label: 'Cancel',
                          onTap: () => Navigator.of(dialogContext).pop(),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            final message = onSave();
                            if (message == null) {
                              Navigator.of(dialogContext).pop();
                            } else {
                              setLocal(() => error = message);
                            }
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AdminColors.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
        ),
      );
    },
  );
}


/// Card photo for a showcase project.
///
/// Shrinks to 1200px on the way in — the card renders at ~400px wide, and
/// a phone-camera original would otherwise be uploaded at full size and
/// then shrunk again server-side for nothing.
class _PhotoPicker extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onPicked;
  const _PhotoPicker({required this.value, required this.onPicked});

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/png';
    onPicked('data:$mime;base64,${base64Encode(bytes)}');
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Card photo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AdminColors.textBase,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: _pick,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 108,
                  height: 72,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AdminColors.statsPlaceholderBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.inputBorder),
                  ),
                  child: hasPhoto
                      ? _Preview(source: value!)
                      : const Text(
                          'Choose…',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.textMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPhoto
                          ? 'Click the image to replace it.'
                          : 'Optional — without one the site shows its '
                                'placeholder pattern.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminColors.textMuted,
                      ),
                    ),
                    if (hasPhoto) ...[
                      const SizedBox(height: 6),
                      _TextButton(
                        label: 'Remove photo',
                        danger: true,
                        onTap: () => onPicked(null),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Photos are data URLs whether freshly picked or loaded from the API, so
/// this always decodes rather than fetching.
class _Preview extends StatelessWidget {
  final String source;
  const _Preview({required this.source});

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      base64Decode(source.split(',').last),
      width: 108,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
    );
  }
}

String _todayIso() => DateTime.now().toIso8601String().substring(0, 10);

/// The date fields are typed, not picked, so a typo would otherwise reach
/// the API as a 422 the admin can't interpret.
bool _isIsoDate(String value) =>
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
    DateTime.tryParse(value) != null;
