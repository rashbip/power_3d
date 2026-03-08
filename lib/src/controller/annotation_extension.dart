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
  void setAnnotationStyle(dynamic style) {
    if (style is String) {
      if (value.annotationStyle == style) return;
      value = value.copyWith(annotationStyle: style);

      if (value.isInitialized) {
        unawaited(
          _webViewController?.evaluateJavascript(
            source: 'setAnnotationStyle(`${style.replaceAll('`', '\\`')}`)',
          ),
        );
      }
    } else {
      // It's likely an Enum or custom Style object
      if (onResolveStyle != null) {
        unawaited(onResolveStyle!(style));
      } else {
        debugPrint(
          'Power3D: Warning - annotationStyle is not a String and onResolveStyle hook is missing. Is power3d_annotations plugin available?',
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
