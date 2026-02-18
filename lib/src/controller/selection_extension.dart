part of 'power3d_controller.dart';

/// Selection and Hierarchy extension for [Power3DController].
extension SelectionExtension on Power3DController {
  /// Registers a callback for part selection events.
  ///
  /// The callback is triggered whenever a part is selected or deselected.
  void onPartSelected(Function(String partName, bool selected) callback) {
    _onPartSelectedCallback = callback;
  }

  /// Retrieves the list of available mesh part names from the currently loaded model.
  Future<List<String>> getPartsList() async {
    if (_webViewController == null) return [];

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getPartsList())',
      );
      final partsJson = result.toString().replaceAll('"', '');
      if (partsJson == 'null' || partsJson.isEmpty) return [];

      final parts = (jsonDecode(partsJson) as List).cast<String>();
      value = value.copyWith(availableParts: parts);
      return parts;
    } catch (e) {
      debugPrint('Failed to get parts list: $e');
      return [];
    }
  }

  /// Focuses and selects a specific part by its mesh [partName].
  Future<void> selectPart(String partName) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('selectPart("$partName")');

    final newSelected = List<String>.from(value.selectedParts);
    if (!newSelected.contains(partName)) {
      if (!value.selectionConfig.multipleSelection) {
        newSelected.clear();
      }
      newSelected.add(partName);
      value = value.copyWith(selectedParts: newSelected);
    }
  }

  /// Deselects a specific part by its mesh [partName].
  Future<void> unselectPart(String partName) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('unselectPart("$partName")');

    final newSelected = List<String>.from(value.selectedParts);
    newSelected.remove(partName);
    value = value.copyWith(selectedParts: newSelected);
  }

  /// Clears all currently selected model parts.
  Future<void> clearSelection() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('clearSelection()');
    value = value.copyWith(selectedParts: []);
  }

  /// Updates the global selection configuration, including styles and behavior.
  Future<void> updateSelectionConfig(SelectionConfig config) async {
    value = value.copyWith(selectionConfig: config);

    if (_webViewController == null) return;

    final Map<String, dynamic> jsConfig = {
      'enabled': config.enabled,
      'multipleSelection': config.multipleSelection,
      'scaleSelection': config.scaleSelection,
      'selectionShift': {
        'x': config.selectionShift?.x ?? 0,
        'y': config.selectionShift?.y ?? 0,
        'z': config.selectionShift?.z ?? 0,
      },
    };

    if (config.selectionStyle != null) {
      jsConfig['selectionStyle'] = {
        if (config.selectionStyle!.highlightColor != null)
          'highlightColor':
              '#${config.selectionStyle!.highlightColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.selectionStyle!.outlineColor != null)
          'outlineColor':
              '#${config.selectionStyle!.outlineColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.selectionStyle!.outlineWidth != null)
          'outlineWidth': config.selectionStyle!.outlineWidth,
      };
    }

    if (config.unselectedStyle != null) {
      jsConfig['unselectedStyle'] = {
        if (config.unselectedStyle!.highlightColor != null)
          'highlightColor':
              '#${config.unselectedStyle!.highlightColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.unselectedStyle!.outlineColor != null)
          'outlineColor':
              '#${config.unselectedStyle!.outlineColor!.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        if (config.unselectedStyle!.outlineWidth != null)
          'outlineWidth': config.unselectedStyle!.outlineWidth,
      };
    }

    await _webViewController!.runJavaScript(
      'enableSelectionMode(${jsonEncode(jsConfig)})',
    );
  }

  // ===== Hierarchy & Node Extras =====

  /// Retrieves the hierarchical structure of parts in the model.
  ///
  /// [useCategorization]: If true, uses naming conventions like "Category.PartName".
  /// If false (default), uses the GLTF scene graph parent-child relationships.
  Future<List<dynamic>> getPartsHierarchy({
    bool useCategorization = false,
  }) async {
    if (_webViewController == null) return [];

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getPartsHierarchy($useCategorization))',
      );

      String resultString = result.toString();
      // WebView results are often wrapped in extra quotes and escaped
      if (resultString.startsWith('"') && resultString.endsWith('"')) {
        try {
          // Decode the outer string wrapper
          final decoded = jsonDecode(resultString);
          resultString = decoded.toString();
        } catch (e) {
          // If decoding fails, fallback to removing leading/trailing quotes if they exist
          resultString = resultString
              .substring(1, resultString.length - 1)
              .replaceAll('\\"', '"');
        }
      }

      if (resultString == 'null' || resultString.isEmpty) return [];

      final hierarchy = jsonDecode(resultString) as List<dynamic>;
      value = value.copyWith(partsHierarchy: hierarchy);
      return hierarchy;
    } catch (e) {
      debugPrint('Failed to get parts hierarchy: $e');
      return [];
    }
  }

  /// Gets extras data from a specific node/part (label, description, category, etc.).
  ///
  /// Returns a map containing metadata and GLTF extras if available.
  Future<Map<String, dynamic>> getNodeExtras(String partName) async {
    if (_webViewController == null) return {};

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'JSON.stringify(getNodeExtras("$partName"))',
      );

      String resultString = result.toString();
      if (resultString.startsWith('"') && resultString.endsWith('"')) {
        try {
          final decoded = jsonDecode(resultString);
          resultString = decoded.toString();
        } catch (e) {
          resultString = resultString
              .substring(1, resultString.length - 1)
              .replaceAll('\\"', '"');
        }
      }

      if (resultString == 'null' || resultString.isEmpty) return {};

      return jsonDecode(resultString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to get node extras: $e');
      return {};
    }
  }

  // ===== Visibility Controls =====

  /// Hides the specified parts from view.
  Future<void> hideParts(List<String> partNames) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'hideParts(${jsonEncode(partNames)})',
    );

    final newHidden = List<String>.from(value.hiddenParts);
    for (final name in partNames) {
      if (!newHidden.contains(name)) newHidden.add(name);
    }
    value = value.copyWith(hiddenParts: newHidden);
  }

  /// Shows the specified parts (makes them visible).
  Future<void> showParts(List<String> showPartNames) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'showParts(${jsonEncode(showPartNames)})',
    );

    final newHidden = List<String>.from(value.hiddenParts);
    newHidden.removeWhere((name) => showPartNames.contains(name));
    value = value.copyWith(hiddenParts: newHidden);
  }

  /// Hides all currently selected parts.
  Future<void> hideSelected() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('hideSelected()');

    final newHidden = List<String>.from(value.hiddenParts);
    for (final name in value.selectedParts) {
      if (!newHidden.contains(name)) newHidden.add(name);
    }
    value = value.copyWith(hiddenParts: newHidden);
  }

  /// Hides all parts except the currently selected ones.
  Future<void> hideUnselected() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('hideUnselected()');

    final unselected = value.availableParts
        .where((name) => !value.selectedParts.contains(name))
        .toList();
    value = value.copyWith(hiddenParts: unselected);
  }

  /// Shows all parts (unhides everything).
  Future<void> unhideAll() async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript('unhideAll()');
    value = value.copyWith(hiddenParts: []);
  }

  // ===== Bounding Box Visualization =====

  /// Shows bounding boxes around the specified parts.
  ///
  /// [partNames]: List of part names to show bounding boxes for.
  /// [config]: Optional configuration for appearance (color, line width, etc.).
  Future<void> showBoundingBox(
    List<String> partNames, {
    BoundingBoxConfig? config,
  }) async {
    if (_webViewController == null) return;

    config ??= const BoundingBoxConfig();

    final String colorHex =
        '#${config.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    final Map<String, dynamic> jsConfig = {
      'color': colorHex,
      'lineWidth': config.lineWidth,
      'style': config.style.name,
    };

    await _webViewController!.runJavaScript(
      'showBoundingBox(${jsonEncode(partNames)}, ${jsonEncode(jsConfig)})',
    );

    final newBoxes = List<String>.from(value.boundingBoxParts);
    for (final name in partNames) {
      if (!newBoxes.contains(name)) newBoxes.add(name);
    }
    value = value.copyWith(boundingBoxParts: newBoxes);
  }

  /// Hides bounding boxes for the specified parts.
  Future<void> hideBoundingBox(List<String> partNames) async {
    if (_webViewController == null) return;

    await _webViewController!.runJavaScript(
      'hideBoundingBox(${jsonEncode(partNames)})',
    );

    final newBoxes = List<String>.from(value.boundingBoxParts);
    newBoxes.removeWhere((name) => partNames.contains(name));
    value = value.copyWith(boundingBoxParts: newBoxes);
  }
}
