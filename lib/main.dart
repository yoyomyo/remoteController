import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'player_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicApp(),
    );
  }
}

class MusicApp extends StatefulWidget {
  const MusicApp({Key? key}) : super(key: key);

  @override
  _MusicAppState createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  bool playing = false;
  IconData playBtn = Icons.play_arrow;

  AudioPlayer player = AudioPlayer();
  AudioCache cache = AudioCache();
  String? localFilePath;
  String? localAudioCacheURI;

  Duration position = Duration();

  void seekToSec(int sec) {
    Duration newPos = Duration(seconds: sec);
    player.seek(newPos);
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // web needs the assets path
      localFilePath = 'assets/waterfalls.mp3';
    } else {
      localFilePath = 'waterfalls.mp3';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade900,
                    Colors.purple.shade200,
                  ]),
            ),
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 36.0, horizontal: 24.0),
                child: ListView(
                  children: [
                    const Center(
                        child: Text(
                      "Music Box",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38.0,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                    const SizedBox(
                      height: 24.0,
                    ),
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                            child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: Image.asset("assets/album_cover.jpg",
                              fit: BoxFit.contain),
                        ))),
                    const SizedBox(
                      height: 18.0,
                    ),
                    const Center(
                      child: Text(
                        "Simple Stories",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30.0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [PlayerWidget(url: localFilePath!)],
                        ),
                      ),
                    ),
                  ],
                ))));
  }
}
