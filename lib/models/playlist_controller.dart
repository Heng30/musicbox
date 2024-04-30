import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';

import './song.dart';

class PlaylistController extends GetxController {
  final playlist = [
    Song(
      songName: "泪桥-1",
      artistName: "古巨基",
      albumArtImagePath: "assets/images/1.png",
      audioPath: "audio/leiqiao.mp3",
    ),
    Song(
      songName: "泪桥-2",
      artistName: "周深",
      albumArtImagePath: "assets/images/2.png",
      audioPath: "audio/leiqiao.mp3",
    ),
    Song(
      songName: "泪桥-3",
      artistName: "古巨基 && 周深",
      albumArtImagePath: "assets/images/3.png",
      audioPath: "audio/leiqiao.mp3",
    ),
  ].obs;

  RxInt? _currentSongIndex = 0.obs;
  int get currentSongIndex => _currentSongIndex!.value;

  set currentSongIndex(int? index) {
    if (index == null) {
      _currentSongIndex = null;
    } else {
      if (_currentSongIndex == null) {
        _currentSongIndex = index.obs;
      } else {
        _currentSongIndex!.value = index;
      }

      play();
    }
  }

  void toggleFavorite() {
    playlist[_currentSongIndex!.value].isFavorite =
        !playlist[_currentSongIndex!.value].isFavorite;
  }

  final _audioPlayer = AudioPlayer();
  final _isPlaying = false.obs;
  final _currentDuration = Duration.zero.obs;
  final _totalDuration = Duration.zero.obs;

  bool get isPlaying => _isPlaying.value;
  Duration get currentDuration => _currentDuration.value;
  Duration get totalDuration => _totalDuration.value;

  PlaylistController() {
    listenToDuration();
  }

  void play() async {
    if (playlist.isEmpty) {
      return;
    }

    final path = playlist[_currentSongIndex!.value].audioPath;
    await _audioPlayer.stop(); // stop the current song
    await _audioPlayer.play(AssetSource(path));
    _isPlaying.value = true;
  }

  void stop() async {
    if (playlist.isEmpty) {
      return;
    }
    await _audioPlayer.stop(); // stop the current song
    _isPlaying.value = false;
  }

  void pause() async {
    await _audioPlayer.pause();
    _isPlaying.value = false;
  }

  void resume() async {
    await _audioPlayer.resume();
    _isPlaying.value = true;
  }

  void pauseOrResume() async {
    if (_isPlaying.value) {
      pause();
    } else {
      resume();
    }
  }

  void seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void playNextSong() {
    if (playlist.isEmpty) {
      return;
    }

    if (_currentSongIndex != null) {
      stop();

      if (_currentSongIndex!.value < playlist.length - 1) {
        _currentSongIndex!.value += 1;
      } else {
        _currentSongIndex!.value = 0;
      }

      play();
    }
  }

  void playPreviousSong() {
    if (playlist.isEmpty) {
      return;
    }

    if (_currentDuration.value.inSeconds > 2) {
      seek(Duration.zero);
    } else {
      stop();
      if (_currentSongIndex!.value > 0) {
        _currentSongIndex!.value -= 1;
      } else {
        _currentSongIndex!.value = playlist.length - 1;
      }
      play();
    }
  }

  void listenToDuration() {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration.value = newDuration;
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentDuration.value = newPosition;
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      playNextSong();
    });
  }
}
