import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/power3d_model.dart';

final power3DProvider =
    StateNotifierProvider.family<Power3DNotifier, Power3DState, String>((
      ref,
      id,
    ) {
      return Power3DNotifier();
    });

class Power3DNotifier extends StateNotifier<Power3DState> {
  Power3DNotifier() : super(Power3DState.initial());

  WebViewController? _controller;

  void setController(WebViewController controller) {
    _controller = controller;
  }

  Future<void> loadModel(Power3DData data) async {
    if (_controller == null) return;

    state = state.copyWith(
      status: Power3DStatus.loading,
      currentModelName: data.fileName ?? p.basename(data.path),
    );

    try {
      String? encodedData;
      String type = 'url';
      String fileName = data.fileName ?? p.basename(data.path);

      switch (data.source) {
        case Power3DSource.asset:
          final byteData = await rootBundle.load(data.path);
          final bytes = byteData.buffer.asUint8List();
          encodedData = base64Encode(bytes);
          type = 'base64';
          break;
        case Power3DSource.network:
          encodedData = data.path;
          type = 'url';
          break;
        case Power3DSource.file:
          final file = File(data.path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            encodedData = base64Encode(bytes);
            type = 'base64';
          } else {
            throw Exception("File not found: ${data.path}");
          }
          break;
      }

      final message = jsonEncode({
        'action': 'loadModel',
        'data': encodedData,
        'fileName': fileName,
        'type': type,
      });
      await _controller!.runJavaScript('window.postMessage($message, "*")');
    } catch (e) {
      state = state.copyWith(
        status: Power3DStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void handleWebViewMessage(String message) {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'status') {
        if (data['message'] == 'loaded') {
          state = state.copyWith(status: Power3DStatus.loaded);
        } else if (data['message'] == 'loading') {
          state = state.copyWith(status: Power3DStatus.loading);
        }
      } else if (data['type'] == 'error') {
        state = state.copyWith(
          status: Power3DStatus.error,
          errorMessage: data['message'],
        );
      }
    } catch (e) {
      // Ignore parse errors from JS
    }
  }
}
