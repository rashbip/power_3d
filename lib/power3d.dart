import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/models/power3d_model.dart';
import 'src/controller/power3d_controller.dart';

export 'src/models/power3d_model.dart';
export 'src/controller/power3d_controller.dart';

class Power3D extends StatefulWidget {
  final Power3DController? controller;
  final Power3DData? initialModel;
  final Function(String)? onMessage;
  final bool lazy;
  final Widget? errorWidget;
  final Widget Function(BuildContext context, Power3DController controller)?
  loadingUi;
  final Widget Function(BuildContext context, Power3DState state)?
  environmentBuilder;
  final EnvironmentConfig? environmentConfig;
  final String? skyboxPath;
  final Power3DSource? skyboxSource;

  const Power3D({
    super.key,
    this.controller,
    this.initialModel,
    this.onMessage,
    this.lazy = false,
    this.errorWidget,
    this.loadingUi,
    this.environmentBuilder,
    this.environmentConfig,
    this.skyboxPath,
    this.skyboxSource,
  });

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
    EnvironmentConfig? environmentConfig,
    String? skyboxPath,
    Power3DSource? skyboxSource,
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
      environmentConfig: environmentConfig,
      skyboxPath: skyboxPath,
      skyboxSource: skyboxSource ?? Power3DSource.asset,
    );
  }

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
    EnvironmentConfig? environmentConfig,
    String? skyboxPath,
    Power3DSource? skyboxSource,
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
      environmentConfig: environmentConfig,
      skyboxPath: skyboxPath,
      skyboxSource: skyboxSource ?? Power3DSource.network,
    );
  }

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
    EnvironmentConfig? environmentConfig,
    String? skyboxPath,
    Power3DSource? skyboxSource,
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
      environmentConfig: environmentConfig,
      skyboxPath: skyboxPath,
      skyboxSource: skyboxSource ?? Power3DSource.file,
    );
  }

  @override
  State<Power3D> createState() => _Power3DState();
}

class _Power3DState extends State<Power3D> with TickerProviderStateMixin {
  WebViewController? _webViewController;
  late Power3DController _controller;
  AnimationController? _bgRotationController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? Power3DController();
    
    if (widget.skyboxPath != null) {
      _controller.setSkybox(
        Power3DData(
          path: widget.skyboxPath!,
          source: widget.skyboxSource ?? Power3DSource.asset,
        ),
      );
    }

    if (widget.environmentConfig?.autoRotate ?? false) {
      _initBgRotation();
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

    if (widget.environmentConfig != oldWidget.environmentConfig) {
      if (widget.environmentConfig?.autoRotate ?? false) {
        _initBgRotation();
      } else {
        _bgRotationController?.dispose();
        _bgRotationController = null;
      }
    }

    if (widget.skyboxPath != oldWidget.skyboxPath ||
        widget.skyboxSource != oldWidget.skyboxSource) {
      if (widget.skyboxPath != null) {
        _controller.setSkybox(
          Power3DData(
            path: widget.skyboxPath!,
            source: widget.skyboxSource ?? Power3DSource.asset,
          ),
        );
      }
    }
  }

  void _initBgRotation() {
    _bgRotationController?.dispose();
    _bgRotationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            (20000 / (widget.environmentConfig?.autoRotationSpeed ?? 1.0))
                .round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _bgRotationController?.dispose();
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
                  _buildEnvironment(
                    context,
                    state,
                    widget.environmentConfig ?? EnvironmentConfig.none,
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

  Widget _buildEnvironment(
    BuildContext context,
    Power3DState state,
    EnvironmentConfig config,
  ) {
    Widget environment = widget.environmentBuilder!(context, state);

    // 1. Zoom Sync
    if (config.syncZoom) {
      // Baseline radius is 5.0
      final double scale = (5.0 / state.cameraRadius) * config.zoomSensitivity;
      environment = Transform.scale(
        scale: scale.clamp(0.1, 10.0),
        child: environment,
      );
    }

    // 2. Rotation / Vertical Sync (Parallax)
    if (config.syncRotation || config.syncVerticalRotation) {
      // Sensitivity factor that makes it feel like it's rotating
      // 1.0 sensitivity means the bg moves with the camera
      final double dx = config.syncRotation
          ? (state.cameraAlpha * config.rotationSensitivity * 200)
          : 0;
      final double dy = config.syncVerticalRotation
          ? (state.cameraBeta * config.verticalSensitivity * 200)
          : 0;
      environment = Transform.translate(
        offset: Offset(dx, dy),
        child: environment,
      );
    }

    // 3. Independent Auto Rotation
    if (config.autoRotate && _bgRotationController != null) {
      environment = AnimatedBuilder(
        animation: _bgRotationController!,
        builder: (context, child) {
          return Transform.rotate(
            angle:
                _bgRotationController!.value *
                2 *
                math.pi *
                config.autoRotationSpeed,
            child: child,
          );
        },
        child: environment,
      );
    }

    return IgnorePointer(child: environment);
  }
}
