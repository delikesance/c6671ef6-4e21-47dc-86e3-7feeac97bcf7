import '../../services/bot_component_service.dart';
import '../execution_budget.dart';
import 'program.dart';
import 'runtime.dart';

class BdfdComponentState {
  List<Map<String, dynamic>> rows = [];
  Map<String, dynamic>? modal;
  Map<String, List<Map<String, dynamic>>> edits = {};
  Future<void> flushEdits(
    BotComponentService? service,
    CommandExecutionBudget budget,
  ) async {
    validateComponentRows(rows);
    for (final value in edits.values) {
      validateComponentRows(value);
    }
    final pending = edits;
    edits = {};
    if (pending.isNotEmpty && service == null) {
      throw StateError('No component service configured.');
    }
    for (final entry in pending.entries) {
      await budget.run(
        () => service!.editComponents(entry.key, entry.value, budget: budget),
      );
    }
  }

  void clear() {
    rows = [];
    modal = null;
    edits = {};
  }
}

abstract interface class BdfdComponentOutput {
  BdfdComponentState get componentState;
  BotComponentService? get components;
}

Map<String, BdfdNativeFunction> bdfdComponentFunctions(
  BotComponentService? service,
) {
  BdfdComponentOutput output(BdfdInvocation call) {
    final sink = call.context.output;
    if (sink is! BdfdComponentOutput) {
      throw BdfdNativeError(
        'A component response output is required.',
        call.location,
      );
    }
    return sink as BdfdComponentOutput;
  }

  Future<List<String>> args(BdfdInvocation call) async => [
    for (var i = 0; i < call.argumentCount; i++) await call.argument(i),
  ];
  bool boolean(String value, {bool fallback = false}) {
    if (value.isEmpty) return fallback;
    if (value == 'yes' || value == 'true') return true;
    if (value == 'no' || value == 'false') return false;
    throw ArgumentError('Expected yes or no.');
  }

  void length(String value, int max, String label, {bool empty = false}) {
    if ((!empty && value.isEmpty) || value.length > max) {
      throw ArgumentError(
        '$label must contain ${empty ? 0 : 1} to $max characters.',
      );
    }
  }

  int integer(String value, int min, int max, {int? fallback}) {
    final n = value.isEmpty ? fallback : int.tryParse(value);
    if (n == null || n < min || n > max) {
      throw ArgumentError('Expected an integer from $min to $max.');
    }
    return n;
  }

  String? message(List<String> values, int index) {
    if (index >= values.length || values[index].isEmpty) return null;
    final raw = values[index];
    final id = int.tryParse(raw);
    if (!RegExp(r'^[0-9]+$').hasMatch(raw) || id == null || id <= 0) {
      throw ArgumentError('Invalid message ID.');
    }
    return raw;
  }

  Future<void> mutate(
    BdfdInvocation call,
    String? id,
    void Function(List<Map<String, dynamic>>) change,
  ) async {
    final List<Map<String, dynamic>> rows;
    if (id == null) {
      rows = copyComponentRows(output(call).componentState.rows);
    } else {
      if (service == null) throw StateError('No component service configured.');
      rows = copyComponentRows(
        output(call).componentState.edits[id] ??
            await call.context.budget.run(
              () => service.readComponents(id, budget: call.context.budget),
            ),
      );
    }
    change(rows);
    if (rows.where((r) => r['type'] == 'actionRow').length > 5) {
      throw ArgumentError('A message supports at most 5 component rows.');
    }
    for (final row in rows) {
      final children = row['components'] as List?;
      if (children != null && children.length > 5) {
        throw ArgumentError('A button row supports at most 5 buttons.');
      }
    }
    if (id == null) {
      output(call).componentState.rows = rows;
    } else {
      output(call).componentState.edits[id] = rows;
    }
  }

  Map<String, dynamic> find(
    List<Map<String, dynamic>> rows,
    String id, {
    String? type,
  }) {
    for (final row in rows) {
      for (final child
          in (row['components'] as List).cast<Map<String, dynamic>>()) {
        if ((child['customId'] == id || child['url'] == id) &&
            (type == null || child['type'] == type)) {
          return child;
        }
      }
    }
    throw ArgumentError('Component $id not found.');
  }

  bool exists(List<Map<String, dynamic>> rows, String id) {
    for (final row in rows) {
      for (final child in (row['components'] as List)) {
        if (child['customId'] == id && id.isNotEmpty) return true;
      }
    }
    return false;
  }

  void addRow(
    List<Map<String, dynamic>> rows,
    Map<String, dynamic> child, {
    bool newRow = true,
  }) {
    if (exists(rows, child['customId']?.toString() ?? '')) {
      throw ArgumentError('Component custom IDs must be unique.');
    }
    if (!newRow &&
        rows.isNotEmpty &&
        (rows.last['components'] as List).every((c) => c['type'] == 'button') &&
        (rows.last['components'] as List).length < 5) {
      (rows.last['components'] as List).add(child);
    } else {
      rows.add({
        'type': 'actionRow',
        'components': [child],
      });
    }
  }

  Map<String, dynamic> button(List<String> a, int offset) {
    final id = a[offset], label = a[offset + 1], style = a[offset + 2];
    final disabled = a.length > offset + 3 ? boolean(a[offset + 3]) : false;
    final emoji = a.length > offset + 4 ? a[offset + 4] : '';
    length(label, 80, 'Button label', empty: true);
    if (label.isEmpty && emoji.isEmpty) {
      throw ArgumentError('A button needs a label or emoji.');
    }
    if (!const [
      'primary',
      'secondary',
      'success',
      'danger',
      'link',
    ].contains(style)) {
      throw ArgumentError('Invalid button style.');
    }
    if (style == 'link') {
      final uri = Uri.tryParse(id);
      if (uri == null ||
          !const ['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        throw ArgumentError('Link buttons need a HTTP(S) URL.');
      }
    } else {
      length(id, 100, 'Custom ID');
    }
    return {
      'type': 'button',
      'customId': style == 'link' ? '' : id,
      'url': style == 'link' ? id : '',
      'label': label,
      'style': style,
      'disabled': '$disabled',
      'emoji': emoji,
    };
  }

  BdfdNativeFunction fn(
    int min,
    int max,
    Future<String> Function(BdfdInvocation, List<String>) callback,
  ) => BdfdNativeFunction(
    minArguments: min,
    maxArguments: max,
    handler: (call) async {
      try {
        return await callback(call, await args(call));
      } on BdfdNativeError {
        rethrow;
      } catch (error) {
        throw BdfdNativeError(error.toString(), call.location);
      }
    },
  );
  return {
    'addbutton': fn(4, 7, (call, a) async {
      final node = button(a, 1), newRow = boolean(a[0]);
      await mutate(
        call,
        message(a, 6),
        (rows) => addRow(rows, node, newRow: newRow),
      );
      return '';
    }),
    'editbutton': fn(3, 6, (call, a) async {
      final node = button(a, 0);
      await mutate(call, message(a, 5), (rows) {
        final target = find(rows, a[0], type: 'button');
        target.addAll(node);
      });
      return '';
    }),
    'newselectmenu': fn(3, 5, (call, a) async {
      length(a[0], 100, 'Menu ID');
      final min = integer(a[1], 0, 25), max = integer(a[2], 1, 25);
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final placeholder = a.length > 3 ? a[3] : '';
      length(placeholder, 150, 'Placeholder', empty: true);
      await mutate(
        call,
        message(a, 4),
        (rows) => addRow(rows, {
          'type': 'stringSelect',
          'customId': a[0],
          'minValues': min,
          'maxValues': max,
          'placeholder': placeholder,
          'options': <Map<String, dynamic>>[],
        }),
      );
      return '';
    }),
    'editselectmenu': fn(3, 5, (call, a) async {
      length(a[0], 100, 'Menu ID');
      final min = integer(a[1], 0, 25), max = integer(a[2], 1, 25);
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final placeholder = a.length > 3 ? a[3] : '';
      length(placeholder, 150, 'Placeholder', empty: true);
      await mutate(call, message(a, 4), (rows) {
        final target = find(rows, a[0], type: 'stringSelect');
        target.addAll({
          'minValues': min,
          'maxValues': max,
          'placeholder': placeholder,
        });
      });
      return '';
    }),
    for (final edit in [false, true])
      (edit ? 'editselectmenuoption' : 'addselectmenuoption'): fn(4, 7, (
        call,
        a,
      ) async {
        length(a[0], 100, 'Menu ID');
        length(a[1], 100, 'Option label');
        length(a[2], 100, 'Option value');
        length(a[3], 100, 'Description', empty: true);
        final isDefault = a.length > 4 ? boolean(a[4]) : false;
        final emoji = a.length > 5 ? a[5] : '';
        // Adds or edits the option on the select menu's option list.
        List<Map<String, dynamic>> apply(List<Map<String, dynamic>> options) {
          final index = options.indexWhere((o) => o['value'] == a[2]);
          if (edit && index < 0) {
            throw ArgumentError('Select option not found.');
          }
          if (!edit && index >= 0) {
            throw ArgumentError('Select option values must be unique.');
          }
          if (isDefault &&
              options.asMap().entries.any(
                (e) => e.key != index && e.value['isDefault'] == true,
              )) {
            throw ArgumentError('Only one default option is supported.');
          }
          final option = {
            'label': a[1],
            'value': a[2],
            'description': a[3],
            'isDefault': isDefault,
            'emoji': emoji,
          };
          if (edit) {
            options[index] = option;
          } else {
            options.add(option);
          }
          if (options.length > 25) {
            throw ArgumentError('A select menu supports at most 25 options.');
          }
          return options;
        }

        // A string select of the modal being built takes its options the same
        // way as a message select menu.
        final modalInputs =
            (output(call).componentState.modal?['inputs'] as List?)
                ?.cast<Map<String, dynamic>>();
        final modalSelect = message(a, 6) != null
            ? null
            : modalInputs
                  ?.where(
                    (input) =>
                        input['type'] == 'selectMenu' &&
                        input['customId'] == a[0],
                  )
                  .firstOrNull;
        if (modalSelect != null) {
          if (modalSelect['menuType'] != 'string') {
            throw ArgumentError('Only string selects take options.');
          }
          modalSelect['options'] = apply(
            ((modalSelect['options'] as List?) ?? <Map<String, dynamic>>[])
                .cast<Map<String, dynamic>>(),
          );
          return '';
        }
        await mutate(call, message(a, 6), (rows) {
          final target = find(rows, a[0], type: 'stringSelect');
          target['options'] = apply(
            (target['options'] as List).cast<Map<String, dynamic>>(),
          );
        });
        return '';
      }),
    'removebuttons': fn(0, 1, (call, a) async {
      await mutate(call, message(a, 0), (rows) {
        for (final row in rows) {
          (row['components'] as List).removeWhere((c) => c['type'] == 'button');
        }
        rows.removeWhere((row) => (row['components'] as List).isEmpty);
      });
      return '';
    }),
    'removecomponent': fn(1, 2, (call, a) async {
      length(a[0], 100, 'Component ID');
      await mutate(call, message(a, 1), (rows) {
        find(rows, a[0]);
        for (final row in rows) {
          (row['components'] as List).removeWhere(
            (c) => c['customId'] == a[0] || c['url'] == a[0],
          );
        }
        rows.removeWhere((row) => (row['components'] as List).isEmpty);
      });
      return '';
    }),
    'newmodal': fn(2, 2, (call, a) async {
      length(a[0], 100, 'Modal ID');
      length(a[1], 45, 'Modal title');
      if (call.context.response.acknowledged) {
        throw ArgumentError('Modal must be the first interaction response.');
      }
      final pending = output(call).componentState;
      if (pending.modal != null) {
        throw ArgumentError('A modal is already being built.');
      }
      pending.modal = {
        'customId': a[0],
        'title': a[1],
        'inputs': <Map<String, dynamic>>[],
      };
      return '';
    }),
    'addtextinput': fn(3, 8, (call, a) async {
      length(a[0], 100, 'Input ID');
      length(a[2], 45, 'Input label');
      if (!const ['short', 'paragraph'].contains(a[1])) {
        throw ArgumentError('Input style must be short or paragraph.');
      }
      final min = integer(a.length > 3 ? a[3] : '', 0, 4000, fallback: 0),
          max = integer(a.length > 4 ? a[4] : '', 1, 4000, fallback: 4000);
      if (min > max) throw ArgumentError('Minimum length exceeds maximum.');
      final required = a.length > 5 ? boolean(a[5], fallback: true) : true,
          value = a.length > 6 ? a[6] : '',
          placeholder = a.length > 7 ? a[7] : '';
      length(value, 4000, 'Default input value', empty: true);
      length(placeholder, 100, 'Input placeholder', empty: true);
      final pending = output(call).componentState.modal;
      if (pending == null) {
        throw ArgumentError('Create a modal before adding text inputs.');
      }
      final inputs = pending['inputs'] as List;
      if (inputs.length >= 5) {
        throw ArgumentError('A modal supports at most 5 inputs.');
      }
      if (inputs.any((input) => input['customId'] == a[0])) {
        throw ArgumentError('Input IDs must be unique.');
      }
      inputs.add({
        'customId': a[0],
        'style': a[1],
        'label': a[2],
        'minLength': min,
        'maxLength': max,
        'required': required,
        'value': value,
        'placeholder': placeholder,
      });
      return '';
    }),
    'addactionrow': fn(0, 2, (call, a) async {
      final id = a.isNotEmpty ? a[0] : '';
      final containerId = a.length > 1 ? a[1] : '';
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'actionRow',
          if (id.isNotEmpty) 'customId': id,
          'components': <Map<String, dynamic>>[],
          if (containerId.isNotEmpty) 'containerId': containerId,
        });
      });
      return '';
    }),
    'addbuttoncv2': fn(2, 6, (call, a) async {
      final id = a[0], label = a[1];
      final style = a.length > 2 && a[2].isNotEmpty ? a[2] : 'primary';
      final disabled = a.length > 3 ? boolean(a[3]) : false;
      final emoji = a.length > 4 ? a[4] : '';
      final targetRowId = a.length > 5 ? a[5] : '';
      final node = button([id, label, style, '$disabled', emoji], 0);
      await mutate(call, null, (rows) {
        if (targetRowId.isNotEmpty) {
          for (final row in rows) {
            if ((row['customId'] == targetRowId || row['id'] == targetRowId) &&
                row['type'] == 'actionRow') {
              final comps = (row['components'] as List)
                  .cast<Map<String, dynamic>>();
              if (comps.length < 5) {
                comps.add(node);
                return;
              }
            }
          }
        }
        addRow(rows, node, newRow: false);
      });
      return '';
    }),
    'addchannelselect': fn(1, 7, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final channelTypes = a.length > 6 ? a[6] : '';
      final node = {
        'type': 'channelSelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
        if (channelTypes.isNotEmpty) 'channelTypes': channelTypes,
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'addcategoryselect': fn(1, 6, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final node = {
        'type': 'categorySelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'addvoiceselect': fn(1, 6, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final node = {
        'type': 'voiceSelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'addroleselect': fn(1, 6, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final node = {
        'type': 'roleSelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'adduserselect': fn(1, 6, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final node = {
        'type': 'userSelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'addmentionableselect': fn(1, 6, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final node = {
        'type': 'mentionableSelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'addstringselect': fn(1, 6, (call, a) async {
      length(a[0], 100, 'Select ID');
      final placeholder = a.length > 1 ? a[1] : '';
      final min = a.length > 2 ? integer(a[2], 0, 25, fallback: 1) : 1;
      final max = a.length > 3 ? integer(a[3], 1, 25, fallback: 1) : 1;
      if (min > max) throw ArgumentError('Minimum cannot exceed maximum.');
      final disabled = a.length > 4 ? boolean(a[4]) : false;
      final node = {
        'type': 'stringSelect',
        'customId': a[0],
        'minValues': min,
        'maxValues': max,
        'disabled': '$disabled',
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
        'options': <Map<String, dynamic>>[],
      };
      await mutate(call, message(a, 5), (rows) => addRow(rows, node));
      return '';
    }),
    'addstringselectoption': fn(2, 6, (call, a) async {
      length(a[0], 100, 'Option label');
      length(a[1], 100, 'Option value');
      final desc = a.length > 2 ? a[2] : '';
      final emoji = a.length > 3 ? a[3] : '';
      final isDefault = a.length > 4 ? boolean(a[4]) : false;
      final menuId = a.length > 5 ? a[5] : '';
      await mutate(call, null, (rows) {
        Map<String, dynamic>? target;
        if (menuId.isNotEmpty) {
          target = find(rows, menuId, type: 'stringSelect');
        } else {
          for (final row in rows.reversed) {
            for (final child in (row['components'] as List? ?? [])) {
              if (child['type'] == 'stringSelect') {
                target = child as Map<String, dynamic>;
                break;
              }
            }
            if (target != null) break;
          }
        }
        if (target == null) throw ArgumentError('No string select menu found.');
        final options = (target['options'] as List)
            .cast<Map<String, dynamic>>();
        if (options.length >= 25) {
          throw ArgumentError('A select menu supports at most 25 options.');
        }
        options.add({
          'label': a[0],
          'value': a[1],
          if (desc.isNotEmpty) 'description': desc,
          if (emoji.isNotEmpty) 'emoji': emoji,
          'isDefault': isDefault,
        });
      });
      return '';
    }),
    'removeallcomponents': fn(0, 1, (call, a) async {
      final msgId = a.isNotEmpty ? message(a, 0) : null;
      if (msgId != null) {
        await mutate(call, msgId, (rows) => rows.clear());
      } else {
        output(call).componentState.rows.clear();
      }
      return '';
    }),
    'addcontainer': fn(0, 3, (call, a) async {
      final id = a.isNotEmpty ? a[0] : '';
      final color = a.length > 1 ? a[1] : '';
      final spoiler = a.length > 2 ? boolean(a[2]) : false;
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'container',
          if (id.isNotEmpty) 'customId': id,
          if (color.isNotEmpty) 'accentColor': color,
          if (spoiler) 'spoiler': true,
          'components': <Map<String, dynamic>>[],
        });
      });
      return '';
    }),
    'addsection': fn(0, 2, (call, a) async {
      final id = a.isNotEmpty ? a[0] : '';
      final containerId = a.length > 1 ? a[1] : '';
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'section',
          if (id.isNotEmpty) 'customId': id,
          if (containerId.isNotEmpty) 'containerId': containerId,
          'components': <Map<String, dynamic>>[],
        });
      });
      return '';
    }),
    'addseparator': fn(0, 3, (call, a) async {
      final divider = a.isNotEmpty ? boolean(a[0], fallback: true) : true;
      final spacing = a.length > 1 ? a[1] : '';
      final containerId = a.length > 2 ? a[2] : '';
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'separator',
          'divider': divider,
          if (spacing.isNotEmpty) 'spacing': spacing,
          if (containerId.isNotEmpty) 'containerId': containerId,
        });
      });
      return '';
    }),
    'addtextdisplay': fn(1, 2, (call, a) async {
      final content = a[0];
      final containerId = a.length > 1 ? a[1] : '';
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'textDisplay',
          'content': content,
          if (containerId.isNotEmpty) 'containerId': containerId,
        });
      });
      return '';
    }),
    'addthumbnail': fn(1, 4, (call, a) async {
      final url = a[0];
      final desc = a.length > 1 ? a[1] : '';
      final spoiler = a.length > 2 ? boolean(a[2]) : false;
      final sectionId = a.length > 3 ? a[3] : '';
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'thumbnail',
          'url': url,
          if (desc.isNotEmpty) 'description': desc,
          if (spoiler) 'spoiler': true,
          if (sectionId.isNotEmpty) 'sectionId': sectionId,
        });
      });
      return '';
    }),
    'addfile': fn(1, 2, (call, a) async {
      final url = a[0];
      final spoiler = a.length > 1 ? boolean(a[1]) : false;
      await mutate(call, null, (rows) {
        rows.add({'type': 'file', 'url': url, if (spoiler) 'spoiler': true});
      });
      return '';
    }),
    'addmediagallery': fn(0, 2, (call, a) async {
      final id = a.isNotEmpty ? a[0] : '';
      final containerId = a.length > 1 ? a[1] : '';
      await mutate(call, null, (rows) {
        rows.add({
          'type': 'mediaGallery',
          if (id.isNotEmpty) 'customId': id,
          if (containerId.isNotEmpty) 'containerId': containerId,
          'items': <Map<String, dynamic>>[],
        });
      });
      return '';
    }),
    'addmediagalleryitem': fn(1, 4, (call, a) async {
      final url = a[0];
      final desc = a.length > 1 ? a[1] : '';
      final spoiler = a.length > 2 ? boolean(a[2]) : false;
      final galleryId = a.length > 3 ? a[3] : '';
      await mutate(call, null, (rows) {
        Map<String, dynamic>? gallery;
        if (galleryId.isNotEmpty) {
          for (final row in rows) {
            if ((row['customId'] == galleryId || row['id'] == galleryId) &&
                row['type'] == 'mediaGallery') {
              gallery = row;
              break;
            }
          }
        } else {
          for (final row in rows.reversed) {
            if (row['type'] == 'mediaGallery') {
              gallery = row;
              break;
            }
          }
        }
        final item = {
          'url': url,
          if (desc.isNotEmpty) 'description': desc,
          if (spoiler) 'spoiler': true,
        };
        if (gallery != null) {
          (gallery['items'] as List).add(item);
        } else {
          rows.add({
            'type': 'mediaGallery',
            if (galleryId.isNotEmpty) 'customId': galleryId,
            'items': [item],
          });
        }
      });
      return '';
    }),
    'addmodaltextdisplay': fn(1, 1, (call, a) async {
      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'textDisplay',
        'content': a[0],
      });
      return '';
    }),
    'addmodaltextinput': fn(3, 9, (call, a) async {
      final label = a[0];
      final desc = a[1];
      final customId = a[2];
      final style = a.length > 3 && a[3].isNotEmpty ? a[3] : 'short';
      final min = a.length > 4 ? integer(a[4], 0, 4000, fallback: 0) : 0;
      final max = a.length > 5 ? integer(a[5], 1, 4000, fallback: 4000) : 4000;
      final required = a.length > 6 ? boolean(a[6], fallback: true) : true;
      final value = a.length > 7 ? a[7] : '';
      final placeholder = a.length > 8 ? a[8] : '';

      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'textInput',
        'customId': customId,
        'label': label,
        if (desc.isNotEmpty) 'description': desc,
        'style': style,
        'minLength': min,
        'maxLength': max,
        'required': required,
        if (value.isNotEmpty) 'value': value,
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
      });
      return '';
    }),
    'addmodalselect': fn(4, 9, (call, a) async {
      final type = a[0];
      final label = a[1];
      final desc = a[2];
      final customId = a[3];
      final placeholder = a.length > 4 ? a[4] : '';
      final min = a.length > 5 ? integer(a[5], 0, 25, fallback: 1) : 1;
      final max = a.length > 6 ? integer(a[6], 1, 25, fallback: 1) : 1;
      final required = a.length > 7 ? boolean(a[7], fallback: true) : true;
      final disabled = a.length > 8 ? boolean(a[8]) : false;

      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'selectMenu',
        'menuType': type,
        'customId': customId,
        'label': label,
        if (desc.isNotEmpty) 'description': desc,
        if (placeholder.isNotEmpty) 'placeholder': placeholder,
        'minValues': min,
        'maxValues': max,
        'required': required,
        'disabled': '$disabled',
      });
      return '';
    }),
    'addmodalfileupload': fn(3, 6, (call, a) async {
      final label = a[0], desc = a[1], customId = a[2];
      final min = a.length > 3 ? integer(a[3], 0, 10, fallback: 1) : 1;
      final max = a.length > 4 ? integer(a[4], 1, 10, fallback: 1) : 1;
      final required = a.length > 5 ? boolean(a[5], fallback: true) : true;

      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'fileUpload',
        'customId': customId,
        'label': label,
        if (desc.isNotEmpty) 'description': desc,
        'minValues': min,
        'maxValues': max,
        'required': required,
      });
      return '';
    }),
    'addmodalradiogroup': fn(3, 4, (call, a) async {
      final label = a[0], desc = a[1], customId = a[2];
      final required = a.length > 3 ? boolean(a[3], fallback: true) : true;

      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'radioGroup',
        'customId': customId,
        'label': label,
        if (desc.isNotEmpty) 'description': desc,
        'required': required,
        'options': <Map<String, dynamic>>[],
      });
      return '';
    }),
    'addmodalcheckboxgroup': fn(3, 6, (call, a) async {
      final label = a[0], desc = a[1], customId = a[2];
      final min = a.length > 3 ? integer(a[3], 0, 25, fallback: 1) : 1;
      final max = a.length > 4 ? integer(a[4], 1, 25, fallback: 1) : 1;
      final required = a.length > 5 ? boolean(a[5], fallback: true) : true;

      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'checkboxGroup',
        'customId': customId,
        'label': label,
        if (desc.isNotEmpty) 'description': desc,
        'minValues': min,
        'maxValues': max,
        'required': required,
        'options': <Map<String, dynamic>>[],
      });
      return '';
    }),
    'addmodalcheckbox': fn(3, 4, (call, a) async {
      final label = a[0], desc = a[1], customId = a[2];
      final isDefault = a.length > 3 ? boolean(a[3]) : false;

      final pending = output(call).componentState;
      pending.modal ??= {
        'customId': 'modal',
        'title': 'Modal',
        'inputs': <Map<String, dynamic>>[],
      };
      (pending.modal!['inputs'] as List).add({
        'type': 'checkbox',
        'customId': customId,
        'label': label,
        if (desc.isNotEmpty) 'description': desc,
        'default': isDefault,
      });
      return '';
    }),
    'addradiogroupoption': fn(2, 5, (call, a) async {
      final groupId = a[0], label = a[1];
      final value = a.length > 2 ? a[2] : label;
      final desc = a.length > 3 ? a[3] : '';
      final isDefault = a.length > 4 ? boolean(a[4]) : false;

      final pending = output(call).componentState;
      final inputs =
          (pending.modal?['inputs'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      for (final input in inputs.reversed) {
        if (input['type'] == 'radioGroup' &&
            (groupId.isEmpty || input['customId'] == groupId)) {
          (input['options'] as List).add({
            'label': label,
            'value': value,
            if (desc.isNotEmpty) 'description': desc,
            'default': isDefault,
          });
          break;
        }
      }
      return '';
    }),
    'addcheckboxgroupoption': fn(2, 5, (call, a) async {
      final groupId = a[0], label = a[1];
      final value = a.length > 2 ? a[2] : label;
      final desc = a.length > 3 ? a[3] : '';
      final isDefault = a.length > 4 ? boolean(a[4]) : false;

      final pending = output(call).componentState;
      final inputs =
          (pending.modal?['inputs'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      for (final input in inputs.reversed) {
        if (input['type'] == 'checkboxGroup' &&
            (groupId.isEmpty || input['customId'] == groupId)) {
          (input['options'] as List).add({
            'label': label,
            'value': value,
            if (desc.isNotEmpty) 'description': desc,
            'default': isDefault,
          });
          break;
        }
      }
      return '';
    }),
  };
}
