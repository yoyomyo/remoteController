import 'dart:async';
import 'dart:js';

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
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MusicApp(app: app),
  ));
}

// void main() {
//   runApp(const MyApp());
// }

class MusicApp extends StatefulWidget {
  MusicApp({Key? key, required this.app}) : super(key: key);

  final FirebaseApp app;
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  _MusicAppState createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  String? localFilePath;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _counter = 0;
  late DatabaseReference _counterRef;
  late DatabaseReference _connectedRef;
  late StreamSubscription<Event> _counterSubscription;
  DatabaseError? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // web needs the assets path
      localFilePath = 'assets/waterfalls.mp3';
    } else {
      localFilePath = 'waterfalls.mp3';
    }

    // Demonstrates configuring to the database using a file
    _counterRef = FirebaseDatabase.instance.reference().child('player_state');

    // Demonstrates configuring the database directly
    // _counterRef.get().then((DataSnapshot? snapshot) {
    //   _counter = snapshot!.value;
    //   print('Connected to directly configured database and read ${_counter}');
    // });
    _counterSubscription = _counterRef.onValue.listen((Event event) {
      setState(() {
        _error = null;
        _counter = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o as DatabaseError;
      setState(() {
        _error = error;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _counterSubscription.cancel();
  }

  Future<void> _increment() async {
    await _counterRef.set(ServerValue.increment(1));
  }

  Future<void> connect() async {
    final FirebaseDatabase db = FirebaseDatabase.instance;
    // Fetch current user's ID from authentication service
    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;
      // Create reference to this user's specific status node
      // This is where we will store data about being online/offline
      var userStatusRef = db.reference().child('/status/' + uid);

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

      // This is the correct implementation
      FirebaseDatabase.instance
          .reference()
          .child('.info/connected')
          .onValue
          .listen((data) {
        if (data.snapshot.value == false) {
          return;
        }

        userStatusRef.onDisconnect().set(isOfflineForDatabase).then((_) {
          userStatusRef.set(isOnlineForDatabase);
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
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        await _signInAnonymously();
                      },
                      child: const Text('sign in')),
                  ElevatedButton(
                      onPressed: () async {
                        await connect();
                      },
                      child: const Text('connect')),
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
                    height: 30,
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
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [PlayerWidget(url: localFilePath!)],
                        ),
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }
}
