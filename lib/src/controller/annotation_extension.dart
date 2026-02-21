part of 'power3d_controller.dart';

/// Extension for [Power3DController] to manage surface-anchored 3D annotations.
extension AnnotationExtension on Power3DController {
  // ── Public API ──────────────────────────────────────────────────────────────

  /// Sends [annotations] to the WebView and renders markers on the mesh surface.
  ///
  /// [mode] controls display:
  ///   - [AnnotationMode.html] → card rendered inside the WebView.
  ///   - [AnnotationMode.dart] → a bridge event fires; use
  ///     [Power3D.dartAnnotationBuilder] or listen to [value.activeAnnotation].
  ///
  /// [htmlTemplate] accepts an HTML string with `{{title}}`, `{{description}}`,
  /// and `{{more}}` placeholders. Pass `null` to use the built-in M3 card.
  Future<void> loadAnnotations(
    List<AnnotationData> annotations, {
    AnnotationMode mode = AnnotationMode.html,
    String? htmlTemplate,
  }) async {
    if (_webViewController == null) return;

    // Do NOT update value here – that would re-trigger notifyListeners and
    // cause an infinite loop inside _onStateChanged.
    final jsonStr = jsonEncode(annotations.map((e) => e.toJson()).toList());
    final modeStr = mode == AnnotationMode.dart ? 'dart' : 'html';
    final tmplArg = htmlTemplate != null ? jsonEncode(htmlTemplate) : 'null';

    await _runJS('loadAnnotationsFromFlutter($jsonStr, "$modeStr", $tmplArg)');
  }

  /// Removes all annotation markers from the 3D scene and closes any open card.
  Future<void> clearAnnotations() async {
    if (_webViewController == null) return;
    // Clear activeAnnotation state only – do not touch the list, avoid re-entrancy
    if (value.activeAnnotation != null) {
      value = value.copyWith(activeAnnotation: null);
    }
    await _runJS('clearAnnotationsFromFlutter()');
  }

  /// Smoothly animates the camera to the saved viewpoint for annotation [id].
  Future<void> focusAnnotation(String id) async {
    if (_webViewController == null) return;

    // Escape the id – it could be a numeric string
    await _runJS('focusAnnotationById(${jsonEncode(id)})');
  }

  /// Dismisses the active annotation overlay (Dart mode).
  void clearActiveAnnotation() {
    value = value.copyWith(activeAnnotation: null);
  }

  // ── Internal helper ─────────────────────────────────────────────────────────

  Future<void> _runJS(String script) async {
    try {
      await _webViewController!.runJavaScript(script);
    } catch (e) {
      debugPrint('[Power3D] JS error: $e');
    }
  }
}
