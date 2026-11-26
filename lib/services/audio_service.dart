// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../models/id.dart';
import '../models/note.dart';
import 'app_errors.dart';
import 'app_paths.dart';

/// Grabación y reproducción del audio de las notas (todo local, sin red).
///
/// Singleton: solo hay un micrófono y una reproducción a la vez. La UI
/// escucha este [ChangeNotifier] (estado) y [position] (posición en vivo).
class AudioService extends ChangeNotifier {
  AudioService._();
  static final instance = AudioService._();

  AudioRecorder? _recorder;
  AudioPlayer? _player;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _doneSub;

  /// Grabación en curso: nota, inicio (ms desde epoch) y archivo.
  ({int startedAt, String path})? _recording;
  bool get isRecording => _recording != null;
  int? get recordingStartedAt => _recording?.startedAt;

  AudioRecording? _playing;
  AudioRecording? get playing => _playing;
  bool _paused = false;
  bool get isPaused => _paused;

  /// Posición de la reproducción actual.
  final position = ValueNotifier<Duration>(Duration.zero);

  /// Empieza a grabar para [noteId]. Lanza [AppError] si no hay permiso.
  Future<void> start(String noteId) async {
    if (isRecording) return;
    await stopPlayback();
    final rec = _recorder ??= AudioRecorder();
    if (!await rec.hasPermission()) throw const AppError(AppErrorCode.micPermission);
    final dir = await AppPaths.audio(noteId);
    // Linux graba con parecord: WAV lo escribe sin ffmpeg (16 kHz mono ≈ 2 MB/min).
    final linux = Platform.isLinux;
    final path = '${dir.path}/${newId('rec')}.${linux ? 'wav' : 'm4a'}';
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    await rec.start(
        linux
            ? const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1)
            : const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, numChannels: 1),
        path: path);
    _recording = (startedAt: startedAt, path: path);
    notifyListeners();
  }

  /// Termina la grabación y devuelve su ficha (null si no había).
  Future<AudioRecording?> stop() async {
    final r = _recording;
    if (r == null) return null;
    _recording = null;
    await _recorder?.stop();
    notifyListeners();
    return AudioRecording(
      id: r.path.split('/').last.split('.').first,
      path: r.path,
      startedAt: r.startedAt,
      durationMs: DateTime.now().millisecondsSinceEpoch - r.startedAt,
    );
  }

  /// Reproduce [rec] desde [from] (o continúa si ya era la actual y estaba en pausa).
  Future<void> play(String noteId, AudioRecording rec, {Duration? from}) async {
    if (isRecording) return;
    final player = _player ??= AudioPlayer();
    _posSub ??= player.onPositionChanged.listen((p) => position.value = p);
    _doneSub ??= player.onPlayerComplete.listen((_) {
      _paused = true;
      position.value = Duration(milliseconds: _playing?.durationMs ?? 0);
      notifyListeners();
    });
    if (_playing?.id == rec.id && _paused && from == null) {
      await player.resume();
    } else {
      _playing = rec;
      await player.play(DeviceFileSource(rec.path),
          position: from ?? Duration.zero);
      position.value = from ?? Duration.zero;
    }
    _paused = false;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player?.pause();
    _paused = true;
    notifyListeners();
  }

  Future<void> seek(Duration to) async {
    position.value = to;
    await _player?.seek(to);
  }

  /// Cierra la reproducción (la barra desaparece).
  Future<void> stopPlayback() async {
    if (_playing == null) return;
    await _player?.stop();
    _playing = null;
    _paused = false;
    position.value = Duration.zero;
    notifyListeners();
  }

  /// Borra el archivo de una grabación (la ficha la quita el controlador).
  Future<void> deleteFile(String noteId, AudioRecording rec) async {
    if (_playing?.id == rec.id) await stopPlayback();
    final f = File(rec.path);
    if (await f.exists()) await f.delete();
  }
}
