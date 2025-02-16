import 'dart:async';

import 'package:apivideo_player/apivideo_player.dart';
import 'package:apivideo_player/src/apivideo_player_life_cycle_observer.dart';
import 'package:apivideo_player/src/apivideo_types.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'apivideo_player_platform_interface.dart';

ApiVideoPlayerPlatform get _playerPlatform {
  return ApiVideoPlayerPlatform.instance;
}

class ApiVideoPlayerController {
  final VideoOptions _initialVideoOptions;
  final bool _initialAutoplay;

  static const int kUninitializedTextureId = -1;
  int _textureId = kUninitializedTextureId;

  StreamSubscription<dynamic>? _eventSubscription;
  List<ApiVideoPlayerEventsListener> eventsListeners = [];
  List<ApiVideoPlayerWidgetListener> widgetListeners = [];

  PlayerLifeCycleObserver? _lifeCycleObserver;

  /// This is just exposed for testing. Do not use it.
  @internal
  int get textureId => _textureId;

  ApiVideoPlayerController({
    required VideoOptions videoOptions,
    bool autoplay = false,
    VoidCallback? onReady,
    VoidCallback? onPlay,
    VoidCallback? onPause,
    VoidCallback? onEnd,
    Function(Object)? onError,
  })  : _initialAutoplay = autoplay,
        _initialVideoOptions = videoOptions {
    eventsListeners.add(ApiVideoPlayerEventsListener(
        onReady: onReady,
        onPlay: onPlay,
        onPause: onPause,
        onEnd: onEnd,
        onError: onError));
  }

  ApiVideoPlayerController.fromListener(
      {required VideoOptions videoOptions,
      bool autoplay = false,
      ApiVideoPlayerEventsListener? listener})
      : _initialAutoplay = autoplay,
        _initialVideoOptions = videoOptions {
    if (listener != null) {
      eventsListeners.add(listener);
    }
  }

  /// Checks if the player has been created.
  Future<bool> get isCreated => _playerPlatform.isCreated(_textureId);

  /// Checks whether the video is playing.
  Future<bool> get isPlaying {
    return _playerPlatform.isPlaying(_textureId);
  }

  /// The video current time.
  Future<Duration> get currentTime async {
    final milliseconds = await _playerPlatform.getCurrentTime(_textureId);
    return Duration(milliseconds: milliseconds);
  }

  /// Sets the current playback time.
  Future<void> setCurrentTime(Duration currentTime) {
    return _playerPlatform.setCurrentTime(
        _textureId, currentTime.inMilliseconds);
  }

  /// Retrieves the duration of the video.
  Future<Duration> get duration async {
    final milliseconds = await _playerPlatform.getDuration(_textureId);
    return Duration(milliseconds: milliseconds);
  }

  /// Retrieves the current video options.
  Future<VideoOptions> get videoOptions {
    return _playerPlatform.getVideoOptions(_textureId);
  }

  /// Sets the video options.
  Future<void> setVideoOptions(VideoOptions videoOptions) {
    return _playerPlatform.setVideoOptions(_textureId, videoOptions);
  }

  /// Checks whether the video is autoplayed.
  Future<bool> get autoplay {
    return _playerPlatform.getAutoplay(_textureId);
  }

  /// Defines if the video should start playing as soon as it is loaded.
  Future<void> setAutoplay(bool autoplay) {
    return _playerPlatform.setAutoplay(_textureId, autoplay);
  }

  /// Checks whether the video is muted.
  Future<bool> get isMuted {
    return _playerPlatform.getIsMuted(_textureId);
  }

  /// Mutes/unmutes the video.
  Future<void> setIsMuted(bool isMuted) {
    return _playerPlatform.setIsMuted(_textureId, isMuted);
  }

  /// Checks whether the video is in loop mode.
  Future<bool> get isLooping {
    return _playerPlatform.getIsLooping(_textureId);
  }

  /// Defines if the video should be played in loop.
  Future<void> setIsLooping(bool isLooping) {
    return _playerPlatform.setIsLooping(_textureId, isLooping);
  }

  /// Retrieves the current volume
  Future<double> get volume {
    return _playerPlatform.getVolume(_textureId);
  }

  /// Changes the audio volume to the given value.
  ///
  /// From 0 to 1 (0 = muted, 1 = 100%).
  Future<void> setVolume(double volume) {
    if (volume < 0 || volume > 1) {
      throw ArgumentError('Volume must be between 0 and 1');
    }
    return _playerPlatform.setVolume(_textureId, volume);
  }

  Future<void> setSpeedRate(double speedRate) {
    return _playerPlatform.setPlaybackRate(_textureId, speedRate);
  }

  Future<double> get speedRate {
    return _playerPlatform.getPlaybackRate(_textureId);
  }

  /// Retrieves the current video size.
  Future<Size?> get videoSize {
    return _playerPlatform.getVideoSize(_textureId);
  }

  /// Initializes the controller.
  Future<void> initialize() async {
    _textureId = await _playerPlatform.initialize(_initialAutoplay) ??
        kUninitializedTextureId;

    _lifeCycleObserver = PlayerLifeCycleObserver(this);
    _lifeCycleObserver?.initialize();

    _eventSubscription = _playerPlatform
        .playerEventsFor(_textureId)
        .listen(_eventListener, onError: _errorListener);

    await _playerPlatform.create(_textureId, _initialVideoOptions);

    for (var listener in [...widgetListeners]) {
      if (listener.onTextureReady != null) {
        listener.onTextureReady!();
      }
    }

    return;
  }

  /// Plays the video.
  Future<void> play() {
    return _playerPlatform.play(_textureId);
  }

  /// Pauses the video.
  Future<void> pause() {
    return _playerPlatform.pause(_textureId);
  }

  /// Disposes the controller.
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    eventsListeners.clear();
    await _playerPlatform.dispose(_textureId);
    _lifeCycleObserver?.dispose();
    return;
  }

  /// Adds/substracts the given Duration to/from the playback time.
  Future<void> seek(Duration offset) {
    return _playerPlatform.seek(_textureId, offset.inMilliseconds);
  }

  /// Adds an event listener to this controller.
  ///
  /// ```dart
  /// final ApiVideoPlayerEventsListener _eventsListener =
  ///    ApiVideoPlayerEventsListener(onPlay: () => print('PLAY'));
  ///
  /// controller.addEventsListener(_eventsListener);
  /// ```
  void addEventsListener(ApiVideoPlayerEventsListener listener) {
    eventsListeners.add(listener);
  }

  /// Adds an event listener to this controller.
  ///
  /// ```dart
  /// final ApiVideoPlayerEventsListener _eventsListener =
  ///    ApiVideoPlayerEventsListener(onPlay: () => print('PLAY'));
  ///
  /// controller.removeEventsListener(_eventsListener);
  /// ```
  void removeEventsListener(ApiVideoPlayerEventsListener listener) {
    eventsListeners.remove(listener);
  }

  /// This is exposed for internal use only. Do not use it.
  @internal
  void addWidgetListener(ApiVideoPlayerWidgetListener listener) {
    widgetListeners.add(listener);
  }

  /// This is exposed for internal use only. Do not use it.
  @internal
  void removeWidgetListener(ApiVideoPlayerWidgetListener listener) {
    widgetListeners.remove(listener);
  }

  void _errorListener(Object obj) {
    final PlatformException e = obj as PlatformException;
    for (var listener in [...eventsListeners]) {
      if (listener.onError != null) {
        listener.onError!(e);
      }
    }
  }

  void _eventListener(PlayerEvent event) {
    switch (event.type) {
      case PlayerEventType.ready:
        for (var listener in [...eventsListeners]) {
          if (listener.onReady != null) {
            listener.onReady!();
          }
        }
        break;
      case PlayerEventType.played:
        for (var listener in [...eventsListeners]) {
          if (listener.onPlay != null) {
            listener.onPlay!();
          }
        }
        break;
      case PlayerEventType.paused:
        for (var listener in [...eventsListeners]) {
          if (listener.onPause != null) {
            listener.onPause!();
          }
        }
        break;
      case PlayerEventType.seek:
        for (var listener in [...eventsListeners]) {
          if (listener.onSeek != null) {
            listener.onSeek!();
          }
        }
        break;
      case PlayerEventType.seekStarted:
        for (var listener in [...eventsListeners]) {
          if (listener.onSeekStarted != null) {
            listener.onSeekStarted!();
          }
        }
        break;
      case PlayerEventType.ended:
        for (var listener in [...eventsListeners]) {
          if (listener.onEnd != null) {
            listener.onEnd!();
          }
        }
        break;
      case PlayerEventType.unknown:
        // Nothing to do
        break;
    }
  }
}

class ApiVideoPlayerEventsListener {
  final VoidCallback? onReady;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onSeek;
  final VoidCallback? onSeekStarted;
  final VoidCallback? onEnd;
  final Function(Object)? onError;

  ApiVideoPlayerEventsListener(
      {this.onReady,
      this.onPlay,
      this.onPause,
      this.onSeek,
      this.onSeekStarted,
      this.onEnd,
      this.onError});
}

class ApiVideoPlayerWidgetListener {
  final VoidCallback? onTextureReady;

  ApiVideoPlayerWidgetListener({this.onTextureReady});
}
