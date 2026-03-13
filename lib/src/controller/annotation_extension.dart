part of 'power3d_controller.dart';

extension AnnotationExtension on Power3DController {
  /// Sets the JSON string representing the annotations.
  void setAnnotations(String json) {
    debugPrint('Power3D: setAnnotations called (length: ${json.length})');
    value = value.copyWith(annotations: json);

    if (value.isInitialized) {
      unawaited(
        _webViewController?.evaluateJavascript(
          source: 'setAnnotations(JSON.parse(${jsonEncode(json)}))',
        ),
      );
    }
  }

  /// Sets the annotation style.
  ///
  /// [style] can be:
  /// - A raw HTML/CSS/JS string to be injected.
  /// - A path to a local JavaScript style file.
  /// - A custom type (like an Enum) handled by the `onResolveStyle` hook.
  void setAnnotationStyle(dynamic style, {bool force = false}) {
    final bool changed = value.annotationStyle != style;
    if (changed) {
      value = value.copyWith(annotationStyle: style);
    }

    if (style is String) {
      if (value.isInitialized && (changed || force)) {
        unawaited(
          _webViewController?.evaluateJavascript(
            source: 'setAnnotationStyle(`${style.replaceAll('`', '\\`')}`)',
          ),
        );
      }
    } else {
      // Provisioning style files requires the engine's assets to be ready. 
      // If we're not initialized yet, we just keep the style in state.
      // The initialize() method will call this again once ready.
      if (!value.isInitialized && !force) return;

      // It's likely an Enum or custom Style object. Check local hook, then global.
      if (onResolveStyle != null) {
        unawaited(onResolveStyle!(style));
      } else if (Power3DController.globalStyleResolver != null) {
        unawaited(Power3DController.globalStyleResolver!(this, style));
      } else {
        debugPrint(
          'Power3D: Warning - annotationStyle is not a String and no resolver found. Is power3d_annotations plugin registered?',
        );
      }
    }
  }

  /// Toggles visibility of all annotations.
  void toggleAnnotations(bool visible) {
    if (value.isInitialized) {
      unawaited(
        _webViewController?.evaluateJavascript(
          source: 'setAnnotationsVisible($visible)',
        ),
      );
    }
  }

  /// Smoothly transitions the camera to a specific orbit and target.
  /// 
  /// [orbit]: List of [Alpha, Beta, Radius] camera angles.
  /// [target]: List of [X, Y, Z] world coordinates.
  /// [duration]: The time in seconds for the flight transition.
  void focusCamera({
    required List<double> orbit,
    required List<double> target,
    double duration = 0.5,
  }) {
    if (value.isInitialized) {
      unawaited(
        _webViewController?.evaluateJavascript(
          source:
              'transitionCamera(${orbit[0]}, ${orbit[1]}, ${orbit[2]}, {x: ${target[0]}, y: ${target[1]}, z: ${target[2]}}, ${duration * 1000})',
        ),
      );
    }
  }
}
