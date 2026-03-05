import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'src/controller/asset_manager.dart';
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

  /// JSON string representing the annotations.
  final String? annotations;

  /// Annotation style to use. Can be a [Power3DAnnotationStyle] enum or a custom JS string.
  final dynamic annotationStyle;


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
    this.annotations,
    this.annotationStyle,
    this.onModelLoaded,
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
    String? annotations,
    dynamic annotationStyle,
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
      annotations: annotations,
      annotationStyle: annotationStyle,
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
    String? annotations,
    dynamic annotationStyle,
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
      annotations: annotations,
      annotationStyle: annotationStyle,
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
    String? annotations,
    dynamic annotationStyle,
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
      annotations: annotations,
      annotationStyle: annotationStyle,
      onModelLoaded: onModelLoaded,
    );
  }

  @override
  State<Power3D> createState() => _Power3DState();
}

class _Power3DState extends State<Power3D> {
  InAppWebViewController? _webViewController;
  late Power3DController _controller;
  // _libReady: assets unzipped, _libPath: path to index.html
  bool _libReady = false;
  String? _libPath;
  // _sceneInitialized: JS scene has been initialized once
  bool _sceneInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? Power3DController();
    debugPrint('Power3D: initState - preparing assets');

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

    if (widget.annotations != null) {
      _controller.setAnnotations(widget.annotations!);
    }
    if (widget.annotationStyle != null) {
      _controller.setAnnotationStyle(widget.annotationStyle!);
    }
    
    _initLib();
  }

  Future<void> _initLib() async {
    try {
      debugPrint('Power3D: _initLib - loading zip asset...');
      final indexPath = await Power3DAssetManager.prepareAssets();
      debugPrint('Power3D: _initLib - assets ready at: $indexPath');
      if (mounted) {
        setState(() {
          _libPath = indexPath;
          _libReady = true;
        });
      }
    } catch (e) {
      debugPrint('Power3D: _initLib FAILED: $e');
    }
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

    if (widget.annotations != oldWidget.annotations &&
        widget.annotations != null) {
      _controller.setAnnotations(widget.annotations!);
    }
    if (widget.annotationStyle != oldWidget.annotationStyle &&
        widget.annotationStyle != null) {
      _controller.setAnnotationStyle(widget.annotationStyle!);
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

    if (state.status == Power3DStatus.loaded) {
      final modelKey = state.currentModelName;
      if (modelKey != null) {
        widget.onModelLoaded?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Power3DState>(
      valueListenable: _controller,
      builder: (context, state, child) {
        // If the viewer should be visible
        if (!widget.lazy || state.status != Power3DStatus.initial) {
          return SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.environmentBuilder != null)
                  IgnorePointer(
                    child: widget.environmentBuilder!(context, state),
                  ),
                if (_libReady && _libPath != null)
                  FutureBuilder<bool>(
                    future: File(_libPath!).exists(),
                    builder: (context, snapshot) {
                      final exists = snapshot.data ?? false;
                      if (snapshot.connectionState == ConnectionState.done) {
                        debugPrint(
                          'Power3D: WebView check - file exists: $exists path=$_libPath',
                        );
                      }
                      if (!exists &&
                          snapshot.connectionState == ConnectionState.done) {
                        return const Center(
                          child: Text("Library file not found on disk"),
                        );
                      }
                      return InAppWebView(
                        initialUrlRequest: URLRequest(
                          url: WebUri('file://$_libPath'),
                        ),
                        initialSettings: InAppWebViewSettings(
                          transparentBackground: true,
                          supportZoom: false,
                          isInspectable: kDebugMode,
                          allowFileAccess: true,
                          allowFileAccessFromFileURLs: true,
                          allowUniversalAccessFromFileURLs: true,
                        ),
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                          _controller.setWebViewController(controller);

                          controller.addJavaScriptHandler(
                            handlerName: 'onMessage',
                            callback: (args) {
                              if (args.isNotEmpty && mounted) {
                                final String message = args[0];
                                _controller.handleWebViewMessage(message);
                                widget.onMessage?.call(message);
                              }
                            },
                          );
                        },
                        onLoadStop: (controller, url) async {
                          debugPrint(
                            'Power3D: onLoadStop - url=$url, sceneInit=$_sceneInitialized',
                          );
                          if (!_sceneInitialized) {
                            _sceneInitialized = true;
                            _controller.initialize();
                            debugPrint(
                              'Power3D: onLoadStop - calling initialize()',
                            );
                            if (widget.initialModel != null) {
                              debugPrint(
                                'Power3D: onLoadStop - loading model: ${widget.initialModel!.path}',
                              );
                              _controller.loadModel(widget.initialModel!);
                            }
                          }
                        },
                        onLoadError: (controller, url, code, message) {
                          debugPrint(
                            'Power3D: onLoadError - url=$url code=$code msg=$message',
                          );
                        },
                        onConsoleMessage: (controller, consoleMessage) {
                          debugPrint(
                            'JS [${consoleMessage.messageLevel.toString()}]: ${consoleMessage.message}',
                          );
                        },
                      );
                  },
                ),
                // Show loading UI on top if loading
                if (state.status == Power3DStatus.loading ||
                    state.status == Power3DStatus.initial)
                  widget.loadingUi?.call(context, _controller) ??
                      const Center(child: CircularProgressIndicator()),

                // Show error widget if error
                if (state.status == Power3DStatus.error)
                  widget.errorWidget ?? const Center(child: Text("Error")),
              ],
            ),
          );
        }

        // Lazy initialization placeholder
        return widget.loadingUi?.call(context, _controller) ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }
}
