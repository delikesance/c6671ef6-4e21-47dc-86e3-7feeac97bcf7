/// Resolve typed component fields before the component model reads them.
/// Text and callback actions retain their normal, later resolution lifecycle.
Map<String, dynamic> resolveComponentRuntimeFields(
  Map<String, dynamic> source,
  String Function(String) resolve,
) {
  const booleanFields = {
    'newRow',
    'disabled',
    'required',
    'isRequired',
    'default',
    'isDefault',
    'spoiler',
    'isSpoiler',
    'divider',
    'animated',
    'ephemeral',
  };
  const integerFields = {
    'minValues',
    'maxValues',
    'minLength',
    'maxLength',
    'spacing',
  };
  const deferredFields = {
    'actions',
    'workflowArguments',
    'onSubmitArguments',
    'arguments',
  };
  dynamic visit(dynamic value, String key) {
    if (deferredFields.contains(key)) return value;
    if (value is Map) {
      return resolveComponentRuntimeFields(
        Map<String, dynamic>.from(value),
        resolve,
      );
    }
    if (value is List) return value.map((item) => visit(item, '')).toList();
    if (value is! String || !value.contains('((')) return value;
    if (booleanFields.contains(key)) {
      final resolved = resolve(value).trim().toLowerCase();
      if (const {'true', 'yes', '1', 'on'}.contains(resolved)) return true;
      if (const {'false', 'no', '0', 'off', ''}.contains(resolved)) {
        return false;
      }
      throw FormatException('Component $key must resolve to a boolean');
    }
    if (integerFields.contains(key)) {
      final number = int.tryParse(resolve(value).trim());
      if (number == null) {
        throw FormatException('Component $key must resolve to an integer');
      }
      return number;
    }
    if (key == 'style' || key == 'menuType') {
      return resolve(value).trim().toLowerCase();
    }
    if (key == 'customId' || key == 'menuId') return resolve(value);
    return value;
  }

  final result = source.map((key, value) => MapEntry(key, visit(value, key)));
  if (result['type'] == 'button' && result.containsKey('customIdOrUrl')) {
    final target = resolve(result.remove('customIdOrUrl').toString());
    final style = result['style'];
    result['customId'] = style == 'link' || style == 'premium' ? '' : target;
    result['url'] = style == 'link' ? target : '';
    if (style == 'premium') {
      result['skuId'] = target;
      result['label'] = '';
      result.remove('emoji');
    }
  }
  return result;
}
