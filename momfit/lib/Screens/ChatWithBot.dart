import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound_record/flutter_sound_record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'base_url.dart';

class ChatWithBot extends StatefulWidget {
  @override
  _ChatWithBotState createState() => _ChatWithBotState();
}

class _ChatWithBotState extends State<ChatWithBot> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  FlutterSoundRecord _audioRecorder = FlutterSoundRecord();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isRecording = false;
  String _filePath = "";

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _audioRecorder.stop();
    _audioRecorder.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({"role": "user", "text": text});
    });
    _controller.clear();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL:1111/chat'),
      );
      request.fields['text'] = text;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var decoded = jsonDecode(responseString);
        String reply = decoded["reply"].toString() ?? "...";

        setState(() {
          _messages.add({
            "role": "bot",
            "text": reply,
          });
        });

      } else {
        Fluttertoast.showToast(msg: "Error from server");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed: $e");
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      Directory tempDir = await getTemporaryDirectory();
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      _filePath = path.join(tempDir.path, "$fileName.mp3");

      await _audioRecorder.start(path: _filePath);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    String? resultPath = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (resultPath != null && resultPath.isNotEmpty) {
      _filePath = resultPath;

      setState(() {
        _messages.add({"role": "user", "audio": _filePath});
      });

      await _uploadAudio();
    } else {
      Fluttertoast.showToast(msg: "Recording failed to save");
    }
  }

  Future<void> _uploadAudio() async {
    if (_filePath.isEmpty) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseURL:1111/voice'),
    );
    request.files.add(await http.MultipartFile.fromPath('audio', _filePath));

    var response = await request.send();
    var responseString = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var decoded = jsonDecode(responseString);
      String reply = decoded["reply"] ?? "[Voice processed]";

      setState(() {
        _messages.add({
          "role": "bot",
          "text": reply,
        });
      });

    } else {
      Fluttertoast.showToast(msg: "Voice upload failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Support"),
        backgroundColor: Colors.pink[400],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.pink[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: msg.containsKey("audio")
                        ? _buildAudioBubble(msg["audio"], isUser)
                        : _buildTextBubble(msg["text"], isUser),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.pink[400]),
                  onPressed: () => _sendMessage(_controller.text),
                ),
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: CircleAvatar(
                    backgroundColor:
                    _isRecording ? Colors.red : Colors.pink[400],
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBubble(String text, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.volume_up,
              color: isUser ? Colors.white : Colors.black54, size: 20),
          onPressed: () async {
            await _flutterTts.stop();
            await _flutterTts.speak(text);
          },
        ),
      ],
    );
  }

  Widget _buildAudioBubble(String filePath, bool isUser) {
    AudioPlayer player = AudioPlayer();
    bool isPlaying = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
                color: isUser ? Colors.white : Colors.black,
              ),
              onPressed: () async {
                if (isPlaying) {
                  await player.stop();
                  setState(() => isPlaying = false);
                } else {
                  await player.play(DeviceFileSource(filePath));
                  setState(() => isPlaying = true);
                  player.onPlayerComplete.listen((_) {
                    setState(() => isPlaying = false);
                  });
                }
              },
            ),
            Text(
              "Voice message",
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        );
      },
    );
  }
}
