import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'player_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp app = await Firebase.initializeApp();
  runApp(
    MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MusicApp(app: app),
        theme: ThemeData(primaryColor: Colors.blue.shade900)),
  );
}

class MusicApp extends StatefulWidget {
  MusicApp({Key? key, required this.app}) : super(key: key);

  final FirebaseApp app;
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _MusicAppState createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  String? localFilePath;
  late DataSync dataSync = DataSync();

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
  void dispose() {
    super.dispose();
  }

  void _handleClick(String value) async {
    switch (value) {
      case 'Sign in':
        await dataSync._signInAnonymously();
        break;
      case 'Connect':
        await dataSync._connect();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Music Box'),
          backgroundColor: Colors.blue.shade800,
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: _handleClick,
              itemBuilder: (BuildContext context) {
                return {'Sign in', 'Connect'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ],
        ),
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
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                            child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
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
                              const BorderRadius.all(Radius.circular(25.0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            PlayerWidget(
                                url: localFilePath!,
                                playerStateRef: FirebaseDatabase.instance
                                    .reference()
                                    .child('/player'))
                          ],
                        ),
                      ),
                    ),
                  ],
                ))));
  }
}

class DataSync {
  late FirebaseAuth _auth;
  DatabaseError? _error;

  DataSync() {
    _auth = FirebaseAuth.instance;
  }

  Future<void> _connect() async {
    final FirebaseDatabase db = FirebaseDatabase.instance;
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      // Create reference to this device's specific status node
      // This is where we will store data about being online/offline
      // Change to FID later
      var deviceStatusRef = db.reference().child('/devices/${uid}');

      // We'll create two constants which we will write to the
      // Realtime database when this device is offline or online
      var isOfflineForDatabase = {
        'state': 'offline',
        'last_changed': ServerValue.timestamp,
      };
      var isOnlineForDatabase = {
        'state': 'online',
        'last_changed': ServerValue.timestamp,
      };

      FirebaseDatabase.instance
          .reference()
          .child('.info/connected')
          .onValue
          .listen((data) {
        if (data.snapshot.value == false) {
          return;
        }

        deviceStatusRef.onDisconnect().set(isOfflineForDatabase).then((_) {
          deviceStatusRef.set(isOnlineForDatabase);
        });
      });
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final User user = (await _auth.signInAnonymously()).user!;
      print('sign in Anonymously. ${user}');
    } catch (e) {
      print('Failed to sign in Anonymously. ${e}');
    }
  }
}
