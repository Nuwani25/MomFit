import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class StressReleaseMusicPage extends StatefulWidget {
  const StressReleaseMusicPage({Key? key}) : super(key: key);

  @override
  State<StressReleaseMusicPage> createState() => _StressReleaseMusicPageState();
}

class _StressReleaseMusicPageState extends State<StressReleaseMusicPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentTrack;

  final List<Map<String, String>> _musicList = [
    {"title": "Meditation", "file": "assets/sounds/Meditation.mp3"},
    {"title": "Nature 1", "file": "assets/sounds/Nature1.mp3"},
    {"title": "Nature 2", "file": "assets/sounds/Nature2.wav"},
    {"title": "Nature 3", "file": "assets/sounds/Nature3.mp3"},
    {"title": "Nature 4", "file": "assets/sounds/Nature4.mp3"},
    {"title": "Nature 5", "file": "assets/sounds/Nature5.mp3"},
    {"title": "Rain 1", "file": "assets/sounds/Rain1.wav"},
    {"title": "Rain 2", "file": "assets/sounds/Rain2.wav"},
    {"title": "Rain 3", "file": "assets/sounds/Rain3.wav"},
    {"title": "Rain 4", "file": "assets/sounds/Rain4.mp3"},
    {"title": "Rain 5", "file": "assets/sounds/Rain5.mp3"},
    {"title": "Rain 6", "file": "assets/sounds/Rain6.mp3"},
  ];

  Future<void> _playPauseMusic(String filePath) async {
    if (_currentTrack == filePath) {
      await _audioPlayer.pause();
      setState(() => _currentTrack = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(filePath.replaceFirst('assets/', '')));
      setState(() => _currentTrack = filePath);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F1), // soft pink
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        title: const Text(
          "Stress Release Music",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _musicList.length,
          itemBuilder: (context, index) {
            final music = _musicList[index];
            final isPlaying = _currentTrack == music["file"];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: isPlaying ? Colors.pink.shade100 : Colors.white,
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.pink.shade400,
                  size: 40,
                ),
                title: Text(
                  music["title"]!,
                  style: TextStyle(
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _playPauseMusic(music["file"]!),
              ),
            );
          },
        ),
      ),
    );
  }
}
