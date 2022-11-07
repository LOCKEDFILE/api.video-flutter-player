import 'dart:async';
import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util';

import 'package:apivideo_player/src/javascript_controller.dart'
    as js_controller;
import 'package:flutter/material.dart';
import 'package:flutter_html/shims/dart_ui.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'apivideo_player_platform_interface.dart';
import 'apivideo_types.dart';

/// A web implementation of the ApiVideoPlayerPlatform of the ApiVideoPlayer plugin.
class ApiVideoPlayerPlugin extends ApiVideoPlayerPlatform {
  /// Registers this class as the default instance of [PathProviderPlatform].
  static void registerWith(Registrar registrar) {
    ApiVideoPlayerPlatform.instance = ApiVideoPlayerPlugin();
  }

  int _textureCounter = -1;
  late bool _autoplay;
  final Map<int, VideoOptions> _videoOptions = {};
  final Map<int, StreamController<PlayerEvent>> _streamControllers = {};

  @override
  Future<int?> initialize(bool autoplay) async {
    _autoplay = autoplay;
    return ++_textureCounter;
  }

  @override
  Future<void> create(int textureId, VideoOptions videoOptions) async {
    final DivElement videoElement = DivElement()
      ..id = 'playerDiv$textureId'
      ..style.height = '100%'
      ..style.width = '100%';

    platformViewRegistry.registerViewFactory(
        'playerDiv$textureId', (int viewId) => videoElement);

    _videoOptions[textureId] = videoOptions;
  }

  @override
  Future<void> dispose(int textureId) async {
    _videoOptions.remove(textureId);
    document.querySelector('#playerDiv$textureId')?.remove();
    document.querySelector('#apiVideoPlayerJsScript$textureId')?.remove();
    return;
  }

  @override
  Future<VideoOptions> getVideoOptions(int textureId) async {
    if (_videoOptions[textureId] == null) {
      throw Exception('No video options found for this texture id: $textureId');
    }
    return _videoOptions[textureId]!;
  }

  @override
  Future<void> setVideoOptions(int textureId, VideoOptions videoOptions) async {
    js_controller.loadConfig(
      'player$textureId',
      mapToJsObject({'id': videoOptions.videoId}),
    );
    return;
  }

  @override
  Future<bool> isPlaying(int textureId) async => await _getPromiseFromJs<bool>(
        textureId: textureId,
        jsMethod: () => js_controller.getPlayingFromJs('player$textureId'),
      );

  @override
  Future<int> getCurrentTime(int textureId) async {
    final currentTime = await _getPromiseFromJs<double>(
      textureId: textureId,
      jsMethod: () => js_controller.getCurrentTimeFromJs('player$textureId'),
    );
    return _secondsToMilliseconds(seconds: currentTime);
  }

  @override
  Future<void> setCurrentTime(int textureId, int currentTime) async =>
      _callJsMethod(
        textureId: textureId,
        jsMethodName: 'setCurrentTime',
        args: [currentTime ~/ 1000],
      );

  @override
  Future<int> getDuration(int textureId) async {
    final duration = await _getPromiseFromJs<double>(
      textureId: textureId,
      jsMethod: () => js_controller.getDurationFromJs('player$textureId'),
    );
    return _secondsToMilliseconds(seconds: duration);
  }

  @override
  Future<void> play(int textureId) async =>
      _callJsMethod(textureId: textureId, jsMethodName: 'play');

  @override
  Future<void> pause(int textureId) async =>
      _callJsMethod(textureId: textureId, jsMethodName: 'pause');

  @override
  Future<void> seek(int textureId, int offset) async => _callJsMethod(
      textureId: textureId, jsMethodName: 'seek', args: [offset ~/ 1000]);

  @override
  Future<double> getVolume(int textureId) => _getPromiseFromJs<double>(
        textureId: textureId,
        jsMethod: () => js_controller.getVolume('player$textureId'),
      );

  @override
  Future<void> setVolume(int textureId, double volume) => _callJsMethod(
        textureId: textureId,
        jsMethodName: 'setVolume',
        args: [volume],
      );

  @override
  Future<bool> getIsMuted(int textureId) => _getPromiseFromJs<bool>(
        textureId: textureId,
        jsMethod: () => js_controller.getMuted('player$textureId'),
      );

  @override
  Future<void> setIsMuted(int textureId, bool isMuted) => _callJsMethod(
        textureId: textureId,
        jsMethodName: isMuted ? 'mute' : 'unmute',
      );

  @override
  Future<bool> getAutoplay(int textureId) async => _autoplay;

  @override
  Future<void> setAutoplay(int textureId, bool autoplay) {
    _autoplay = autoplay;
    return _callJsMethod(
      textureId: textureId,
      jsMethodName: 'setAutoplay',
      args: [autoplay],
    );
  }

  @override
  Future<bool> getIsLooping(int textureId) => _getPromiseFromJs<bool>(
        textureId: textureId,
        jsMethod: () => js_controller.getLoop('player$textureId'),
      );

  @override
  Future<void> setIsLooping(int textureId, bool isLooping) => _callJsMethod(
        textureId: textureId,
        jsMethodName: 'setLoop',
        args: [isLooping],
      );

  @override
  Stream<PlayerEvent> playerEventsFor(int textureId) {
    final streamController = StreamController<PlayerEvent>();
    _streamControllers[textureId] = streamController;
    return streamController.stream;
  }

  @override
  Widget buildView(int textureId) {
    if (_videoOptions[textureId] == null) {
      throw ArgumentError('videos options must be provided');
    }

    void injectScripts() {
      if (document.body?.querySelector('#playersState') == null) {
        const String jsString = '''
          window.state = {
            getCurrentTime: async function(playerId) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].getCurrentTime();
            },
            setCurrentTime: async function(playerId, currentTime) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].setCurrentTime(currentTime);
            },
            getDuration: async function(playerId) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].getDuration();
            },
            getPlaying: async function(playerId) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].getPlaying();
            },
            getMuted: async function(playerId) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].getMuted();
            },
            getLoop: async function(playerId) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].getLoop();
            },
            getVolume: async function(playerId) {
              if (!playerId || !window[playerId]) return;
              return await window[playerId].getVolume();
            },
            loadConfig: function(playerId, videoOptions) {
              if (!playerId || !window[playerId]) return;
              console.log(videoOptions);
              window[playerId].loadConfig(videoOptions);
            }
          };
        ''';
        final ScriptElement script = ScriptElement()
          ..id = 'playersState'
          ..innerText = jsString;
        script.innerHtml = script.innerHtml?.replaceAll('<br>', '');
        document.body?.insertAdjacentElement('beforeend', script);
      }

      final String jsString = '''
        window.player$textureId = new PlayerSdk(
          "#playerDiv$textureId",
          { 
            id: "${_videoOptions[textureId]!.videoId}",
            chromeless: true,
            live: ${_videoOptions[textureId]!.videoType == VideoType.live},
            autoplay: $_autoplay,
          }
        );
      ''';
      final ScriptElement script = ScriptElement()
        ..id = 'apiVideoPlayerJsScript$textureId'
        ..innerText = jsString;
      script.innerHtml = script.innerHtml?.replaceAll('<br>', '');
      document.body?.insertAdjacentElement('beforeend', script);

      if (_streamControllers[textureId] == null) {
        throw Exception('No stream controller for this texture id: $textureId');
      }
      for (var playerEvent in PlayerEventType.values) {
        _callJsMethod(
          textureId: textureId,
          jsMethodName: 'addEventListener',
          args: [
            playerEvent.displayPlayerSdkName,
            () => _streamControllers[textureId]!
                .add(PlayerEvent(type: playerEvent)),
          ],
        );
      }
    }

    return HtmlElementView(
      viewType: 'playerDiv$textureId',
      onPlatformViewCreated: (id) => injectScripts(),
    );
  }

  /// Calls a JS object method that returns void only.
  Future<void> _callJsMethod({
    required int textureId,
    required String jsMethodName,
    List<dynamic>? args,
  }) async {
    ArgumentError.checkNotNull(js.context['player$textureId'], 'player');
    js.JsObject.fromBrowserObject(js.context['player$textureId']).callMethod(
      jsMethodName,
      args,
    );
    return;
  }

  /// Handle a JS [Promise] that returns a value other than void
  /// and parse it into a Dart [Future].
  Future<T> _getPromiseFromJs<T>({
    required int textureId,
    required Function jsMethod,
  }) async {
    ArgumentError.checkNotNull(js.context['player$textureId'], 'player');
    ArgumentError.checkNotNull(js.context['state'], 'state');
    return await promiseToFuture(
      jsMethod(),
    );
  }

  /// Converts seconds into milliseconds.
  int _secondsToMilliseconds({required double seconds}) =>
      int.parse((seconds * 1000).toStringAsFixed(0));

  /// Converts a [Map] to a [JS object]
  Object mapToJsObject(Map map) {
    var object = newObject();
    map.forEach((k, v) {
      if (v is Map) {
        setProperty(object, k, mapToJsObject(v));
      } else {
        setProperty(object, k, v);
      }
    });
    return object;
  }
}
