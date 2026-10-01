import 'dart:async';
import 'dart:io';
import 'package:nyxx/nyxx.dart';

/// Preserve actionable failures for the assistant without exposing HTTP bodies,
/// credentials, scripts or arbitrary exception text.
Map<String, dynamic> copilotToolFailure(Object error) {
  final known = error is HttpResponseError
      ? (
          'discord_request_failed',
          'Discord returned an error (HTTP ${error.statusCode}, code ${error.errorCode}). Inspect the current command state before retrying; success is not confirmed.',
        )
      : error is StateError
      ? switch (error.message) {
          'Command already exists; edit it instead' => (
            'command_exists',
            'A command with this name already exists on this device. Read its latest ID and revision, then update it instead of creating it again.',
          ),
          'Discord command already exists; import and edit it instead' => (
            'discord_command_exists',
            'A command with this name already exists on Discord. Import it and read its latest revision before editing it.',
          ),
          'Command not found' => (
            'command_not_found',
            'This command ID no longer exists on this device. List the current commands before proposing another update.',
          ),
          'Discord command identity not found' => (
            'discord_command_not_found',
            'This slash command has no matching registration on Discord. Inspect its invocation mode and synchronize its configuration before retrying.',
          ),
          'Discord command identity is ambiguous' => (
            'discord_command_ambiguous',
            'More than one Discord registration matches this command. Inspect its current identity before proposing another update.',
          ),
          'Command changed; read its latest revision before editing' ||
          'Configuration changed; read its latest revision before editing' => (
            'command_revision_conflict',
            'The command changed after it was inspected. Read its current revision before proposing another update.',
          ),
          'Execution mode does not match the bot runtime' ||
          'Workflow execution mode does not match bot runtime' => (
            'runtime_mismatch',
            'The proposed execution mode does not match the current bot runtime. Inspect the runtime and choose the matching mode.',
          ),
          'Configure the bot token in the application' ||
          'Configure the bot credentials in the application' => (
            'bot_credentials_missing',
            'The bot credentials are missing on this device. Configure them in the application before retrying.',
          ),
          'Bot identity does not match its token' ||
          'Bot identity does not match its credentials' ||
          'Tool targets another bot' => (
            'bot_identity_mismatch',
            'The action does not match the selected bot. Inspect the current bot before proposing another action.',
          ),
          'Unknown MCP tool' || 'Unsupported MCP tool' => (
            'tool_unavailable',
            'This tool is unavailable in the current application. Refresh the available tools before proposing another action.',
          ),
          _ => null,
        }
      : error is FormatException
      ? (
          'invalid_tool_arguments',
          'The tool rejected the proposed arguments. Inspect the current configuration and tool schema before proposing a corrected action.',
        )
      : error is TimeoutException || error is SocketException
      ? (
          'tool_connection_failed',
          'The connection failed or timed out. Inspect the current command state before retrying; success is not confirmed.',
        )
      : null;
  return {
    'isError': true,
    'approved': true,
    'success_confirmed': false,
    'code': known?.$1 ?? 'tool_execution_failed',
    if (error is HttpResponseError) ...{
      'http_status': error.statusCode,
      'discord_code': error.errorCode,
    },
    'message':
        known?.$2 ??
        'The action was approved, but execution failed on this device. Success is not confirmed. This was not an approval refusal.',
  };
}
