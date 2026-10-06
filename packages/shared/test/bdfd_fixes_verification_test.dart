import 'package:bot_creator_shared/utils/embed_fields.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('BDFD Fixes Verification', () {
    group(r'$addField Dynamic Freezing & Resolution', () {
      test(
        r'resolves $addField inline argument dynamically in buildResolvedEmbedFields',
        () {
          final staticEmbedJson = {
            'fields': [
              {'name': 'Field 1', 'value': 'Val 1', 'inline': 'yes'},
              {'name': 'Field 2', 'value': 'Val 2', 'inline': 'no'},
              {
                'name': 'Field 3',
                'value': 'Val 3',
                'inline': '((dynamicInline))',
              },
            ],
          };

          // Case 1: Dynamic inline resolves to 'yes'
          final resolvedFields1 = buildResolvedEmbedFields(
            embedJson: staticEmbedJson,
            resolve: (input) =>
                resolveTemplatePlaceholders(input, {'dynamicInline': 'yes'}),
          );
          expect(resolvedFields1, hasLength(3));
          expect(resolvedFields1[0].isInline, isTrue);
          expect(resolvedFields1[1].isInline, isFalse);
          expect(resolvedFields1[2].isInline, isTrue);

          // Case 2: Dynamic inline resolves to 'no'
          final resolvedFields2 = buildResolvedEmbedFields(
            embedJson: staticEmbedJson,
            resolve: (input) =>
                resolveTemplatePlaceholders(input, {'dynamicInline': 'no'}),
          );
          expect(resolvedFields2, hasLength(3));
          expect(resolvedFields2[0].isInline, isTrue);
          expect(resolvedFields2[1].isInline, isFalse);
          expect(resolvedFields2[2].isInline, isFalse);
        },
      );
    });
  });
}
