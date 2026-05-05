import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves owner from owner_id field', () {
    final resolution = resolveOwnerFromManagerBotPayload(<String, dynamic>{
      'owner_id': '111111',
    });

    expect(resolution.ownerCandidates, <String>['111111']);
    expect(resolution.preferredOwnerId, '111111');
    expect(resolution.source, 'manager_payload');
  });

  test('resolves owner from nested owner.id field', () {
    final resolution = resolveOwnerFromManagerBotPayload(<String, dynamic>{
      'owner': <String, dynamic>{'id': '222222'},
    });

    expect(resolution.ownerCandidates, <String>['222222']);
    expect(resolution.preferredOwnerId, '222222');
  });

  test('resolves owner from team owner_user_id field', () {
    final resolution = resolveOwnerFromManagerBotPayload(<String, dynamic>{
      'team': <String, dynamic>{'owner_user_id': '333333'},
    });

    expect(resolution.ownerCandidates, <String>['333333']);
    expect(resolution.preferredOwnerId, '333333');
  });

  test('deduplicates owner candidates from all payload variants', () {
    final resolution = resolveOwnerFromManagerBotPayload(<String, dynamic>{
      'owner_id': '444444',
      'ownerId': '444444',
      'owner': <String, dynamic>{'id': '444444', 'owner_id': '444444'},
      'team': <String, dynamic>{'owner_user_id': '444444'},
    });

    expect(resolution.ownerCandidates, <String>['444444']);
    expect(resolution.preferredOwnerId, '444444');
  });

  test('returns none source when no owner can be extracted', () {
    final resolution = resolveOwnerFromManagerBotPayload(<String, dynamic>{
      'bot_id': 'bot-1',
    });

    expect(resolution.ownerCandidates, isEmpty);
    expect(resolution.preferredOwnerId, isNull);
    expect(resolution.source, 'none');
  });
}
