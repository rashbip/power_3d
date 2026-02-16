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

  const Power3D({
    super.key,
    this.initialModel,
    this.onMessage,
    this.viewerId = 'default',
  });

  @override
  ConsumerState<Power3D> createState() => _Power3DState();
}

class _Power3DState extends ConsumerState<Power3D> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (widget.initialModel != null) {
              ref
                  .read(power3DProvider(widget.viewerId).notifier)
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
          ref
              .read(power3DProvider(widget.viewerId).notifier)
              .handleWebViewMessage(message.message);
          if (widget.onMessage != null) {
            widget.onMessage!(message.message);
          }
        },
      )
      ..loadFlutterAsset('packages/power3d/assets/index.html');

    // Register controller with ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(power3DProvider(widget.viewerId).notifier)
          .setController(_controller);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(power3DProvider(widget.viewerId));

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
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
                          .read(power3DProvider(widget.viewerId).notifier)
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
