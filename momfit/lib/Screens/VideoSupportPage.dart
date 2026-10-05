import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoSupportPage extends StatefulWidget {
  const VideoSupportPage({super.key});

  @override
  _VideoSupportPageState createState() => _VideoSupportPageState();
}

class _VideoSupportPageState extends State<VideoSupportPage> {
  String searchQuery = "";

  final List<Map<String, String>> videos = [
    {
      "title": "How to Use the App",
      "description": "Learn how to navigate and use all main features of the app.",
      "youtubeId": "dQw4w9WgXcQ",
    },
    {
      "title": "Pregnancy Health Tips",
      "description": "Essential health tips for pregnant women to follow.",
      "youtubeId": "xvFZjo5PgG0",
    },
  ];

  @override
  Widget build(BuildContext context) {

    final filteredVideos = videos.where((video) {
      final desc = video["description"]!.toLowerCase();
      final title = video["title"]!.toLowerCase();
      return desc.contains(searchQuery.toLowerCase()) ||
          title.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade400,
        title: Text(
          "Video Support",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search videos...",
                  prefixIcon: Icon(Icons.search, color: Colors.pink),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filteredVideos.isEmpty
                  ? Center(
                child: Text(
                  "No videos found",
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              )
                  : ListView.builder(
                itemCount: filteredVideos.length,
                itemBuilder: (context, index) {
                  final video = filteredVideos[index];
                  final controller = YoutubePlayerController(
                    initialVideoId: video["youtubeId"]!,
                    flags: const YoutubePlayerFlags(
                      autoPlay: false,
                      mute: false,
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video["title"]!,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video["description"]!,
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: YoutubePlayer(
                              controller: controller,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
