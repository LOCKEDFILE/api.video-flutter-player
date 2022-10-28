import 'package:apivideo_player/apivideo_player.dart';
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
  final ApiVideoPlayerController _controller = ApiVideoPlayerController(
    videoOptions: VideoOptions(videoId: 'vi3CjYlusQKz6JN7au0EmW9b'),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            buildPreview(controller: _controller),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  _controller.seek(Duration(seconds: -10));
                },
              ),
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
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  _controller.seek(Duration(seconds: 10));
                },
              ),
            ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_off),
                  onPressed: () {
                    _controller.setIsMuted(true);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    _controller.setIsMuted(false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int> initialize() async {
    await _controller.initialize();
    return 0;
  }

  Widget buildPreview({required ApiVideoPlayerController controller}) {
    // Wait for [LiveStreamController.create] to finish.
    return FutureBuilder<void>(
        future: initialize(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (!snapshot.hasData) {
            // while data is loading:
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ApiVideoPlayer(controller: controller);
          }
        });
  }
}
