import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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
  //we will need some variables
  bool playing = false; // at the begining we are not playing any song
  IconData playBtn = Icons.play_arrow; // the main state of the play button icon

  AudioPlayer player = AudioPlayer();
  AudioCache? cache;
  String? localFilePath;
  String? localAudioCacheURI;

  Duration position = Duration();
  Duration musicLength = Duration(seconds: 4 * 60 + 19);

  //we will create a custom slider
  Widget slider() {
    return SizedBox(
      width: 200.0,
      child: Slider.adaptive(
          activeColor: Colors.blue.shade800,
          inactiveColor: Colors.grey.shade300,
          value: 100.0,
          max: musicLength.inSeconds.toDouble(),
          onChanged: (v) {
            seekToSec(v.toInt());
          }),
    );
  }

  //let's create the seek function that will allow us to go to a certain position of the music
  void seekToSec(int sec) {
    Duration newPos = Duration(seconds: sec);
    player.seek(newPos);
  }

  @override
  void initState() {
    super.initState();

    cache = AudioCache(fixedPlayer: player);

    //now let's handle the audioplayer time

    //this function will allow you to get the music duration
    player.onDurationChanged.listen((Duration d) {
      print('Max duration: $d');
      setState(() {
        musicLength = d;
      });
    });

    //this function will allow us to move the cursor of the slider while we are playing the song
    //   player.positionHandler = (p) {
    //     setState(() {
    //       position = p;
    //     });
    //   };

    //   player.onAudioPositionChanged.listen((Duration ) { })
    // }
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
                                Text(
                                  "${position.inMinutes}:${position.inSeconds.remainder(60)}",
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                  ),
                                ),
                                slider(),
                                Text(
                                  "${musicLength.inMinutes}:${musicLength.inSeconds.remainder(60)}",
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                  //here we will add the functionality of the play button
                                  if (!playing) {
                                    //now let's play the song
                                    cache?.play("samples.mp3");
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
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }
}
