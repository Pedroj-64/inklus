// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';
import '../../logic/canvas_controller.dart';
import '../../models/note.dart';
import '../../services/app_errors.dart';
import '../../services/audio_service.dart';
import '../theme/inklus_colors.dart';
import '../theme/tokens.dart';
import '../widgets/dialogs.dart';
import '../widgets/page_scaffold.dart';

String _fmt(Duration d) {
  final s = d.inSeconds;
  final h = s ~/ 3600, m = (s ~/ 60) % 60, sec = s % 60;
  final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
  return '${h > 0 ? '$h:' : ''}$mm:${sec.toString().padLeft(2, '0')}';
}

/// Termina la grabación en curso (si es de esta nota) y la guarda en ella.
/// Se llama al salir del editor.
Future<void> finishRecording(CanvasController c) async {
  final audio = AudioService.instance;
  if (!audio.isRecording) {
    await audio.stopPlayback();
    return;
  }
  final rec = await audio.stop();
  c.recordingStartedAt = null;
  if (rec != null) c.addRecording(rec);
}

/// Botón de micrófono de la barra del editor.
/// - Sin grabaciones: empieza a grabar. Grabando: para (muestra el tiempo).
/// - Con grabaciones: abre la lista (grabar otra, reproducir, borrar).
class AudioButton extends StatelessWidget {
  const AudioButton({super.key, required this.controller});

  final CanvasController controller;

  AudioService get _audio => AudioService.instance;

  Future<void> _start(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _audio.start(controller.note.id);
      controller.recordingStartedAt = _audio.recordingStartedAt;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(userError(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _audio,
        builder: (context, _) {
          if (_audio.isRecording) {
            return _RecordingChip(onStop: () => finishRecording(controller));
          }
          return IconButton(
            tooltip: context.l10n.audioRecord,
            icon: const Icon(Icons.mic_none),
            onPressed: () => controller.note.recordings.isEmpty
                ? _start(context)
                : showRecordingsSheet(context, controller, onRecord: () => _start(context)),
          );
        },
      );
}

class _RecordingChip extends StatefulWidget {
  const _RecordingChip({required this.onStop});
  final VoidCallback onStop;

  @override
  State<_RecordingChip> createState() => _RecordingChipState();
}

class _RecordingChipState extends State<_RecordingChip> {
  late final Timer _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = AudioService.instance.recordingStartedAt ?? 0;
    final elapsed = Duration(milliseconds: DateTime.now().millisecondsSinceEpoch - start);
    return Tooltip(
      message: context.l10n.audioStop,
      child: ActionChip(
        avatar: Icon(Icons.stop_circle, color: context.inklus.danger),
        label: Text(_fmt(elapsed)),
        onPressed: widget.onStop,
      ),
    );
  }
}

/// Lista de grabaciones de la nota.
Future<void> showRecordingsSheet(
  BuildContext context,
  CanvasController controller, {
  required VoidCallback onRecord,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (sheet, _) {
            final recs = controller.note.recordings;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SheetHeader(
                  icon: Icons.mic_none,
                  title: sheet.l10n.audioTitle,
                  subtitle: sheet.l10n.audioHint,
                ),
                ListTile(
                  leading: Icon(Icons.fiber_manual_record, color: sheet.inklus.danger),
                  title: Text(sheet.l10n.audioRecordNew),
                  onTap: () {
                    Navigator.pop(sheet);
                    onRecord();
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final (i, r) in recs.indexed)
                        ListTile(
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(sheet.l10n.audioItem(i + 1)),
                          subtitle: Text(
                              '${MaterialLocalizations.of(sheet).formatShortDate(DateTime.fromMillisecondsSinceEpoch(r.startedAt))} · ${_fmt(Duration(milliseconds: r.durationMs))}'),
                          onTap: () {
                            Navigator.pop(sheet);
                            AudioService.instance.play(controller.note.id, r);
                          },
                          trailing: IconButton(
                            tooltip: sheet.l10n.libDelete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(sheet, controller, r),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

Future<void> _delete(BuildContext context, CanvasController c, AudioRecording r) async {
  final ok = await showConfirmDialog(
    context,
    title: context.l10n.audioDeleteTitle,
    message: context.l10n.audioDeleteBody,
    confirmLabel: context.l10n.libDelete,
    destructive: true,
  );
  if (!ok) return;
  await AudioService.instance.deleteFile(c.note.id, r);
  c.removeRecording(r.id);
}

/// Barra de reproducción: aparece mientras suena una grabación. La escritura
/// posterior al instante actual se ve tenue y tocar un trazo (con el dedo)
/// salta a cuando se escribió.
class AudioReplayBar extends StatefulWidget {
  const AudioReplayBar({super.key, required this.controller});
  final CanvasController controller;

  @override
  State<AudioReplayBar> createState() => _AudioReplayBarState();
}

class _AudioReplayBarState extends State<AudioReplayBar> {
  AudioService get _audio => AudioService.instance;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_sync);
    _audio.position.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    _audio.removeListener(_sync);
    _audio.position.removeListener(_sync);
    widget.controller.onCanvasTap = null;
    super.dispose();
  }

  void _sync() {
    final c = widget.controller;
    final rec = _audio.playing;
    c.setReplayUntil(rec == null ? null : rec.startedAt + _audio.position.value.inMilliseconds);
    c.onCanvasTap = rec == null ? null : _seekToStrokeAt;
    if (mounted) setState(() {});
  }

  bool _seekToStrokeAt(Offset world) {
    final c = widget.controller;
    final hit = c.strokeAt(world);
    final target = hit == null ? null : c.recordingAtStroke(hit);
    if (target == null) return false;
    _audio.play(c.note.id, target.rec, from: target.at);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final rec = _audio.playing;
    if (rec == null) return const SizedBox.shrink();
    final total = Duration(milliseconds: rec.durationMs);
    final pos = _audio.position.value;
    return Material(
      elevation: 3,
      color: context.inklus.toolbar,
      borderRadius: Radii.xlAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        child: SizedBox(
          width: 420,
          child: Row(
            children: [
              IconButton(
                tooltip: _audio.isPaused ? context.l10n.audioPlay : context.l10n.audioPause,
                icon: Icon(_audio.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () => _audio.isPaused
                    ? _audio.play(widget.controller.note.id, rec,
                        from: pos >= total ? Duration.zero : null)
                    : _audio.pause(),
              ),
              Text(_fmt(pos), style: context.text.labelMedium),
              Expanded(
                child: Slider(
                  value: pos.inMilliseconds.clamp(0, rec.durationMs).toDouble(),
                  max: rec.durationMs <= 0 ? 1 : rec.durationMs.toDouble(),
                  onChanged: (v) => _audio.seek(Duration(milliseconds: v.round())),
                ),
              ),
              Text(_fmt(total), style: context.text.labelMedium),
              IconButton(
                tooltip: context.l10n.commonClose,
                icon: const Icon(Icons.close),
                onPressed: _audio.stopPlayback,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
