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
    );
  }

  @override
  State<Power3D> createState() => _Power3DState();
}

class _Power3DState extends State<Power3D> {
  WebViewController? _webViewController;
  late Power3DController _controller;

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
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _initController() {
    if (!mounted) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted && widget.initialModel != null) {
              _controller.loadModel(widget.initialModel!);
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
    _controller.initialize();
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
}

