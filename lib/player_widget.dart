// Adapted from https://github.com/bluefireteam/audioplayers/blob/master/packages/audioplayers/example/lib/player_widget.dart

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlayerWidget extends StatefulWidget {
  final String url;
  final PlayerMode mode;
  final DatabaseReference playerStateRef;
  late _PlayerWidgetState playerWidgetState;

  PlayerWidget(
      {Key? key,
      required this.url,
      this.mode = PlayerMode.MEDIA_PLAYER,
      required this.playerStateRef})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    playerWidgetState = _PlayerWidgetState(url, mode, playerStateRef);
    return playerWidgetState;
  }

  void listenToChange(bool isSubscriber) {
    playerWidgetState.listenToChange(isSubscriber);
    print('player start to listen to DB change, isSubscriber {$isSubscriber}');
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  String _url;
  PlayerMode mode;
  DatabaseReference playerStateRef;
  DatabaseError? _error;

  late StreamSubscription<Event> _playerDBSubscription;
  late bool _isSubscriber = true;

  late AudioPlayer _audioPlayer;
  late AudioCache _audioCache;
  late String _selectLocation;

  //PlayerState? _audioPlayerState;
  // TODO: remove hard coded duration
  Duration? _duration = Duration(seconds: 2 * 60 + 26);
  Duration? _position;

  PlayerState _playerState = PlayerState.STOPPED;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerErrorSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription<PlayerControlCommand>? _playerControlCommandSubscription;
  Stream<QuerySnapshot>? _song;

  String get _durationText => _durationToString(_duration);

  String get _positionText => _durationToString(_position);

  _PlayerWidgetState(this._url, this.mode, this.playerStateRef);

  late Slider _slider;
  late double _sliderPosition;

  late Slider _slider;
  late double _sliderPosition;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _sliderPosition = 0.0;
    _song = FirebaseFirestore.instance.collection('songlist').snapshots();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _playerControlCommandSubscription?.cancel();

    _playerDBSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _slider = Slider(onChanged: _onSliderChangeHandler, value: _sliderPosition);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _song,
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Something went wrong');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text("Loading");
                        }

                        return DropdownButton<String>(
                          value: _url,
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _url = newValue;
                                if (_playerState == PlayerState.PLAYING) {
                                  _position = const Duration();
                                  _play();
                                }
                              });
                            }
                          },
                          iconEnabledColor: Colors.deepPurpleAccent,
                          style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 16),
                          underline: Text(''),
                          items: snapshot.data!.docs
                              .map((DocumentSnapshot document) {
                            Map<String, dynamic> data =
                                document.data()! as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: data['url'],
                              child: Text(data['songname']),
                            );
                          }).toList(),
                        );
                      },
                    )
                  ]),
              Row(
                children: [
                  Text(
                    _position != null ? '$_positionText' : '00:00',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: _slider,
                  ),
                  Text(
                    _duration != null ? _durationText : '00:00',
                    style: const TextStyle(fontSize: 18.0),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('fastforward_button'),
                    onPressed: _forward,
                    iconSize: 48.0,
                    icon: const Icon(Icons.fast_forward),
                    color: Colors.blue.shade500,
                  ),
                  IconButton(
                    key: const Key('play_button'),
                    onPressed:
                        _playerState == PlayerState.PLAYING ? _pause : _play,
                    iconSize: 48.0,
                    icon: _playerState == PlayerState.PLAYING
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                    color: Colors.blue.shade500,
                  ),
                  IconButton(
                    key: const Key('rewind_button'),
                    onPressed: _rewind,
                    iconSize: 48.0,
                    icon: const Icon(Icons.fast_rewind),
                    color: Colors.blue.shade500,
                  ),
                ],
              ),
              Text('State: $_playerState'),
            ],
          ),
        ),
      ],
    );
  }

  void _onSongChange(v) {
    setState(() {});
  }

  void _onSliderChangeHandler(v) {
    final duration = _duration;
    if (duration == null) {
      return;
    }
    final Position = v * duration.inMilliseconds;
    _sliderPosition = v;
    _position = Duration(milliseconds: Position.round());
    _audioPlayer.seek(_position!);

    _updatePlayerDBState();
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: mode);
    _audioCache = AudioCache(fixedPlayer: _audioPlayer);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // optional: listen for notification updates in the background
        _audioPlayer.notificationService.startHeadlessService();

        // set at least title to see the notification bar on ios.
        _audioPlayer.notificationService.setNotification(
          title: 'App Name',
          artist: 'Artist or blank',
          albumTitle: 'Name or blank',
          imageUrl: 'Image URL or blank',
          forwardSkipInterval: const Duration(seconds: 30),
          // default is 30s
          backwardSkipInterval: const Duration(seconds: 30),
          // default is 30s
          duration: duration,
          enableNextTrackButton: true,
          enablePreviousTrackButton: true,
        );
      }
    });

    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
              if (kIsWeb && _playerState == PlayerState.PAUSED) {
                return;
              }
              _position = p;
              if (_position == _duration) {
                _onComplete();
              }
            }));

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() {
        _position = const Duration();
      });
    });

    _playerStateSubscription =
        _audioPlayer.onPlayerStateChanged.listen((state) {
      print('Current player state: $state');
      setState(() => _playerState = state);
    });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.STOPPED;
        _duration = const Duration();
        _position = const Duration();
      });
    });

    _playerControlCommandSubscription =
        _audioPlayer.notificationService.onPlayerCommand.listen((command) {
      print('command: $command');
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _audioPlayer.onNotificationPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });
  }

  Future<int> _play() async {
    final playPosition = (_position != null &&
            _duration != null &&
            _position!.inMilliseconds > 0 &&
            _position!.inMilliseconds < _duration!.inMilliseconds)
        ? _position
        : null;
    var result = 0;
    if (kIsWeb) {
      result =
          await _audioPlayer.play("assets/" + _url, position: playPosition);
      if (result == 1) {
        setState(() => _playerState = PlayerState.PLAYING);
      }
    } else {
      _audioCache.play(_url);
      _playerState = PlayerState.PLAYING;
    }
    _updatePlayerDBState();
    return result;
  }

  Future<int> _pause() async {
    final playPosition = (_position != null &&
            _duration != null &&
            _position!.inMilliseconds > 0 &&
            _position!.inMilliseconds < _duration!.inMilliseconds)
        ? _position
        : null;
    final result = await _audioPlayer.pause();
    if (result == 1) {
      setState(() => {_playerState = PlayerState.PAUSED});
    }
    _updatePlayerDBState();
    return result;
  }

  Future<int> _rewind() async {
    Duration _tempPosition =
        Duration(seconds: max(0, _position!.inSeconds - 10));
    var result = await _seek(_tempPosition);
    return result;
  }

  Future<int> _seek(Duration _tempPosition) async {
    var result = await _audioPlayer.seek(_tempPosition);
    if (result == 1) {
      setState(() => _position = _tempPosition);
    }
    return result;
  }

  Future<int> _forward() async {
    Duration _tempPosition =
        Duration(seconds: min(_duration!.inSeconds, _position!.inSeconds + 10));
    var result = await _seek(_tempPosition);
    return result;
  }

  //
  // Future<int> _stop() async {
  //   final result = await _audioPlayer.stop();
  //   if (result == 1) {
  //     setState(() {
  //       _playerState = PlayerState.STOPPED;
  //       _position = const Duration();
  //     });
  //   }
  //   return result;
  // }

  void _onComplete() {
    setState(() {
      _playerState = PlayerState.STOPPED;
    });
  }

  void _updatePlayerDBState() async {
    if (_isSubscriber) {
      // subscribers do not need to udpate DB
      return;
    }
    try {
      var playerSnapshot = {
        'state': _playerState.index,
        'slider_position': _slider.value
      };
      playerStateRef.set(playerSnapshot);
    } catch (e) {
      print('updated playerState with error');
    }
  }

  // convert duration to [HH:]mm:ss format
  String _durationToString(Duration? duration) {
    String twoDigits(n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration?.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration?.inSeconds.remainder(60));
    if (duration?.inHours == 0) {
      return '${twoDigitMinutes}:${twoDigitSeconds}';
    }
    return '${twoDigits(duration?.inHours)}:${twoDigitMinutes}:${twoDigitSeconds}';
  }

  void listenToChange(bool isSubscriber) async {
    _isSubscriber = isSubscriber;
    if (_isSubscriber) {
      _playerDBSubscription = playerStateRef.onValue.listen((Event event) {
        setState(() {
          _error = null;
          if (event != null && event.snapshot != null) {
            int state = event.snapshot.value['state'];
            _playerState = PlayerState.values[state];
            switch (_playerState) {
              case PlayerState.PLAYING:
                _play();
                break;
              case PlayerState.PAUSED:
                _pause();
                break;
            }
            try {
              setState(() {
                _sliderPosition = event.snapshot.value['slider_position'];
                _slider.onChanged!(_sliderPosition);
              });
            } catch (e) {
              print('trouble updating slider');
            }
          }
        });
      }, onError: (Object o) {
        final DatabaseError error = o as DatabaseError;
        setState(() {
          _error = error;
        });
      });
    }
  }
}
