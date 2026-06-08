import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';

/// Full-screen modal page for editing HTTP request details:
/// URL, method, headers (key-value pairs), body mode, and JSON/text body.
///
/// This replaces the cramped inline dialog with a proper responsive editor.
class HttpRequestEditorPage extends StatefulWidget {
  const HttpRequestEditorPage({
    super.key,
    required this.url,
    required this.method,
    required this.headers,
    required this.bodyMode,
    required this.bodyText,
    required this.bodyJson,
    required this.onSaved,
  });

  final String url;
  final String method;
  final Map<String, String> headers;
  final String bodyMode; // 'text' or 'json'
  final String bodyText;
  final Map<String, dynamic> bodyJson;
  final void Function({
    required String url,
    required String method,
    required Map<String, String> headers,
    required String bodyMode,
    required String bodyText,
    required Map<String, dynamic> bodyJson,
  }) onSaved;

  @override
  State<HttpRequestEditorPage> createState() => _HttpRequestEditorPageState();
}

class _HttpRequestEditorPageState extends State<HttpRequestEditorPage> {
  late final TextEditingController _urlController;
  late String _method;
  late String _bodyMode;
  late final TextEditingController _bodyTextController;
  late final TextEditingController _bodyJsonController;
  late final List<_HeaderEntry> _headers;
  String? _jsonError;

  static const _httpMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'];

  static const _commonHeaders = [
    'Authorization',
    'Content-Type',
    'Accept',
    'User-Agent',
    'Cache-Control',
    'Host',
    'Connection',
    'Origin',
    'Referer',
    'X-Requested-With',
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.url);
    _method = widget.method.toUpperCase();
    _bodyMode = widget.bodyMode.toLowerCase();
    _bodyTextController = TextEditingController(text: widget.bodyText);
    _bodyJsonController = TextEditingController(
      text: _formatJson(widget.bodyJson),
    );
    _headers = widget.headers.entries.map((e) {
      return _HeaderEntry(
        keyController: TextEditingController(text: e.key),
        valueController: TextEditingController(text: e.value),
      );
    }).toList();
    if (_headers.isEmpty) {
      _headers.add(_HeaderEntry.empty());
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyTextController.dispose();
    _bodyJsonController.dispose();
    for (final h in _headers) {
      h.keyController.dispose();
      h.valueController.dispose();
    }
    super.dispose();
  }

  String _formatJson(Map<String, dynamic> json) {
    if (json.isEmpty) return '{\n  \n}';
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return '{}';
    }
  }

  void _validateJson(String text) {
    if (text.trim().isEmpty) {
      setState(() => _jsonError = null);
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _jsonError = 'Root must be a JSON object');
      } else {
        setState(() => _jsonError = null);
      }
    } catch (e) {
      setState(() => _jsonError = e.toString());
    }
  }

  void _formatJsonField() {
    try {
      final decoded = jsonDecode(_bodyJsonController.text.trim());
      if (decoded is Map) {
        setState(() {
          _bodyJsonController.text = const JsonEncoder.withIndent('  ').convert(decoded);
          _jsonError = null;
        });
      }
    } catch (_) {
      setState(() => _jsonError = 'Cannot format: Invalid JSON');
    }
  }

  void _save() {
    final headers = <String, String>{};
    for (final h in _headers) {
      final key = h.keyController.text.trim();
      if (key.isNotEmpty) {
        headers[key] = h.valueController.text;
      }
    }

    Map<String, dynamic> bodyJson;
    try {
      final text = _bodyJsonController.text.trim();
      bodyJson = text.isEmpty ? <String, dynamic>{} : (jsonDecode(text) as Map<String, dynamic>).cast<String, dynamic>();
    } catch (_) {
      bodyJson = <String, dynamic>{};
    }

    widget.onSaved(
      url: _urlController.text.trim(),
      method: _method,
      headers: headers,
      bodyMode: _bodyMode,
      bodyText: _bodyTextController.text,
      bodyJson: bodyJson,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final showBody = _method != 'GET' && _method != 'HEAD';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Section: Request Line ----
            _sectionHeader('Request'),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _httpMethods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) => setState(() => _method = v ?? 'GET'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'https://api.example.com/endpoint',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---- Section: Headers ----
            _sectionHeader('Headers'),
            const SizedBox(height: 8),
            ..._headers.asMap().entries.map((entry) {
              final index = entry.key;
              final header = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Autocomplete<String>(
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) return _commonHeaders;
                          return _commonHeaders.where((o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (s) => header.keyController.text = s,
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          if (controller.text.isEmpty && header.keyController.text.isNotEmpty) {
                            controller.text = header.keyController.text;
                          }
                          controller.addListener(() {
                            header.keyController.text = controller.text;
                          });
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Header name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: header.valueController,
                        decoration: const InputDecoration(
                          hintText: 'Value',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.error, size: 20),
                      onPressed: () {
                        setState(() {
                          if (_headers.length > 1) {
                            _headers.removeAt(index);
                          } else {
                            header.keyController.clear();
                            header.valueController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => setState(() => _headers.add(_HeaderEntry.empty())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add header'),
            ),

            if (showBody) ...[
              const SizedBox(height: 24),

              // ---- Section: Body ----
              _sectionHeader('Body'),
              const SizedBox(height: 8),
              Row(
                children: [
                  _modeChip('JSON', 'json'),
                  const SizedBox(width: 8),
                  _modeChip('Text', 'text'),
                ],
              ),
              const SizedBox(height: 12),
              if (_bodyMode == 'json') ...[
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.format_align_left, size: 20),
                      tooltip: 'Format JSON',
                      onPressed: _formatJsonField,
                    ),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TextField(
                    controller: _bodyJsonController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    onChanged: _validateJson,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '{\n  "key": "value"\n}',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      errorText: _jsonError,
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 200,
                  child: TextField(
                    controller: _bodyTextController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Plain text body...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppTheme.brandPrimary,
      ),
    );
  }

  Widget _modeChip(String label, String value) {
    final selected = _bodyMode == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _bodyMode = value),
    );
  }
}

class _HeaderEntry {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _HeaderEntry({required this.keyController, required this.valueController});

  factory _HeaderEntry.empty() => _HeaderEntry(
    keyController: TextEditingController(),
    valueController: TextEditingController(),
  );
}
