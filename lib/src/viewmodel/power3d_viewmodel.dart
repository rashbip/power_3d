import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/power3d_model.dart';

part 'power3d_viewmodel.g.dart';

@riverpod
class Power3DManager extends _$Power3DManager {
  @override
  Power3DState build(String id) {
    return Power3DState.initial();
  }

  WebViewController? _controller;

  void setController(WebViewController controller) {
    _controller = controller;
  }

  void initialize() {
    // Avoid double initialization and ensure state is updated
    if (!state.isInitialized) {
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> loadModel(Power3DData data) async {
    if (!state.isInitialized || _controller == null) return;

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

      await _controller!.runJavaScript(
        'loadModel("$encodedData", "$fileName", "$type")',
      );
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
