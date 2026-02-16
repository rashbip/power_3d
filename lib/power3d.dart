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
  final String viewerId;
  final bool lazy;
  final Widget Function(BuildContext context, Power3DManager notifier)?
  placeholderBuilder;

  const Power3D({
    super.key,
    this.initialModel,
    this.onMessage,
    this.viewerId = 'default',
    this.lazy = false,
    this.placeholderBuilder,
  });

  factory Power3D.fromAsset(
    String path, {
    Key? key,
    String? fileName,
    String viewerId = 'default',
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
      viewerId: viewerId,
      onMessage: onMessage,
      lazy: lazy,
      placeholderBuilder: placeholderBuilder,
    );
  }

  factory Power3D.fromNetwork(
    String url, {
    Key? key,
    String? fileName,
    String viewerId = 'default',
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
      viewerId: viewerId,
      onMessage: onMessage,
      lazy: lazy,
      placeholderBuilder: placeholderBuilder,
    );
  }

  factory Power3D.fromFile(
    dynamic file, {
    Key? key,
    String? fileName,
    String viewerId = 'default',
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
      viewerId: viewerId,
      onMessage: onMessage,
      lazy: lazy,
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
                  .read(power3DManagerProvider(widget.viewerId).notifier)
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
                .read(power3DManagerProvider(widget.viewerId).notifier)
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

    final notifier = ref.read(power3DManagerProvider(widget.viewerId).notifier);
    notifier.setController(controller);
    notifier.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(power3DManagerProvider(widget.viewerId));
    final notifier = ref.read(power3DManagerProvider(widget.viewerId).notifier);

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

    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (state.status == Power3DStatus.loading)
          const Center(child: CircularProgressIndicator()),
        if (state.status == Power3DStatus.error)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (widget.initialModel != null) {
                      ref
                          .read(
                            power3DManagerProvider(widget.viewerId).notifier,
                          )
                          .loadModel(widget.initialModel!);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
