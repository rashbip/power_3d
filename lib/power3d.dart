import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class Power3D extends StatefulWidget {
  final String? modelUrl;
  final Function(String)? onMessage;

  const Power3D({super.key, this.modelUrl, this.onMessage});

  @override
  State<Power3D> createState() => _Power3DState();
}

class _Power3DState extends State<Power3D> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            if (widget.modelUrl != null) {
              _loadModel(widget.modelUrl!);
            }
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (widget.onMessage != null) {
            widget.onMessage!(message.message);
          }
        },
      )
      ..loadFlutterAsset('packages/power3d/assets/index.html');
  }

  void _loadModel(String url) {
    _controller.runJavaScript('loadModel("$url")');
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
