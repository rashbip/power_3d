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
  placeholderBuilder;

  const Power3D({
    super.key,
    this.initialModel,
    this.onMessage,
    this.lazy = false,
    this.errorWidget,
    this.placeholderBuilder,
  });

  factory Power3D.fromAsset(
    String path, {
    Key? key,
    String? fileName,
    Widget? errorWidget,
    Function(String)? onMessage,
    bool lazy = false,
    Widget Function(BuildContext context, Power3DManager notifier)?
    placeholderBuilder,
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
      placeholderBuilder: placeholderBuilder,
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
    placeholderBuilder,
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
      placeholderBuilder: placeholderBuilder,
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
    placeholderBuilder,
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
      placeholderBuilder: placeholderBuilder,
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
    // Use addPostFrameCallback to ensure context and ref are ready
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

    if (!state.isInitialized) {
      if (widget.placeholderBuilder != null) {
        return widget.placeholderBuilder!(context, notifier);
      }
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            _initController();
            setState(() {});
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Load 3D Model'),
        ),
      );
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (state.status == Power3DStatus.loading)
            const Center(child: CircularProgressIndicator()),
          if (state.status == Power3DStatus.error)
            widget.errorWidget ?? const Center(child: Text("Error")),
        ],
      ),
    );
  }
}
