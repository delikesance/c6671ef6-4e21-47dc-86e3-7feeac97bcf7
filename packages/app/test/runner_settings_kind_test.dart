import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RunnerConnectionConfig serializes kind and useEmbedded', () {
    const config = RunnerConnectionConfig(
      id: 'test',
      url: 'http://127.0.0.1:18080',
      apiToken: 'secret',
      kind: RunnerKind.javascript,
      useEmbedded: true,
    );

    final json = config.toJson(includeToken: true);
    expect(json['kind'], 'javascript');
    expect(json['useEmbedded'], isTrue);

    final restored = RunnerConnectionConfig.fromJson(json);
    expect(restored.kind, RunnerKind.javascript);
    expect(restored.useEmbedded, isTrue);
  });

  test('RunnerKind round-trips through json', () {
    expect(RunnerKind.fromJson('auto'), RunnerKind.auto);
    expect(RunnerKind.javascript.toJson(), 'javascript');
  });
}
