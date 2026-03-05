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

  /// Sets the combined HTML/CSS/JS string for annotation styling.
  void setAnnotationStyle(String style) {
    if (value.annotationStyle == style) return;
    value = value.copyWith(annotationStyle: style);

    if (value.isInitialized) {
      unawaited(
        _webViewController?.evaluateJavascript(
          source: 'setAnnotationStyle(`${style.replaceAll('`', '\\`')}`)',
        ),
      );
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
