import 'package:apivideo_player/apivideo_player.dart';
import 'package:apivideo_player/apivideo_player_controller.dart';
import 'package:apivideo_player/apivideo_types.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiVideoPlayerController _controller;

  void _onViewCreated(ApiVideoPlayerController controller) {
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            SizedBox(
                width: 400.0,
                height: 300.0,
                child: ApiVideoPlayer(
                    videoId: 'vi3CjYlusQKz6JN7au0EmW9b',
                    videoType: VideoType.vod,
                    onViewCreated: _onViewCreated)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    _controller.play();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    _controller.pause();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
