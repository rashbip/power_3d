import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'src/models/power3d_model.dart';
import 'src/viewmodel/power3d_viewmodel.dart';

export 'src/models/power3d_model.dart';
export 'src/viewmodel/power3d_viewmodel.dart';

class Power3D extends ConsumerStatefulWidget {
  final Power3DData? initialModel;
  final Function(String)? onMessage;
  final bool lazy;
  final Widget? errorWidget;
  final Widget Function(BuildContext context, Power3DManager notifier)?
  loadingUi;

  const Power3D({
    super.key,
    this.initialModel,
    this.onMessage,
    this.lazy = false,
    this.errorWidget,
    this.loadingUi,
  });

  factory Power3D.fromAsset(
    String path, {
    Key? key,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DManager notifier)?
    loadingUi,
  }) {
    return Power3D(
      key: key,
      initialModel: Power3DData(
        path: path,
        source: Power3DSource.asset,
        fileName: fileName,
      ),
      onMessage: onMessage,
      lazy: lazy,
      errorWidget: errorWidget,
      loadingUi: loadingUi,
    );
  }

  factory Power3D.fromNetwork(
    String url, {
    Key? key,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DManager notifier)?
    loadingUi,
  }) {
    return Power3D(
      key: key,
      initialModel: Power3DData(
        path: url,
        source: Power3DSource.network,
        fileName: fileName,
      ),
      onMessage: onMessage,
      lazy: lazy,
      errorWidget: errorWidget,
      loadingUi: loadingUi,
    );
  }

  factory Power3D.fromFile(
    dynamic file, {
    Key? key,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DManager notifier)?
    loadingUi,
  }) {
    final String path = file is String ? file : file.path;
    return Power3D(
      key: key,
      initialModel: Power3DData(
        path: path,
        source: Power3DSource.file,
        fileName: fileName,
      ),
      onMessage: onMessage,
      lazy: lazy,
      errorWidget: errorWidget,
      loadingUi: loadingUi,
    );
  }

  @override
  ConsumerState<Power3D> createState() => _Power3DState();
}

class _Power3DState extends ConsumerState<Power3D> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.lazy && mounted) {
        _initController();
      }
    });
  }

  String get _viewerId => widget.initialModel?.path ?? 'default';

  void _initController() {
    if (!mounted) return;

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted && widget.initialModel != null) {
              ref
                  .read(power3DManagerProvider(_viewerId).notifier)
                  .loadModel(widget.initialModel!);
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
            ref
                .read(power3DManagerProvider(_viewerId).notifier)
                .handleWebViewMessage(message.message);
            if (widget.onMessage != null) {
              widget.onMessage!(message.message);
            }
          }
        },
      )
      ..loadFlutterAsset('packages/power3d/assets/index.html');

    setState(() {
      _controller = controller;
    });

    final notifier = ref.read(power3DManagerProvider(_viewerId).notifier);
    notifier.setController(controller);
    notifier.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(power3DManagerProvider(_viewerId));
    final notifier = ref.read(power3DManagerProvider(_viewerId).notifier);

    // If the model is fully loaded, show the viewer (with potential error/loading overlays)
    if (state.status == Power3DStatus.loaded) {
      return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null) WebViewWidget(controller: _controller!),
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
      return widget.loadingUi!(context, notifier);
    }

    // Default Fallback
    return const Center(child: CircularProgressIndicator());
  }
}
