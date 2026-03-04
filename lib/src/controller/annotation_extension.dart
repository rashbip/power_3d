part of 'power3d_controller.dart';

extension AnnotationExtension on Power3DController {
  /// Sets the JSON string representing the annotations.
  void setAnnotations(String json) {
    if (value.annotations == json) return;
    value = value.copyWith(annotations: json);

    if (value.isInitialized) {
      unawaited(
        _webViewController?.evaluateJavascript(
          source: 'setAnnotations(`${json.replaceAll('`', '\\`')}`)',
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
}
