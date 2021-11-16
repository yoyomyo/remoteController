import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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
    localFilePath = 'waterfalls.mp3';

    if (kIsWeb) {
      // Calls to Platform.isIOS fails on web
      return;
    }
    if (Platform.isIOS) {
      cache.fixedPlayer?.notificationService.startHeadlessService();
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
              padding:
                  const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (context) {
                    return const Text(
                      "Music Box",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38.0,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const SizedBox(
                    height: 24.0,
                  ),
                  Center(
                      child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Image.asset("assets/album_cover.jpg",
                            fit: BoxFit.fitWidth)),
                  )),
                  const SizedBox(
                    height: 18.0,
                  ),
                  const Center(
                    child: Text(
                      "Simple Stories",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          //Let's start by adding the controller
                          //let's add the time indicator text
                          SizedBox(
                            width: 500.0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PlayerWidget(url: localFilePath!),
                              ],
                            ),
                          ),
                          /*
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 45.0,
                                color: Colors.blue,
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.skip_previous,
                                ),
                              ),
                              IconButton(
                                iconSize: 62.0,
                                color: Colors.blue.shade800,
                                onPressed: () {
                                  if (!playing) {
                                    cache.play("samples.mp3");
                                    setState(() {
                                      playBtn = Icons.pause;
                                      playing = true;
                                    });
                                  } else {
                                    player.pause();
                                    setState(() {
                                      playBtn = Icons.play_arrow;
                                      playing = false;
                                    });
                                  }
                                },
                                icon: Icon(
                                  playBtn,
                                ),
                              ),
                              IconButton(
                                iconSize: 45.0,
                                color: Colors.blue,
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.skip_next,
                                ),
                              ),
                            ],
                          )*/
                        ],
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }
}
