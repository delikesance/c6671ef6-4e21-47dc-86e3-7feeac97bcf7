import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../l10n/tr_extension.dart';
import '../models/variable_suggestion.dart';
import '../../theme/app_theme.dart';
import './variable_text_field.dart';

import '../../widgets/app_icon.dart';

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
    required this.variableSuggestions,
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
  })
  onSaved;
  final List<VariableSuggestion> variableSuggestions;

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
  Timer? _jsonValidateTimer;

  static const _httpMethods = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  ];

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
    _jsonValidateTimer?.cancel();
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
    _jsonValidateTimer?.cancel();
    _jsonValidateTimer = Timer(const Duration(milliseconds: 300), () {
      _validateJsonNow(text);
    });
  }

  void _validateJsonNow(String text) {
    if (text.trim().isEmpty) {
      setState(() => _jsonError = null);
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _jsonError = context.tr.action_root_must_json);
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
          _bodyJsonController.text = const JsonEncoder.withIndent(
            '  ',
          ).convert(decoded);
          _jsonError = null;
        });
      }
    } catch (_) {
      setState(() => _jsonError = context.tr.action_cannot_format_json);
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
      bodyJson = text.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(text) as Map<String, dynamic>).cast<String, dynamic>();
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
        title: Text(context.tr.action_name_httpRequest),
        leading: IconButton(
          icon: const AppIcon.fromMaterial(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FilledButton.icon(
            onPressed: _save,
            icon: const AppIcon.fromMaterial(Icons.check, size: 18),
            label: Text(context.tr.common_save),
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
            _sectionHeader(context.tr.http_request_section_request),
            const SizedBox(height: 8),
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 100,
                    maxWidth: 150,
                  ),
                  child: DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: _httpMethods
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _method = v ?? 'GET'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VariableTextField(
                    controller: _urlController,
                    label: 'URL',
                    hint: 'https://api.example.com/endpoint',
                    suggestions: widget.variableSuggestions,
                    maxLines: 1,
                    useLabelText: true,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ---- Section: Headers ----
            _sectionHeader(context.tr.http_request_section_headers),
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
                          if (textEditingValue.text.isEmpty) {
                            return _commonHeaders;
                          }
                          return _commonHeaders.where(
                            (o) => o.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (s) => header.keyController.text = s,
                        fieldViewBuilder:
                            (
                              context,
                              controller,
                              focusNode,
                              onEditingComplete,
                            ) {
                              if (controller.text.isEmpty &&
                                  header.keyController.text.isNotEmpty) {
                                controller.text = header.keyController.text;
                              }
                              controller.addListener(() {
                                header.keyController.text = controller.text;
                              });
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: context.tr.http_request_header_name,
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
                      child: VariableTextField(
                        controller: header.valueController,
                        label: context.tr.common_value,
                        suggestions: widget.variableSuggestions,
                        maxLines: 1,
                        useLabelText: true,
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const AppIcon.fromMaterial(
                        Icons.remove_circle_outline,
                        color: AppTheme.error,
                        size: 20,
                      ),
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
              onPressed: () =>
                  setState(() => _headers.add(_HeaderEntry.empty())),
              icon: const AppIcon.fromMaterial(Icons.add, size: 18),
              label: Text(context.tr.action_add_header),
            ),

            if (showBody) ...[
              const SizedBox(height: 24),

              // ---- Section: Body ----
              _sectionHeader(context.tr.http_request_section_body),
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
                      icon: const AppIcon.fromMaterial(
                        Icons.format_align_left,
                        size: 20,
                      ),
                      tooltip: context.tr.action_format_json,
                      onPressed: _formatJsonField,
                    ),
                  ],
                ),
                VariableTextField(
                  controller: _bodyJsonController,
                  label: context.tr.http_request_json_body,
                  hint: '{\n  "key": "value"\n}',
                  suggestions: widget.variableSuggestions,
                  maxLines: 20,
                  onChanged: (value) => _validateJson(value),
                ),
                if (_jsonError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _jsonError!,
                      style: const TextStyle(
                        color: AppTheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ] else ...[
                VariableTextField(
                  controller: _bodyTextController,
                  label: context.tr.http_request_text_body,
                  hint: 'Plain text body...',
                  suggestions: widget.variableSuggestions,
                  maxLines: 10,
                  onChanged: (_) {},
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        // Section labels are structural: neutral muted text, not a brand
        // accent.
        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
