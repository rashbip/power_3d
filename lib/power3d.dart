import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/models/power3d_model.dart';
import 'src/controller/power3d_controller.dart';

export 'src/models/power3d_model.dart';
export 'src/controller/power3d_controller.dart';

/// A powerful 3D model viewer widget using Babylon.js.
///
/// Supports loading models from assets, network, or local files.
/// Provides advanced controls for camera, lighting, and object selection.
class Power3D extends StatefulWidget {
  /// Optional controller to programmatically interact with the 3D scene.
  final Power3DController? controller;

  /// Initial model data to load when the widget initializes.
  final Power3DData? initialModel;

  /// Callback for receiving messages from the underlying JavaScript layer.
  final Function(String)? onMessage;

  /// Callback triggered when a 3D model is successfully loaded.
  final VoidCallback? onModelLoaded;

  /// If true, the viewer will not initialize until manually triggered.
  final bool lazy;

  /// Widget to display if an error occurs during model loading.
  final Widget? errorWidget;

  /// Custom UI to display while the model is loading.
  final Widget Function(BuildContext context, Power3DController controller)?
  loadingUi;

  /// Builder for providing a custom background or environment UI (e.g., gradients, images).
  final Widget Function(BuildContext context, Power3DState state)?
  environmentBuilder;

  /// Initial set of lights for the scene.
  final List<LightingConfig>? lights;

  /// Initial exposure level for the scene.
  final double? exposure;

  /// Initial contrast level for the scene.
  final double? contrast;

  /// Whether to display 3D annotations in the scene.
  final bool showAnnotations;

  /// List of annotations to display.
  final List<AnnotationData>? annotations;

  /// Display mode for the annotations (HTML or Dart).
  final AnnotationMode annotationMode;

  /// Optional custom HTML template for the annotation card (HTML mode).
  /// Use {{title}}, {{description}}, {{more}} as placeholders.
  final String? htmlAnnotationStyle;

  /// Optional builder for a custom Flutter widget (Dart mode).
  final Widget Function(BuildContext context, AnnotationData data)?
  dartAnnotationBuilder;

  /// Creates a new [Power3D] viewer.
  const Power3D({
    super.key,
    this.controller,
    this.initialModel,
    this.onMessage,
    this.lazy = false,
    this.errorWidget,
    this.loadingUi,
    this.environmentBuilder,
    this.lights,
    this.exposure,
    this.contrast,
    this.onModelLoaded,
    this.showAnnotations = false,
    this.annotations,
    this.annotationMode = AnnotationMode.html,
    this.htmlAnnotationStyle,
    this.dartAnnotationBuilder,
  });

  /// Creates a [Power3D] viewer from a Flutter asset path.
  factory Power3D.fromAsset(
    String path, {
    Key? key,
    Power3DController? controller,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DController controller)?
    loadingUi,
    Widget Function(BuildContext context, Power3DState state)?
    environmentBuilder,
    List<LightingConfig>? lights,
    double? exposure,
    double? contrast,
    VoidCallback? onModelLoaded,
  }) {
    return Power3D(
      key: key,
      controller: controller,
      initialModel: Power3DData(
        path: path,
        source: Power3DSource.asset,
        fileName: fileName,
      ),
      onMessage: onMessage,
      lazy: lazy,
      errorWidget: errorWidget,
      loadingUi: loadingUi,
      environmentBuilder: environmentBuilder,
      lights: lights,
      exposure: exposure,
      contrast: contrast,
      onModelLoaded: onModelLoaded,
    );
  }

  /// Creates a [Power3D] viewer from a network URL.
  factory Power3D.fromNetwork(
    String url, {
    Key? key,
    Power3DController? controller,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DController controller)?
    loadingUi,
    Widget Function(BuildContext context, Power3DState state)?
    environmentBuilder,
    List<LightingConfig>? lights,
    double? exposure,
    double? contrast,
    VoidCallback? onModelLoaded,
  }) {
    return Power3D(
      key: key,
      controller: controller,
      initialModel: Power3DData(
        path: url,
        source: Power3DSource.network,
        fileName: fileName,
      ),
      onMessage: onMessage,
      lazy: lazy,
      errorWidget: errorWidget,
      loadingUi: loadingUi,
      environmentBuilder: environmentBuilder,
      lights: lights,
      exposure: exposure,
      contrast: contrast,
      onModelLoaded: onModelLoaded,
    );
  }

  /// Creates a [Power3D] viewer from a local file.
  factory Power3D.fromFile(
    dynamic file, {
    Key? key,
    Power3DController? controller,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DController controller)?
    loadingUi,
    Widget Function(BuildContext context, Power3DState state)?
    environmentBuilder,
    List<LightingConfig>? lights,
    double? exposure,
    double? contrast,
    VoidCallback? onModelLoaded,
  }) {
    final String path = file is String ? file : file.path;
    return Power3D(
      key: key,
      controller: controller,
      initialModel: Power3DData(
        path: path,
        source: Power3DSource.file,
        fileName: fileName,
      ),
      onMessage: onMessage,
      lazy: lazy,
      errorWidget: errorWidget,
      loadingUi: loadingUi,
      environmentBuilder: environmentBuilder,
      lights: lights,
      exposure: exposure,
      contrast: contrast,
      onModelLoaded: onModelLoaded,
    );
  }

  @override
  State<Power3D> createState() => _Power3DState();
}

class _Power3DState extends State<Power3D> {
  WebViewController? _webViewController;
  late Power3DController _controller;
  // Track which model we last synced annotations for to avoid re-entrant loops
  String? _lastAnnotationSyncModel;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? Power3DController();

    if (widget.lights != null) {
      _controller.setLights(widget.lights!);
    }
    if (widget.exposure != null || widget.contrast != null) {
      _controller.updateSceneProcessing(
        exposure: widget.exposure,
        contrast: widget.contrast,
      );
    }

    _controller.addListener(_onStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.lazy && mounted) {
        _initController();
      }
    });
  }

  @override
  void didUpdateWidget(Power3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? Power3DController();
      if (_webViewController != null) {
        _controller.setWebViewController(_webViewController!);
      }
    }

    if (oldWidget.lazy && !widget.lazy && _webViewController == null) {
      _initController();
    }

    if (widget.lights != oldWidget.lights && widget.lights != null) {
      _controller.setLights(widget.lights!);
    }
    if ((widget.exposure != oldWidget.exposure ||
            widget.contrast != oldWidget.contrast) &&
        (widget.exposure != null || widget.contrast != null)) {
      _controller.updateSceneProcessing(
        exposure: widget.exposure,
        contrast: widget.contrast,
      );
    }

    if (widget.showAnnotations != oldWidget.showAnnotations ||
        widget.annotations != oldWidget.annotations ||
        widget.annotationMode != oldWidget.annotationMode ||
        widget.htmlAnnotationStyle != oldWidget.htmlAnnotationStyle) {
      _syncAnnotations();
    }
  }

  void _syncAnnotations() {
    if (!widget.showAnnotations || widget.annotations == null) {
      _controller.clearAnnotations();
    } else {
      _controller.loadAnnotations(
        widget.annotations!,
        mode: widget.annotationMode,
        htmlTemplate: widget.htmlAnnotationStyle,
      );
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onStateChanged);
    }
    super.dispose();
  }

  void _onStateChanged() {
    final state = _controller.value;
    // Only react to the transition INTO loaded, not every notification while loaded.
    if (state.status == Power3DStatus.loaded) {
      final modelKey = state.currentModelName;
      if (_lastAnnotationSyncModel != modelKey) {
        _lastAnnotationSyncModel = modelKey;
        _syncAnnotations();
        widget.onModelLoaded?.call();
      }
    } else {
      // Reset when model unloads / changes
      _lastAnnotationSyncModel = null;
    }
  }

  void _initController() {
    if (!mounted) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              _controller.initialize();
              if (widget.initialModel != null) {
                _controller.loadModel(widget.initialModel!);
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (mounted) {
            _controller.handleWebViewMessage(message.message);
            if (widget.onMessage != null) {
              widget.onMessage!(message.message);
            }
          }
        },
      )
      ..loadFlutterAsset('packages/power3d/assets/index.html');

    setState(() {
      _webViewController = controller;
    });

    _controller.setWebViewController(controller);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Power3DState>(
      valueListenable: _controller,
      builder: (context, state, child) {
        // If the model is fully loaded, show the viewer
        if (state.status == Power3DStatus.loaded) {
          return SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.environmentBuilder != null)
                  IgnorePointer(
                    child: widget.environmentBuilder!(context, state),
                  ),
                if (_webViewController != null)
                  WebViewWidget(controller: _webViewController!),
                if (widget.showAnnotations &&
                    widget.annotationMode == AnnotationMode.dart &&
                    state.activeAnnotation != null)
                  _buildDartAnnotation(context, state.activeAnnotation!),
              ],
            ),
          );
        }

        // If we have an error, show the error widget
        if (state.status == Power3DStatus.error) {
          return widget.errorWidget ?? const Center(child: Text("Error"));
        }

        // Otherwise (status is initial or loading), show the loading UI
        if (widget.loadingUi != null) {
          return widget.loadingUi!(context, _controller);
        }

        // Default Fallback
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDartAnnotation(BuildContext context, AnnotationData data) {
    if (widget.dartAnnotationBuilder != null) {
      return widget.dartAnnotationBuilder!(context, data);
    }

    // Default Material 3 style sheet for Dart mode
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data.ui.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _controller.clearActiveAnnotation(),
                    ),
                  ],
                ),
                if (data.ui.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.ui.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (data.ui.more.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // Developer can handle this via dartAnnotationBuilder
                      // if they want full control.
                    },
                    child: const Text('Learn More →'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

