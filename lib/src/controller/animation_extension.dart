part of 'power3d_controller.dart';

/// Extension on [Power3DController] for animation management.
extension Power3DAnimationExtension on Power3DController {
  /// Fetches the list of all animations available in the current model.
  Future<void> getAnimationsList() async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript('getAnimationsList()');
  }

  /// Plays a specific animation by [name].
  ///
  /// [loop] determines if the animation should repeat.
  /// [speed] sets the playback speed ratio.
  Future<void> playAnimation(
    String name, {
    bool loop = true,
    double speed = 1.0,
  }) async {
    if (!value.isInitialized || _webViewController == null) return;

    await _webViewController!.runJavaScript(
      'playAnimation("$name", $loop, $speed)',
    );
  }

  /// Pauses a specific animation by [name].
  Future<void> pauseAnimation(String name) async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript('pauseAnimation("$name")');
  }

  /// Stops a specific animation by [name].
  Future<void> stopAnimation(String name) async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript('stopAnimation("$name")');
  }

  /// Sets the playback speed for a specific animation.
  Future<void> setAnimationSpeed(String name, double speed) async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript(
      'setAnimationSpeed("$name", $speed)',
    );
  }

  /// Sets whether a specific animation should loop.
  Future<void> setAnimationLoop(String name, bool loop) async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript('setAnimationLoop("$name", $loop)');
  }

  /// Pauses an animation after a specified [duration].
  void pauseAfter(String name, Duration duration) {
    Timer(duration, () {
      pauseAnimation(name);
    });
  }

  /// Stops all currently active animations.
  Future<void> stopAllAnimations() async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript('stopAllAnimations()');
  }

  /// Starts or resumes all available animations.
  Future<void> startAllAnimations() async {
    if (!value.isInitialized || _webViewController == null) return;
    await _webViewController!.runJavaScript('startAllAnimations()');
  }

  /// Sets whether multiple animations can be played simultaneously.
  Future<void> setPlayMultiple(bool enabled) async {
    if (!value.isInitialized || _webViewController == null) return;
    value = value.copyWith(playMultiple: enabled);
    await _webViewController!.runJavaScript('window.playMultiple = $enabled');
  }
}
