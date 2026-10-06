import 'dart:async';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/main_api_auth_service.dart';
import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart'
    show refreshBotRuntime;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:bot_creator/main.dart' show appManager;
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart' hide Locale;
import 'package:uuid/uuid.dart';

/// Marketplace de l'app : le catalogue vient du Manager, l'application d'un
/// modèle écrit dans le stockage local et enregistre les commandes sur Discord.
class AppMarketplaceController extends MarketplaceController {
  const AppMarketplaceController(this.apiClient);

  final MainApiClient? apiClient;

  @override
  bool get connected => apiClient != null;

  @override
  Future<List<MarketplaceTemplate>> list() async {
    final raw = await apiClient!.listMarketplaceTemplates();
    return raw.map(MarketplaceTemplate.fromJson).toList();
  }

  @override
  Future<MarketplaceTemplate?> get(String id) async =>
      MarketplaceTemplate.fromJson(await apiClient!.getMarketplaceTemplate(id));

  @override
  Future<void> rate(String id, double rating) =>
      apiClient!.rateMarketplaceTemplate(id, rating);

  @override
  Future<void> delete(String id) async {
    await apiClient?.deleteMarketplaceTemplate(id);
  }

  @override
  Future<String?> currentUserId() async =>
      (await MainApiSettingsStore.loadSession())?.userId;

  @override
  Future<void> login(BuildContext context) async {
    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) {
      throw Exception('Manager not configured');
    }
    final client = MainApiClient(baseUrl: config.baseUrl);
    final session = await MainApiAuthService.connectWithDiscord(client: client);
    await MainApiSettingsStore.saveSession(
      session.copyWith(authMethod: MainApiAuthMethod.discordOauth),
    );
    await MobileAccountSession.instance.recheck();
  }

  @override
  bool get canPublish => true;

  @override
  Future<TemplatePublishSource> publishSource(String botId) async {
    final commands = await appManager.listAppCommands(botId);
    final appData = await appManager.getApp(botId);
    final workflows = List<Map<String, dynamic>>.from(
      (appData['workflows'] as List?)?.whereType<Map>().map(
            (w) => Map<String, dynamic>.from(w),
          ) ??
          const [],
    );
    return TemplatePublishSource(
      commands: commands.map((c) => Map<String, dynamic>.from(c)).toList(),
      workflows: workflows,
      appData: appData,
    );
  }

  @override
  Future<void> createTemplate(Map<String, dynamic> template) =>
      apiClient!.createMarketplaceTemplate(template);

  @override
  Future<void> updateTemplate(String id, Map<String, dynamic> template) =>
      apiClient!.updateMarketplaceTemplate(id, template);

  @override
  Future<String?> apply(
    BuildContext context,
    MarketplaceTemplate template,
    String botId,
    Map<String, String> variables,
  ) async {
    final tr = context.tr;
    {
      final client = apiClient;
      if (client != null) {
        await client.applyMarketplaceTemplate(template.id, botId, variables);
      }

      final appManager = AppManager();

      // Apply global variables
      for (final entry in variables.entries) {
        await appManager.setGlobalVariable(botId, entry.key, entry.value);
      }

      // Detect conflicts before applying commands
      final existingCommands = await appManager.listAppCommands(botId);
      final existingByName = <String, Map<String, dynamic>>{};
      for (final c in existingCommands) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        if (name.isNotEmpty) existingByName[name] = c;
      }

      final conflicts = <Map<String, dynamic>>[];
      final nonConflicting = <Map<String, dynamic>>[];

      for (final cmd in template.commands) {
        final resolvedName =
            (resolveTemplateVariables(cmd.name, variables) as String)
                .toLowerCase();
        final existing = existingByName[resolvedName];
        if (existing != null) {
          final localData = existing['data'];
          conflicts.add({
            'templateName': cmd.name,
            'resolvedName': resolvedName,
            'cmd': cmd,
            'localActions': countTemplateActions(localData),
            'templateActions': countTemplateActions(
              Map<String, dynamic>.from(cmd.data),
            ),
          });
        } else {
          nonConflicting.add({'resolvedName': resolvedName, 'cmd': cmd});
        }
      }

      // Resolve conflicts if any
      Map<String, bool>? conflictChoices;
      if (conflicts.isNotEmpty) {
        conflictChoices = await showTemplateConflictDialog(
          context,
          conflicts,
          variables,
        );
        if (conflictChoices == null) {
          return null; // annulé
        }
        // User chose to cancel entirely
        if (conflictChoices.isEmpty) {
          return null;
        }
      }

      final uuid = const Uuid();
      var addedCount = 0;
      var skippedCount = 0;
      var overwrittenCount = 0;

      // Process non-conflicting commands
      for (final entry in nonConflicting) {
        final cmd = entry['cmd'] as dynamic;
        final resolvedName = entry['resolvedName'] as String;
        final resolvedDescription =
            resolveTemplateVariables(cmd.description, variables) as String;
        final resolvedData =
            resolveTemplateVariables(cmd.data, variables)
                as Map<String, dynamic>;

        if (resolvedData['response'] is Map &&
            (resolvedData['response'] as Map).containsKey('_migrated')) {
          resolvedData.remove('response');
        }
        resolvedData.remove('simpleConfig');

        // Register on Discord first
        final discordId = await _registerOnDiscord(
          resolvedName: resolvedName,
          resolvedDescription: resolvedDescription,
          resolvedData: resolvedData,
          botId: botId,
        );
        final newCmdId = discordId ?? uuid.v4();
        final localPayload = <String, dynamic>{
          'name': resolvedName,
          'description': resolvedDescription,
          'type':
              resolvedData['commandType'] ??
              resolvedData['type'] ??
              'chatInput',
          'id': newCmdId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'data': resolvedData,
        };
        await appManager.saveAppCommand(botId, newCmdId, localPayload);
        addedCount++;
      }

      // Process conflicting commands based on user choices
      for (final conflict in conflicts) {
        final cmd = conflict['cmd'] as dynamic;
        final resolvedName = conflict['resolvedName'] as String;
        final useTemplate = conflictChoices?[resolvedName] ?? false;

        if (!useTemplate) {
          skippedCount++;
          continue;
        }

        // Use template version: delete local, save template
        final existing = existingByName[resolvedName];
        final existingId = existing?['id']?.toString();
        if (existingId != null) {
          await appManager.deleteAppCommand(botId, existingId);
        }

        final resolvedDescription =
            resolveTemplateVariables(cmd.description, variables) as String;
        final resolvedData =
            resolveTemplateVariables(cmd.data, variables)
                as Map<String, dynamic>;

        if (resolvedData['response'] is Map &&
            (resolvedData['response'] as Map).containsKey('_migrated')) {
          resolvedData.remove('response');
        }
        resolvedData.remove('simpleConfig');

        // Register on Discord first
        final discordId = await _registerOnDiscord(
          resolvedName: resolvedName,
          resolvedDescription: resolvedDescription,
          resolvedData: resolvedData,
          botId: botId,
        );
        final newCmdId = discordId ?? uuid.v4();
        final localPayload = <String, dynamic>{
          'name': resolvedName,
          'description': resolvedDescription,
          'type':
              resolvedData['commandType'] ??
              resolvedData['type'] ??
              'chatInput',
          'id': newCmdId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'data': resolvedData,
        };
        await appManager.saveAppCommand(botId, newCmdId, localPayload);
        overwrittenCount++;
      }

      // Add workflows
      for (final workflow in template.workflows) {
        final resolvedWorkflow =
            resolveTemplateVariables(workflow, variables)
                as Map<String, dynamic>;
        final wName = (resolvedWorkflow['name'] ?? '').toString();
        final wActions = (resolvedWorkflow['actions'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final wEntryPoint = resolvedWorkflow['entryPoint']?.toString();
        final wArguments = (resolvedWorkflow['arguments'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final wType = resolvedWorkflow['workflowType']?.toString();
        final wEventTrigger = resolvedWorkflow['eventTrigger'] != null
            ? Map<String, dynamic>.from(resolvedWorkflow['eventTrigger'] as Map)
            : null;
        final wFolder = resolvedWorkflow['folder']?.toString();

        await appManager.saveWorkflow(
          botId,
          name: wName,
          actions: wActions,
          entryPoint: wEntryPoint,
          arguments: wArguments,
          workflowType: wType,
          eventTrigger: wEventTrigger,
          folder: wFolder,
        );
      }

      final parts = <String>[];
      if (addedCount > 0) parts.add('$addedCount added');
      if (overwrittenCount > 0) parts.add('$overwrittenCount replaced');
      if (skippedCount > 0) parts.add('$skippedCount kept local');
      unawaited(refreshBotRuntime(botId));
      return parts.isEmpty
          ? tr.marketplace_apply_success
          : 'Template applied: ${parts.join(', ')}';
    }
  }

  /// Register a command on Discord and return the assigned ID.
  /// Returns null if Discord is unreachable (command saved locally with UUID).
  Future<String?> _registerOnDiscord({
    required String resolvedName,
    required String resolvedDescription,
    required Map<String, dynamic> resolvedData,
    required String botId,
  }) async {
    try {
      final appManager = AppManager();
      final appData = await appManager.getApp(botId);
      final token = (appData['token'] ?? '').toString().trim();
      if (token.isEmpty) return null;

      final rest = await Nyxx.connectRest(token);
      try {
        final commandType =
            resolvedData['commandType']?.toString() ?? 'chatInput';
        final ApplicationCommandBuilder builder;
        switch (commandType) {
          case 'user':
            builder = ApplicationCommandBuilder.user(name: resolvedName);
          case 'message':
            builder = ApplicationCommandBuilder.message(name: resolvedName);
          default:
            final rawOptions =
                (resolvedData['options'] as List?)?.whereType<Map>().toList() ??
                [];
            final options = rawOptions.isNotEmpty
                ? deserializeCommandOptions(rawOptions)
                : <CommandOptionBuilder>[];
            builder = ApplicationCommandBuilder.chatInput(
              name: resolvedName,
              description: resolvedDescription,
              options: options,
            );
        }

        final permissionRaw = resolvedData['defaultMemberPermissions']
            ?.toString();
        if (permissionRaw != null && permissionRaw.isNotEmpty) {
          final perm = int.tryParse(permissionRaw);
          if (perm != null && perm > 0) {
            builder.defaultMemberPermissions = Permissions(perm);
          }
        }

        // Read integration types and contexts from command data
        final integrationTypesRaw = resolvedData['integrationTypes'];
        if (integrationTypesRaw is List && integrationTypesRaw.isNotEmpty) {
          builder.integrationTypes = integrationTypesRaw
              .map((t) => ApplicationIntegrationType(t as int))
              .toList();
        }
        final contextsRaw = resolvedData['contexts'];
        if (contextsRaw is List && contextsRaw.isNotEmpty) {
          builder.contexts = contextsRaw
              .map((c) => InteractionContextType(c as int))
              .toList();
        }

        final cmd = await rest.commands.create(builder);
        return cmd.id.toString();
      } finally {
        rest.close();
      }
    } catch (_) {
      return null;
    }
  }
}
