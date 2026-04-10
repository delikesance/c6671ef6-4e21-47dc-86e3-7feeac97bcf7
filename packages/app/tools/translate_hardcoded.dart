// ignore_for_file: avoid_print
/// Comprehensive migration script: extract hardcoded UI strings into ARB
/// files and replace them with context.tr.* calls.
///
/// Run from packages/app/:
///   dart run tools/translate_hardcoded.dart
library;

import 'dart:convert';
import 'dart:io';

// ── ARB key definitions ─────────────────────────────────────────────────────

/// All new keys mapped to {en, fr} values.
final Map<String, Map<String, String>> _keys = {
  // ── Phase 0: Common keys ───────────────────────────────────────────────
  'common_cancel': {'en': 'Cancel', 'fr': 'Annuler'},
  'common_ok': {'en': 'OK', 'fr': 'OK'},
  'common_save': {'en': 'Save', 'fr': 'Enregistrer'},
  'common_remove': {'en': 'Remove', 'fr': 'Supprimer'},
  'common_delete': {'en': 'Delete', 'fr': 'Supprimer'},
  'common_edit': {'en': 'Edit', 'fr': 'Modifier'},
  'common_apply': {'en': 'Apply', 'fr': 'Appliquer'},
  'common_close': {'en': 'Close', 'fr': 'Fermer'},
  'common_back': {'en': 'Back', 'fr': 'Retour'},
  'common_next': {'en': 'Next', 'fr': 'Suivant'},
  'common_enabled': {'en': 'Enabled', 'fr': 'Activé'},
  'common_import': {'en': 'Import', 'fr': 'Importer'},
  'common_retry': {'en': 'Retry', 'fr': 'Réessayer'},
  'common_move_up': {'en': 'Move up', 'fr': 'Déplacer vers le haut'},
  'common_move_down': {'en': 'Move down', 'fr': 'Déplacer vers le bas'},
  'common_name': {'en': 'Name', 'fr': 'Nom'},
  'common_value': {'en': 'Value', 'fr': 'Valeur'},
  'common_key': {'en': 'Key', 'fr': 'Clé'},
  'common_type': {'en': 'Type', 'fr': 'Type'},
  'common_required': {'en': 'Required', 'fr': 'Requis'},
  'common_description': {'en': 'Description', 'fr': 'Description'},
  'common_clear': {'en': 'Clear', 'fr': 'Effacer'},
  'common_all': {'en': 'All', 'fr': 'Tout'},
  'common_pick': {'en': 'Pick', 'fr': 'Choisir'},
  'common_add_argument': {'en': 'Add Argument', 'fr': 'Ajouter un argument'},
  'common_add_option': {'en': 'Add Option', 'fr': 'Ajouter une option'},
  'common_refresh': {'en': 'Refresh', 'fr': 'Actualiser'},
  'common_refresh_workflows': {
    'en': 'Refresh workflows',
    'fr': 'Actualiser les workflows',
  },
  'common_search': {'en': 'Search', 'fr': 'Rechercher'},
  'common_workflow': {'en': 'Workflow', 'fr': 'Workflow'},
  'common_static_options': {
    'en': 'Static Options',
    'fr': 'Options statiques',
  },
  'common_manage_workflows': {
    'en': 'Manage Workflows',
    'fr': 'Gérer les workflows',
  },

  // ── Phase 1: workflow_docs.page.dart ────────────────────────────────────
  // messageReactionAdd
  'doc_event_reaction_add_title': {
    'en': 'Event: messageReactionAdd',
    'fr': 'Événement : messageReactionAdd',
  },
  'doc_event_reaction_add_subtitle': {
    'en': 'Triggered when a user adds a reaction to a message.',
    'fr':
        "Déclenché quand un utilisateur ajoute une réaction à un message.",
  },
  'doc_event_reaction_add_summary': {
    'en':
        'Ideal for button-like UX without components, vote systems, role menus, and lightweight approvals.',
    'fr':
        "Idéal pour une UX type bouton sans composants, les systèmes de vote, les menus de rôles et les approbations légères.",
  },
  'doc_event_reaction_add_intent': {
    'en': 'Guild Message Reactions',
    'fr': 'Guild Message Reactions',
  },
  'doc_event_reaction_add_best_use_l1': {
    'en': 'Approve/reject flows with unicode emoji.',
    'fr': "Flux d'approbation/rejet avec des emojis unicode.",
  },
  'doc_event_reaction_add_best_use_l2': {
    'en': 'Multi-step polls using custom emoji IDs.',
    'fr':
        'Sondages multi-étapes utilisant des IDs d\'emojis personnalisés.',
  },
  'doc_event_reaction_add_best_use_l3': {
    'en': 'Quick moderation signals from staff channels.',
    'fr':
        'Signaux de modération rapides depuis les salons du staff.',
  },
  'doc_event_reaction_add_notes_l1': {
    'en': 'reaction.emoji.id can be empty for unicode emoji.',
    'fr':
        'reaction.emoji.id peut être vide pour les emojis unicode.',
  },
  'doc_event_reaction_add_notes_l2': {
    'en': 'Use reaction.emoji.name for generic matching.',
    'fr':
        'Utilisez reaction.emoji.name pour une correspondance générique.',
  },
  'doc_event_reaction_add_notes_l3': {
    'en': 'Use reaction.emoji.id for strict custom emoji matching.',
    'fr':
        'Utilisez reaction.emoji.id pour une correspondance stricte d\'emojis personnalisés.',
  },
  'doc_event_reaction_add_example': {
    'en':
        'Guard: ((reaction.emoji.name)) equals ✅\nAction: addRole -> user=((userId)) role=((global.approvedRoleId))',
    'fr':
        'Guard : ((reaction.emoji.name)) equals ✅\nAction : addRole -> user=((userId)) role=((global.approvedRoleId))',
  },

  // messagePollVoteAdd
  'doc_event_poll_vote_add_title': {
    'en': 'Event: messagePollVoteAdd',
    'fr': 'Événement : messagePollVoteAdd',
  },
  'doc_event_poll_vote_add_subtitle': {
    'en': 'Triggered when a user votes on a poll answer.',
    'fr':
        "Déclenché quand un utilisateur vote sur une réponse de sondage.",
  },
  'doc_event_poll_vote_add_summary': {
    'en':
        'Useful for score tracking, role assignment by poll option, and survey processing.',
    'fr':
        "Utile pour le suivi des scores, l'attribution de rôles par option de sondage et le traitement des enquêtes.",
  },
  'doc_event_poll_vote_add_intent': {
    'en': 'Guild Messages',
    'fr': 'Guild Messages',
  },
  'doc_event_poll_vote_add_best_use_l1': {
    'en': 'Map each answer id to a different action branch.',
    'fr':
        "Associer chaque identifiant de réponse à une branche d'action différente.",
  },
  'doc_event_poll_vote_add_best_use_l2': {
    'en': 'Track poll participation per channel or user group.',
    'fr':
        'Suivre la participation aux sondages par salon ou groupe d\'utilisateurs.',
  },
  'doc_event_poll_vote_add_notes_l1': {
    'en': 'poll.answer.id is the most stable key for routing.',
    'fr':
        "poll.answer.id est la clé la plus stable pour le routage.",
  },
  'doc_event_poll_vote_add_notes_l2': {
    'en':
        'poll.question is optional and may be empty depending on payload.',
    'fr':
        "poll.question est optionnel et peut être vide selon le payload.",
  },

  // voiceStateUpdate
  'doc_event_voice_state_update_title': {
    'en': 'Event: voiceStateUpdate',
    'fr': 'Événement : voiceStateUpdate',
  },
  'doc_event_voice_state_update_subtitle': {
    'en': 'Triggered when voice state changes for a user.',
    'fr':
        "Déclenché quand l'état vocal change pour un utilisateur.",
  },
  'doc_event_voice_state_update_summary': {
    'en':
        'Use this for auto-moderation in voice channels, attendance checks, and voice automation.',
    'fr':
        "Utilisez ceci pour la modération automatique dans les salons vocaux, le suivi de présence et l'automatisation vocale.",
  },
  'doc_event_voice_state_update_intent': {
    'en': 'Guilds',
    'fr': 'Guilds',
  },
  'doc_event_voice_state_update_section_title': {
    'en': 'Typical Automations',
    'fr': 'Automatisations typiques',
  },
  'doc_event_voice_state_update_automations_l1': {
    'en': 'Detect self-mute/self-deafen policy violations.',
    'fr':
        'Détecter les violations de politique de sourdine/désactivation du son.',
  },
  'doc_event_voice_state_update_automations_l2': {
    'en':
        'Trigger welcome message on voice join for support channels.',
    'fr':
        "Envoyer un message de bienvenue à la connexion vocale pour les salons de support.",
  },
  'doc_event_voice_state_update_automations_l3': {
    'en': 'Log leave/join patterns using channel changes.',
    'fr':
        "Journaliser les patterns d'arrivée/départ via les changements de salon.",
  },

  // userUpdate
  'doc_event_user_update_title': {
    'en': 'Event: userUpdate',
    'fr': 'Événement : userUpdate',
  },
  'doc_event_user_update_subtitle': {
    'en': 'Triggered when user profile data changes.',
    'fr':
        "Déclenché quand les données du profil utilisateur changent.",
  },
  'doc_event_user_update_summary': {
    'en':
        'Useful for profile-change auditing and username/avatar-driven triggers.',
    'fr':
        "Utile pour l'audit des changements de profil et les déclencheurs basés sur le pseudo/avatar.",
  },
  'doc_event_user_update_notes_l1': {
    'en': 'No channel context for this event in most cases.',
    'fr':
        "Pas de contexte de salon pour cet événement dans la plupart des cas.",
  },
  'doc_event_user_update_notes_l2': {
    'en':
        'Prefer logging + moderation alerts over direct user-facing replies.',
    'fr':
        "Privilégiez la journalisation + alertes de modération plutôt que les réponses directes à l'utilisateur.",
  },

  // guildAuditLogCreate
  'doc_event_audit_log_create_title': {
    'en': 'Event: guildAuditLogCreate',
    'fr': 'Événement : guildAuditLogCreate',
  },
  'doc_event_audit_log_create_subtitle': {
    'en': 'Triggered when a new audit log entry is created.',
    'fr':
        "Déclenché quand une nouvelle entrée du journal d'audit est créée.",
  },
  'doc_event_audit_log_create_summary': {
    'en': 'High-value event for administrative security monitoring.',
    'fr':
        "Événement à haute valeur pour la surveillance de sécurité administrative.",
  },
  'doc_event_audit_log_create_best_use_l1': {
    'en':
        'Alert staff on sensitive actions (role delete, webhook create, ban, etc.).',
    'fr':
        "Alerter le staff sur les actions sensibles (suppression de rôle, création de webhook, ban, etc.).",
  },
  'doc_event_audit_log_create_best_use_l2': {
    'en': 'Route specific action types to dedicated workflows.',
    'fr':
        "Router des types d'actions spécifiques vers des workflows dédiés.",
  },

  // action.stopUnless
  'doc_action_stop_unless_title': {
    'en': 'Action: stopUnless',
    'fr': 'Action : stopUnless',
  },
  'doc_action_stop_unless_subtitle': {
    'en': 'Guard clause that stops workflow when condition fails.',
    'fr':
        "Clause de garde qui arrête le workflow quand la condition échoue.",
  },
  'doc_action_stop_unless_summary': {
    'en':
        'Use it at the top of workflows to prevent unnecessary actions when context does not match.',
    'fr':
        "Utilisez-le en haut des workflows pour éviter les actions inutiles quand le contexte ne correspond pas.",
  },
  'doc_action_stop_unless_section_operators': {
    'en': 'Supported Operators',
    'fr': 'Opérateurs supportés',
  },
  'doc_action_stop_unless_operators_l1': {
    'en':
        'equals, notEquals, contains, notContains, startsWith, endsWith',
    'fr':
        'equals, notEquals, contains, notContains, startsWith, endsWith',
  },
  'doc_action_stop_unless_operators_l2': {
    'en': 'greaterThan, lessThan, greaterOrEqual, lessOrEqual',
    'fr': 'greaterThan, lessThan, greaterOrEqual, lessOrEqual',
  },
  'doc_action_stop_unless_operators_l3': {
    'en': 'isEmpty, isNotEmpty, matches',
    'fr': 'isEmpty, isNotEmpty, matches',
  },
  'doc_action_stop_unless_section_format': {
    'en': 'Condition Variable Format',
    'fr': 'Format de la variable de condition',
  },
  'doc_action_stop_unless_format_l1': {
    'en': 'You can use raw keys: message.content[0]',
    'fr':
        'Vous pouvez utiliser des clés brutes : message.content[0]',
  },
  'doc_action_stop_unless_format_l2': {
    'en': 'You can use wrapped variables: ((message.content[0]))',
    'fr':
        'Vous pouvez utiliser des variables encapsulées : ((message.content[0]))',
  },
  'doc_action_stop_unless_format_l3': {
    'en': 'Both are resolved by runtime.',
    'fr': 'Les deux sont résolus par le runtime.',
  },
  'doc_action_stop_unless_example': {
    'en':
        'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅',
    'fr':
        'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅',
  },

  // action.ifBlock
  'doc_action_if_block_title': {
    'en': 'Action: ifBlock',
    'fr': 'Action : ifBlock',
  },
  'doc_action_if_block_subtitle': {
    'en':
        'Branch execution between THEN, ELSE IF and ELSE nested action lists.',
    'fr':
        "Branche l'exécution entre les listes d'actions imbriquées THEN, ELSE IF et ELSE.",
  },
  'doc_action_if_block_summary': {
    'en':
        'Use this to keep a single workflow while handling several outcomes based on runtime state.',
    'fr':
        "Utilisez ceci pour garder un seul workflow tout en gérant plusieurs résultats selon l'état d'exécution.",
  },
  'doc_action_if_block_section_execution': {
    'en': 'Execution Model',
    'fr': "Modèle d'exécution",
  },
  'doc_action_if_block_execution_l1': {
    'en': 'Condition is evaluated once.',
    'fr': 'La condition est évaluée une seule fois.',
  },
  'doc_action_if_block_execution_l2': {
    'en':
        'The first matching branch executes: THEN, then ELSE IF blocks in order, then ELSE.',
    'fr':
        "La première branche correspondante s'exécute : THEN, puis les blocs ELSE IF dans l'ordre, puis ELSE.",
  },
  'doc_action_if_block_execution_l3': {
    'en':
        'Nested actions can include runWorkflow, API calls, and interaction replies.',
    'fr':
        "Les actions imbriquées peuvent inclure runWorkflow, des appels API et des réponses d'interaction.",
  },

  // action.runWorkflow
  'doc_action_run_workflow_title': {
    'en': 'Action: runWorkflow',
    'fr': 'Action : runWorkflow',
  },
  'doc_action_run_workflow_subtitle': {
    'en': 'Calls another workflow with entry point and arguments.',
    'fr':
        "Appelle un autre workflow avec un point d'entrée et des arguments.",
  },
  'doc_action_run_workflow_summary': {
    'en':
        'Core composition primitive to split business logic into reusable units.',
    'fr':
        "Primitive de composition pour découper la logique métier en unités réutilisables.",
  },
  'doc_action_run_workflow_section_practices': {
    'en': 'Best Practices',
    'fr': 'Bonnes pratiques',
  },
  'doc_action_run_workflow_practices_l1': {
    'en':
        'Keep top-level workflow thin and delegate to domain workflows.',
    'fr':
        "Gardez le workflow principal léger et déléguez aux workflows de domaine.",
  },
  'doc_action_run_workflow_practices_l2': {
    'en':
        'Pass explicit arguments instead of relying on implicit globals.',
    'fr':
        'Passez des arguments explicites au lieu de dépendre des globales implicites.',
  },
  'doc_action_run_workflow_practices_l3': {
    'en':
        'Use entry points to model sub-routines (create, close, assign, escalate).',
    'fr':
        "Utilisez les points d'entrée pour modéliser des sous-routines (create, close, assign, escalate).",
  },

  // action.httpRequest
  'doc_action_http_request_title': {
    'en': 'Action: httpRequest',
    'fr': 'Action : httpRequest',
  },
  'doc_action_http_request_subtitle': {
    'en': 'Executes an external HTTP call inside a workflow.',
    'fr': "Exécute un appel HTTP externe dans un workflow.",
  },
  'doc_action_http_request_summary': {
    'en':
        'Use this for webhooks, internal APIs, moderation services, AI endpoints, and integrations.',
    'fr':
        "Utilisez ceci pour les webhooks, APIs internes, services de modération, endpoints IA et intégrations.",
  },
  'doc_action_http_request_section_checklist': {
    'en': 'Reliability Checklist',
    'fr': 'Checklist de fiabilité',
  },
  'doc_action_http_request_checklist_l1': {
    'en':
        'Set explicit timeout and retries in your service layer when possible.',
    'fr':
        'Définissez un timeout et des retries explicites dans votre couche de services quand c\'est possible.',
  },
  'doc_action_http_request_checklist_l2': {
    'en':
        'Store API keys in globals or secure backend, never hardcode tokens.',
    'fr':
        "Stockez les clés API dans les globales ou un backend sécurisé, ne codez jamais les tokens en dur.",
  },
  'doc_action_http_request_checklist_l3': {
    'en':
        'Validate status code and response body before next actions.',
    'fr':
        "Validez le code de statut et le corps de la réponse avant les actions suivantes.",
  },

  // ── Phase 2: response_embeds_editor.dart ───────────────────────────────
  'embed_color_picker_title': {
    'en': 'Pick embed color',
    'fr': "Choisir la couleur de l'embed",
  },
  'embed_delete_title': {'en': 'Delete embed', 'fr': "Supprimer l'embed"},
  'embed_delete_confirm': {
    'en': 'This embed will be removed. Continue?',
    'fr': "Cet embed sera supprimé. Continuer ?",
  },
  'embed_field_delete_title': {
    'en': 'Delete field',
    'fr': 'Supprimer le champ',
  },
  'embed_field_delete_confirm': {
    'en': 'This field will be removed from the embed. Continue?',
    'fr': "Ce champ sera supprimé de l'embed. Continuer ?",
  },
  'embed_response_header': {
    'en': 'Response Embeds ({count}/{max})',
    'fr': 'Embeds de réponse ({count}/{max})',
  },
  '@embed_response_header': {
    'en': '',
    'fr': '',
  },
  'embed_add_tooltip': {'en': 'Add embed', 'fr': 'Ajouter un embed'},
  'embed_empty_message': {
    'en': 'No embeds. You can add up to {max} embeds.',
    'fr': "Aucun embed. Vous pouvez en ajouter jusqu'à {max}.",
  },
  '@embed_empty_message': {
    'en': '',
    'fr': '',
  },
  'embed_number': {
    'en': 'Embed #{index}',
    'fr': 'Embed #{index}',
  },
  '@embed_number': {
    'en': '',
    'fr': '',
  },
  'embed_label_title': {'en': 'Title', 'fr': 'Titre'},
  'embed_label_url': {'en': 'URL', 'fr': 'URL'},
  'embed_label_timestamp': {
    'en': 'Timestamp (ISO8601)',
    'fr': 'Horodatage (ISO8601)',
  },
  'embed_label_color': {
    'en': 'Color (int or #hex)',
    'fr': 'Couleur (int ou #hex)',
  },
  'embed_section_footer': {'en': 'Footer', 'fr': 'Pied de page'},
  'embed_label_footer_text': {
    'en': 'Footer Text',
    'fr': 'Texte du pied de page',
  },
  'embed_label_footer_icon': {
    'en': 'Footer Icon URL',
    'fr': 'URL icône du pied de page',
  },
  'embed_section_author': {'en': 'Author', 'fr': 'Auteur'},
  'embed_label_author_name': {
    'en': 'Author Name',
    'fr': "Nom de l'auteur",
  },
  'embed_label_author_url': {
    'en': 'Author URL',
    'fr': "URL de l'auteur",
  },
  'embed_label_author_icon': {
    'en': 'Author Icon URL',
    'fr': "URL icône de l'auteur",
  },
  'embed_section_media': {'en': 'Media', 'fr': 'Médias'},
  'embed_label_image_url': {'en': 'Image URL', 'fr': "URL de l'image"},
  'embed_label_thumbnail_url': {
    'en': 'Thumbnail URL',
    'fr': 'URL de la miniature',
  },
  'embed_fields_header': {
    'en': 'Fields ({count}/25)',
    'fr': 'Champs ({count}/25)',
  },
  '@embed_fields_header': {
    'en': '',
    'fr': '',
  },
  'embed_fields_empty': {'en': 'No fields yet.', 'fr': 'Aucun champ.'},
  'embed_field_number': {
    'en': 'Field #{index}',
    'fr': 'Champ #{index}',
  },
  '@embed_field_number': {
    'en': '',
    'fr': '',
  },
  'embed_label_inline': {'en': 'Inline', 'fr': 'En ligne'},
  'embed_label_dynamic_fields': {
    'en': 'Dynamic Fields Template',
    'fr': 'Modèle de champs dynamiques',
  },

  // ── Phase 3: component_node_editor.dart ────────────────────────────────
  'component_remove_title': {
    'en': 'Remove component',
    'fr': 'Supprimer le composant',
  },
  'component_remove_confirm': {
    'en': 'This component will be removed from the layout. Continue?',
    'fr':
        'Ce composant sera supprimé de la mise en page. Continuer ?',
  },
  'component_label': {'en': 'Label', 'fr': 'Libellé'},
  'component_style': {'en': 'Style', 'fr': 'Style'},
  'component_url': {'en': 'URL', 'fr': 'URL'},
  'component_custom_id_required': {
    'en': 'Custom ID *',
    'fr': 'ID personnalisé *',
  },
  'component_validation_required': {
    'en': 'Required',
    'fr': 'Requis',
  },
  'component_workflow_optional': {
    'en': 'Call Workflow (optional)',
    'fr': 'Appeler un workflow (optionnel)',
  },
  'component_workflow_click_hint': {
    'en': 'Saved workflow name to run on click',
    'fr': 'Nom du workflow sauvegardé à exécuter au clic',
  },
  'component_workflow_select_hint': {
    'en': 'Saved workflow name to run on selection',
    'fr': 'Nom du workflow sauvegardé à exécuter à la sélection',
  },
  'component_custom_id': {'en': 'Custom ID', 'fr': 'ID personnalisé'},
  'component_placeholder': {
    'en': 'Placeholder',
    'fr': 'Texte indicatif',
  },
  'component_options': {'en': 'Options', 'fr': 'Options'},
  'component_markdown_content': {
    'en': 'Markdown Content',
    'fr': 'Contenu Markdown',
  },
  'component_visible_divider': {
    'en': 'Visible Divider Line',
    'fr': 'Ligne de séparation visible',
  },
  'component_spacing_small': {
    'en': 'Small Spacing',
    'fr': 'Espacement réduit',
  },
  'component_spacing_large': {
    'en': 'Large Spacing',
    'fr': 'Espacement large',
  },
  'component_section_text_displays': {
    'en': 'Text Displays',
    'fr': 'Affichages de texte',
  },
  'component_add_text_display': {
    'en': 'Add Text Display',
    'fr': 'Ajouter un affichage texte',
  },
  'component_section_accessory': {
    'en': 'Accessory Node (Optional)',
    'fr': 'Nœud accessoire (optionnel)',
  },
  'component_accent_color': {
    'en': 'Accent Color (Hex, e.g. FF0000)',
    'fr': 'Couleur d\'accentuation (Hex, ex. FF0000)',
  },
  'component_pick_accent_color': {
    'en': 'Pick Accent Color',
    'fr': "Choisir la couleur d'accentuation",
  },
  'component_add_child': {
    'en': 'Add Child Component',
    'fr': 'Ajouter un composant enfant',
  },
  'component_checked_by_default': {
    'en': 'Checked by default',
    'fr': 'Coché par défaut',
  },
  'component_add_radio_option': {
    'en': 'Add Radio Option',
    'fr': 'Ajouter une option radio',
  },
  'component_add_media_item': {
    'en': 'Add Media Item',
    'fr': 'Ajouter un élément média',
  },
  'component_not_implemented': {
    'en': 'Editor not implemented yet',
    'fr': "Éditeur pas encore implémenté",
  },
  'component_choose_color': {
    'en': 'Choose Color',
    'fr': 'Choisir la couleur',
  },
  'component_label_title': {
    'en': 'Label Title',
    'fr': 'Titre du libellé',
  },
  'component_workflow_args_title': {
    'en': 'Workflow Call Arguments (JSON)',
    'fr': "Arguments d'appel du workflow (JSON)",
  },
  'component_workflow_args_hint': {
    'en': 'Example: {"ticketId":"((opts.ticket))"}',
    'fr': 'Exemple : {"ticketId":"((opts.ticket))"}',
  },

  // autocomplete / workflow selector (shared between component_node_editor, option_widget)
  'autocomplete_workflow_label': {
    'en': 'Autocomplete Workflow',
    'fr': "Workflow d'autocomplétion",
  },
  'autocomplete_loading': {
    'en': 'Loading workflows…',
    'fr': 'Chargement des workflows…',
  },
  'autocomplete_no_workflows': {
    'en': 'No saved workflows found',
    'fr': 'Aucun workflow sauvegardé trouvé',
  },
  'autocomplete_select_workflow': {
    'en': 'Select a saved workflow',
    'fr': 'Sélectionnez un workflow sauvegardé',
  },
  'autocomplete_type_name': {
    'en': 'Or type workflow name',
    'fr': 'Ou tapez le nom du workflow',
  },
  'workflow_entry_point': {
    'en': 'Entry Point',
    'fr': "Point d'entrée",
  },
  'workflow_arguments_section': {
    'en': 'Workflow Arguments',
    'fr': 'Arguments du workflow',
  },
  'hint_use_variables': {
    'en': 'Use variables/templates if needed',
    'fr': 'Utilisez des variables/templates si nécessaire',
  },
  'autocomplete_dynamic': {
    'en': 'Dynamic Autocomplete',
    'fr': 'Autocomplétion dynamique',
  },
  'autocomplete_dynamic_desc': {
    'en': 'Resolve choices from a workflow instead of static values.',
    'fr':
        'Résoudre les choix depuis un workflow au lieu de valeurs statiques.',
  },
  'autocomplete_filter_hint': {
    'en': 'Suggestions are filtered by what the user types.',
    'fr':
        "Les suggestions sont filtrées selon ce que l'utilisateur tape.",
  },

  // ── Phase 4: option_widget.dart ────────────────────────────────────────
  'option_delete_title': {
    'en': 'Delete option',
    'fr': "Supprimer l'option",
  },
  'option_delete_confirm': {
    'en': 'This option will be removed. Continue?',
    'fr': 'Cette option sera supprimée. Continuer ?',
  },
  'option_desc_required': {
    'en': 'Please enter a description for the option',
    'fr': "Veuillez entrer une description pour l'option",
  },
  'option_delete_argument_title': {
    'en': 'Delete argument',
    'fr': "Supprimer l'argument",
  },
  'option_delete_argument_confirm': {
    'en': 'This argument will be removed. Continue?',
    'fr': 'Cet argument sera supprimé. Continuer ?',
  },
  'option_static_label_n': {
    'en': 'Label {index}',
    'fr': 'Libellé {index}',
  },
  '@option_static_label_n': {'en': '', 'fr': ''},
  'option_static_value_n': {
    'en': 'Value {index}',
    'fr': 'Valeur {index}',
  },
  '@option_static_value_n': {'en': '', 'fr': ''},
  'option_delete_choice_title': {
    'en': 'Delete option',
    'fr': "Supprimer l'option",
  },
  'option_delete_choice_confirm': {
    'en': 'This choice will be removed. Continue?',
    'fr': 'Ce choix sera supprimé. Continuer ?',
  },
  'option_default_name': {
    'en': 'Option {index}',
    'fr': 'Option {index}',
  },
  '@option_default_name': {'en': '', 'fr': ''},
  'option_min_value': {'en': 'Min Value', 'fr': 'Valeur min'},
  'option_max_value': {'en': 'Max Value', 'fr': 'Valeur max'},
  'option_add_localizations': {
    'en': 'Add Localizations',
    'fr': 'Ajouter des localisations',
  },
  'option_select_language': {
    'en': 'Select Language',
    'fr': 'Sélectionner la langue',
  },
  'option_delete_localization_title': {
    'en': 'Delete localization',
    'fr': 'Supprimer la localisation',
  },
  'option_delete_localization_confirm': {
    'en': 'This localization entry will be removed. Continue?',
    'fr': 'Cette entrée de localisation sera supprimée. Continuer ?',
  },
  'option_localized_name': {
    'en': 'Localized Name',
    'fr': 'Nom localisé',
  },
  'option_localized_description': {
    'en': 'Localized Description',
    'fr': 'Description localisée',
  },
  'option_choice_number': {
    'en': 'Choice {index}',
    'fr': 'Choix {index}',
  },
  '@option_choice_number': {'en': '', 'fr': ''},
  'option_choice_delete_title': {
    'en': 'Delete choice',
    'fr': 'Supprimer le choix',
  },
  'option_choice_delete_confirm': {
    'en': 'This choice will be removed. Continue?',
    'fr': 'Ce choix sera supprimé. Continuer ?',
  },
  'option_choice_name': {'en': 'Choice Name', 'fr': 'Nom du choix'},
  'option_choice_value': {
    'en': 'Choice Value',
    'fr': 'Valeur du choix',
  },
  'option_add_choice': {
    'en': 'Add Choice',
    'fr': 'Ajouter un choix',
  },
  'option_subcommands': {
    'en': 'SubCommands',
    'fr': 'Sous-commandes',
  },
  'option_subcommand_options': {
    'en': 'SubCommand Options',
    'fr': 'Options de sous-commande',
  },

  // ── Phase 5: action_card.dart ──────────────────────────────────────────
  'action_options_tooltip': {
    'en': 'Action options',
    'fr': "Options de l'action",
  },
  'action_remove_menu': {
    'en': 'Remove action',
    'fr': "Supprimer l'action",
  },
  'action_order_tip': {
    'en': 'Tip: use arrows to change action order.',
    'fr':
        "Astuce : utilisez les flèches pour changer l'ordre des actions.",
  },
  'action_key_field': {'en': 'Action Key', 'fr': "Clé d'action"},
  'action_on_error': {'en': 'On Error', 'fr': 'En cas d\'erreur'},
  'action_error_stop': {'en': 'Stop', 'fr': 'Arrêter'},
  'action_error_continue': {'en': 'Continue', 'fr': 'Continuer'},
  'action_advanced_settings': {
    'en': 'Advanced settings',
    'fr': 'Paramètres avancés',
  },
  'action_status_enabled': {'en': 'Enabled', 'fr': 'Activé'},
  'action_status_disabled': {'en': 'Disabled', 'fr': 'Désactivé'},
  'action_remove_title': {
    'en': 'Remove action',
    'fr': "Supprimer l'action",
  },
  'action_remove_confirm': {
    'en': 'This action will be removed from the workflow. Continue?',
    'fr':
        'Cette action sera supprimée du workflow. Continuer ?',
  },
  'action_store_results': {
    'en': 'Store results in global variables',
    'fr': 'Stocker les résultats dans les variables globales',
  },
  'action_http_test_button': {
    'en': 'Send Test Request & Auto-Detect Routes',
    'fr': 'Envoyer une requête test et détecter les routes',
  },
  'action_http_test_title': {
    'en': 'Test Request Results',
    'fr': 'Résultats de la requête test',
  },
  'action_http_status': {
    'en': 'Status: {status}',
    'fr': 'Statut : {status}',
  },
  '@action_http_status': {'en': '', 'fr': ''},
  'action_http_paths_parsed': {
    'en': '{count} paths parsed',
    'fr': '{count} chemins analysés',
  },
  '@action_http_paths_parsed': {'en': '', 'fr': ''},
  'action_http_response_body': {
    'en': 'Response Body (Raw):',
    'fr': 'Corps de la réponse (brut) :',
  },
  'action_literal': {'en': 'Literal', 'fr': 'Littéral'},
  'action_dynamic': {'en': 'Dynamic', 'fr': 'Dynamique'},
  'action_add_else_if': {
    'en': 'Add ELSE IF',
    'fr': 'Ajouter ELSE IF',
  },
  'action_remove_else_if': {
    'en': 'Remove ELSE IF',
    'fr': 'Supprimer ELSE IF',
  },
  'action_condition_variable': {
    'en': 'Condition Variable',
    'fr': 'Variable de condition',
  },
  'action_condition_value': {
    'en': 'Condition Value',
    'fr': 'Valeur de condition',
  },
  'action_else_if_label': {
    'en': 'ELSE IF {index} — actions',
    'fr': 'ELSE IF {index} — actions',
  },
  '@action_else_if_label': {'en': '', 'fr': ''},
  'action_expression': {'en': 'Expression', 'fr': 'Expression'},
  'action_edit_param': {
    'en': 'Edit {name}',
    'fr': 'Modifier {name}',
  },
  '@action_edit_param': {'en': '', 'fr': ''},
  'action_choose_param': {
    'en': 'Choose {name}',
    'fr': 'Choisir {name}',
  },
  '@action_choose_param': {'en': '', 'fr': ''},
  'action_format_json': {
    'en': 'Format JSON',
    'fr': 'Formater le JSON',
  },
  'action_add_header': {
    'en': 'Add header',
    'fr': 'Ajouter un en-tête',
  },
  'action_clear_all': {
    'en': 'Clear all',
    'fr': 'Tout effacer',
  },
  'action_refresh_keys': {
    'en': 'Refresh keys',
    'fr': 'Actualiser les clés',
  },
  'action_manage_variable_keys': {
    'en': 'Manage Variable Keys',
    'fr': 'Gérer les clés de variables',
  },

  // ── Phase 6: command.create.validation.dart ────────────────────────────
  'validation_command_name_required': {
    'en': 'Please enter a command name',
    'fr': 'Veuillez entrer un nom de commande',
  },
  'validation_awaited_callback_local_only': {
    'en': 'Awaited callbacks require a local-only Legacy Command.',
    'fr':
        'Les callbacks attendus nécessitent une commande Legacy locale uniquement.',
  },
  'validation_awaited_callback_length': {
    'en':
        'Awaited callback trigger must be at most {max} characters long',
    'fr':
        'Le déclencheur de callback attendu doit contenir au maximum {max} caractères',
  },
  '@validation_awaited_callback_length': {'en': '', 'fr': ''},
  'validation_awaited_callback_format': {
    'en':
        r'Awaited callback must use $awaitedCommand[name;filter] or $awaitedCommandError[name].',
    'fr':
        r'Le callback attendu doit utiliser $awaitedCommand[name;filter] ou $awaitedCommandError[name].',
  },
  'validation_command_name_length': {
    'en': 'Command name must be at most {max} characters long',
    'fr': 'Le nom de commande doit contenir au maximum {max} caractères',
  },
  '@validation_command_name_length': {'en': '', 'fr': ''},
  'validation_command_name_no_spaces': {
    'en': 'Command name cannot contain spaces',
    'fr': 'Le nom de commande ne peut pas contenir d\'espaces',
  },
  'validation_command_name_invalid_chars': {
    'en':
        'Command name can only contain letters, numbers, and underscores',
    'fr':
        'Le nom de commande ne peut contenir que des lettres, chiffres et underscores',
  },
  'validation_command_name_no_underscore': {
    'en': 'Command name cannot start with an underscore',
    'fr': 'Le nom de commande ne peut pas commencer par un underscore',
  },
  'validation_command_name_no_exclamation': {
    'en': 'Command name cannot start with an exclamation mark',
    'fr':
        "Le nom de commande ne peut pas commencer par un point d'exclamation",
  },
  'validation_command_name_no_slash': {
    'en': 'Command name cannot start with a slash',
    'fr': 'Le nom de commande ne peut pas commencer par un slash',
  },
  'validation_command_name_no_hash': {
    'en': 'Command name cannot start with a hash',
    'fr': 'Le nom de commande ne peut pas commencer par un dièse',
  },
  'validation_command_name_no_at': {
    'en': 'Command name cannot start with an at sign',
    'fr': 'Le nom de commande ne peut pas commencer par un arobase',
  },
  'validation_command_name_no_ampersand': {
    'en': 'Command name cannot start with an ampersand',
    'fr': 'Le nom de commande ne peut pas commencer par une esperluette',
  },
  'validation_command_name_no_percent': {
    'en': 'Command name cannot start with a percent sign',
    'fr':
        'Le nom de commande ne peut pas commencer par un signe pourcent',
  },
  'validation_legacy_chat_input_only': {
    'en': 'Legacy mode is only available for chat input commands.',
    'fr':
        "Le mode legacy est disponible uniquement pour les commandes de saisie.",
  },
  'validation_modal_not_legacy': {
    'en': 'Modal responses are not supported in legacy command mode.',
    'fr':
        'Les réponses modales ne sont pas supportées en mode commande legacy.',
  },
  'validation_legacy_only_requires_legacy': {
    'en': 'Legacy-only commands require legacy mode to be enabled.',
    'fr':
        'Les commandes legacy-only nécessitent que le mode legacy soit activé.',
  },
  'validation_legacy_only_new_or_local': {
    'en':
        'Legacy-only mode can only be used for new commands or existing local commands.',
    'fr':
        'Le mode legacy-only ne peut être utilisé que pour les nouvelles commandes ou les commandes locales existantes.',
  },
  'validation_invalid_permissions': {
    'en':
        'Invalid default member permissions bitfield. Use a positive integer or leave empty.',
    'fr':
        'Champ de bits de permissions par défaut invalide. Utilisez un entier positif ou laissez vide.',
  },

  // ── Phase 7: scheduler.page.dart ───────────────────────────────────────
  'scheduler_no_workflows': {
    'en': 'Create at least one workflow before adding a schedule.',
    'fr':
        'Créez au moins un workflow avant d\'ajouter un planning.',
  },
  'scheduler_add_title': {
    'en': 'Add schedule',
    'fr': 'Ajouter un planning',
  },
  'scheduler_edit_title': {
    'en': 'Edit schedule',
    'fr': 'Modifier le planning',
  },
  'scheduler_label_hint': {
    'en': 'Optional display label',
    'fr': "Libellé d'affichage optionnel",
  },
  'scheduler_label_field': {'en': 'Label', 'fr': 'Libellé'},
  'scheduler_every_minutes': {
    'en': 'Every (minutes)',
    'fr': 'Toutes les (minutes)',
  },
  'scheduler_invalid_minutes': {
    'en': 'Every minutes must be greater than 0.',
    'fr': 'Les minutes doivent être supérieures à 0.',
  },
  'scheduler_limit_reached': {
    'en': 'Scheduler limit reached ({limit}).',
    'fr': 'Limite du planificateur atteinte ({limit}).',
  },
  '@scheduler_limit_reached': {'en': '', 'fr': ''},
  'scheduler_save_failed': {
    'en': 'Failed to save schedule: {error}',
    'fr': "Échec de l'enregistrement du planning : {error}",
  },
  '@scheduler_save_failed': {'en': '', 'fr': ''},
  'scheduler_delete_title': {
    'en': 'Delete schedule',
    'fr': 'Supprimer le planning',
  },
  'scheduler_delete_confirm': {
    'en': 'Delete "{label}" schedule?',
    'fr': 'Supprimer le planning « {label} » ?',
  },
  '@scheduler_delete_confirm': {'en': '', 'fr': ''},
  'scheduler_page_title': {
    'en': 'Scheduler',
    'fr': 'Planificateur',
  },
  'scheduler_add_trigger': {
    'en': 'Add trigger',
    'fr': 'Ajouter un déclencheur',
  },
  'scheduler_triggers_count': {
    'en': 'Triggers: {count}{limit}',
    'fr': 'Déclencheurs : {count}{limit}',
  },
  '@scheduler_triggers_count': {'en': '', 'fr': ''},
  'scheduler_empty': {
    'en': 'No scheduled triggers yet.',
    'fr': 'Aucun déclencheur planifié.',
  },

  // ── Phase 8: inbound_webhooks.page.dart ────────────────────────────────
  'webhooks_no_workflows': {
    'en': 'Create at least one workflow before adding an inbound webhook.',
    'fr':
        'Créez au moins un workflow avant d\'ajouter un webhook entrant.',
  },
  'webhooks_add_title': {
    'en': 'Add inbound webhook',
    'fr': 'Ajouter un webhook entrant',
  },
  'webhooks_edit_title': {
    'en': 'Edit inbound webhook',
    'fr': 'Modifier le webhook entrant',
  },
  'webhooks_path_label': {'en': 'Path', 'fr': 'Chemin'},
  'webhooks_path_hint': {'en': 'orders/new', 'fr': 'orders/new'},
  'webhooks_target_label': {
    'en': 'Workflow target',
    'fr': 'Workflow cible',
  },
  'webhooks_secret_label': {
    'en': 'Webhook secret',
    'fr': 'Secret du webhook',
  },
  'webhooks_generate': {'en': 'Generate', 'fr': 'Générer'},
  'webhooks_limit_reached': {
    'en': 'Inbound webhook limit reached ({limit}).',
    'fr': 'Limite de webhooks entrants atteinte ({limit}).',
  },
  '@webhooks_limit_reached': {'en': '', 'fr': ''},
  'webhooks_path_exists': {
    'en': 'This path already exists. Choose another one.',
    'fr': 'Ce chemin existe déjà. Choisissez-en un autre.',
  },
  'webhooks_save_failed': {
    'en': 'Failed to save inbound webhook: {error}',
    'fr': "Échec de l'enregistrement du webhook entrant : {error}",
  },
  '@webhooks_save_failed': {'en': '', 'fr': ''},
  'webhooks_delete_title': {
    'en': 'Delete inbound webhook?',
    'fr': 'Supprimer le webhook entrant ?',
  },
  'webhooks_delete_confirm': {
    'en': 'Delete "{label}"? This cannot be undone.',
    'fr':
        'Supprimer « {label} » ? Cette action est irréversible.',
  },
  '@webhooks_delete_confirm': {'en': '', 'fr': ''},
  'webhooks_delete_confirm_no_label': {
    'en': 'This cannot be undone.',
    'fr': 'Cette action est irréversible.',
  },
  'webhooks_runner_url_required': {
    'en':
        'Configure a Runner URL first to copy the full webhook URL.',
    'fr':
        "Configurez d'abord une URL Runner pour copier l'URL complète du webhook.",
  },
  'webhooks_missing_data': {
    'en': 'Webhook path or secret is missing.',
    'fr': 'Le chemin ou le secret du webhook est manquant.',
  },
  'webhooks_copied': {
    'en': 'Full webhook URL copied.',
    'fr': "URL complète du webhook copiée.",
  },
  'webhooks_invalid_runner_url': {
    'en': 'Runner URL is invalid.',
    'fr': "L'URL du Runner est invalide.",
  },
  'webhooks_page_title': {
    'en': 'Inbound Webhooks',
    'fr': 'Webhooks entrants',
  },
  'webhooks_add_action': {
    'en': 'Add webhook',
    'fr': 'Ajouter un webhook',
  },
  'webhooks_empty': {
    'en': 'No inbound webhooks yet.',
    'fr': 'Aucun webhook entrant.',
  },
  'webhooks_workflow_subtitle': {
    'en': 'Workflow: {workflow}',
    'fr': 'Workflow : {workflow}',
  },
  '@webhooks_workflow_subtitle': {'en': '', 'fr': ''},
  'webhooks_copy_url': {'en': 'Copy URL', 'fr': "Copier l'URL"},
  'webhooks_copy_path': {
    'en': 'Copy path',
    'fr': 'Copier le chemin',
  },
  'webhooks_copy_secret': {
    'en': 'Copy secret',
    'fr': 'Copier le secret',
  },
  'webhooks_actions': {'en': 'Actions', 'fr': 'Actions'},

  // ── Phase 9: command.create.dart ───────────────────────────────────────
  'command_legacy_mode_title': {
    'en': 'Enable legacy mode on this command',
    'fr': 'Activer le mode legacy sur cette commande',
  },
  'command_legacy_mode_subtitle': {
    'en': 'Uses positional options (example: !config #channel).',
    'fr':
        'Utilise des options positionnelles (exemple : !config #channel).',
  },
  'command_legacy_prefix_title': {
    'en': 'Legacy Prefix Mode',
    'fr': 'Mode préfixe legacy',
  },
  'command_legacy_prefix_desc': {
    'en':
        'Handle commands from messageCreate using <prefix><command>.',
    'fr':
        'Gérer les commandes de messageCreate avec <préfixe><commande>.',
  },
  'command_prefix_override_label': {
    'en': 'Prefix override (optional)',
    'fr': 'Remplacement du préfixe (optionnel)',
  },
  'command_prefix_override_hint': {
    'en': 'Example: ? or ((guild.prefix | !))',
    'fr': 'Exemple : ? ou ((guild.prefix | !))',
  },
  'command_legacy_response_label': {
    'en': 'Legacy response mode',
    'fr': 'Mode de réponse legacy',
  },
  'command_response_mode_reply': {
    'en': 'message.reply',
    'fr': 'message.reply',
  },
  'command_response_mode_channel': {
    'en': 'message.channel.send',
    'fr': 'message.channel.send',
  },
  'command_modal_disabled_legacy': {
    'en': 'Modals are disabled in legacy mode.',
    'fr': 'Les modals sont désactivés en mode legacy.',
  },
  'command_target_subcommand': {
    'en': 'Target subcommand',
    'fr': 'Sous-commande cible',
  },
  'command_unsaved_title': {
    'en': 'Unsaved changes',
    'fr': 'Modifications non enregistrées',
  },
  'command_unsaved_confirm': {
    'en': 'You have unsaved changes. Discard them?',
    'fr': 'Vous avez des modifications non enregistrées. Les abandonner ?',
  },
  'command_unsaved_keep': {
    'en': 'Keep editing',
    'fr': "Continuer l'édition",
  },
  'command_error_missing_bot_id': {
    'en': 'Missing bot id for local command save.',
    'fr':
        'ID de bot manquant pour la sauvegarde de commande locale.',
  },
  'command_import_tooltip': {
    'en': 'Import command payload',
    'fr': 'Importer un payload de commande',
  },
  'command_export_tooltip': {
    'en': 'Export command payload',
    'fr': 'Exporter le payload de la commande',
  },

  // ── Phase 10: builder.response.dart ────────────────────────────────────
  'actions_missing_field_title': {
    'en': 'Missing Required Field',
    'fr': 'Champ requis manquant',
  },
  'actions_no_matches': {
    'en': 'No actions match your search.',
    'fr': 'Aucune action ne correspond à votre recherche.',
  },
  'actions_add_new_title': {
    'en': 'Add New Action',
    'fr': 'Ajouter une nouvelle action',
  },
  'actions_search_hint': {
    'en': 'Search actions...',
    'fr': 'Rechercher des actions…',
  },
  'actions_add_label': {
    'en': 'Add Action',
    'fr': 'Ajouter une action',
  },
  'actions_builder_title': {
    'en': 'Actions Builder',
    'fr': 'Constructeur d\'actions',
  },
  'actions_save_tooltip': {
    'en': 'Save Actions',
    'fr': 'Enregistrer les actions',
  },
  'actions_key_label': {
    'en': 'Key: {key}',
    'fr': 'Clé : {key}',
  },
  '@actions_key_label': {'en': '', 'fr': ''},

  // ── Phase 11: modal_builder.dart ───────────────────────────────────────
  'modal_remove_field_title': {
    'en': 'Remove modal field',
    'fr': 'Supprimer le champ modal',
  },
  'modal_remove_field_confirm': {
    'en':
        'This field will be removed from the modal. Continue?',
    'fr': 'Ce champ sera supprimé du modal. Continuer ?',
  },
  'modal_title_label': {'en': 'Modal Title', 'fr': 'Titre du modal'},
  'modal_custom_id_label': {'en': 'Custom ID', 'fr': 'ID personnalisé'},
  'modal_custom_id_hint': {
    'en': 'Used to identify this modal',
    'fr': 'Utilisé pour identifier ce modal',
  },
  'modal_workflow_submit': {
    'en': 'Workflow to run on submit (optional)',
    'fr': 'Workflow à exécuter à la soumission (optionnel)',
  },
  'modal_add_text_input': {
    'en': 'Add Text Input',
    'fr': 'Ajouter un champ texte',
  },
  'modal_field_default_label': {
    'en': 'Field {index}',
    'fr': 'Champ {index}',
  },
  '@modal_field_default_label': {'en': '', 'fr': ''},
  'modal_style': {'en': 'Style:', 'fr': 'Style :'},
  'modal_default_value': {
    'en': 'Default value',
    'fr': 'Valeur par défaut',
  },

  // ── Phase 12: basic_info_card.dart ─────────────────────────────────────
  'command_legacy_preset_title': {
    'en': 'Legacy preset',
    'fr': 'Preset legacy',
  },
  'command_legacy_preset_desc': {
    'en':
        'Generate an internal awaited callback trigger and switch this command to the required local legacy setup.',
    'fr':
        "Générer un déclencheur de callback attendu interne et basculer cette commande vers la configuration legacy locale requise.",
  },
  'command_awaited_preset_button': {
    'en': 'Use Awaited Callback Preset',
    'fr': 'Utiliser le preset de callback attendu',
  },
  'command_awaited_preset_active': {
    'en': 'Awaited callback preset',
    'fr': 'Preset de callback attendu',
  },
  'command_edit_raw_name': {
    'en': 'Edit Raw Name',
    'fr': 'Modifier le nom brut',
  },
  'command_awaited_preset_desc': {
    'en':
        'The command name is generated for you and saved as an internal legacy callback.',
    'fr':
        'Le nom de la commande est généré et enregistré comme callback legacy interne.',
  },
  'command_awaited_success': {'en': 'Success', 'fr': 'Succès'},
  'command_awaited_error': {'en': 'Error', 'fr': 'Erreur'},
  'command_awaited_name_label': {
    'en': 'Awaited callback name',
    'fr': 'Nom du callback attendu',
  },
  'command_awaited_name_hint': {
    'en': 'Example: say',
    'fr': 'Exemple : say',
  },
  'command_awaited_filter_label': {
    'en': 'Filter (optional)',
    'fr': 'Filtre (optionnel)',
  },
  'command_awaited_filter_hint': {
    'en': 'Example: <numeric> or <yes/no/cancel>',
    'fr': 'Exemple : <numeric> ou <yes/no/cancel>',
  },
  'command_info_title': {
    'en': 'Command Info',
    'fr': 'Info de la commande',
  },
  'command_info_desc': {
    'en': 'Basic metadata and availability',
    'fr': 'Métadonnées et disponibilité',
  },
  'command_name_label': {'en': 'Name', 'fr': 'Nom'},
  'command_name_generated': {
    'en': 'Generated by the awaited callback preset.',
    'fr': 'Généré par le preset de callback attendu.',
  },
  'command_type_label': {'en': 'Command Type', 'fr': 'Type de commande'},
  'command_type_slash': {'en': 'Slash Command', 'fr': 'Commande Slash'},
  'command_type_legacy': {
    'en': 'Legacy Command',
    'fr': 'Commande Legacy',
  },
  'command_type_user': {'en': 'User Command', 'fr': 'Commande Utilisateur'},
  'command_type_message': {
    'en': 'Message Command',
    'fr': 'Commande Message',
  },
  'command_integration_guild': {
    'en': 'Guild Install',
    'fr': 'Installation serveur',
  },
  'command_integration_user': {
    'en': 'User Install',
    'fr': 'Installation utilisateur',
  },
  'command_context_guild': {'en': 'Guild', 'fr': 'Serveur'},
  'command_context_bot_dm': {'en': 'Bot DM', 'fr': 'MP du bot'},
  'command_context_group_dm': {
    'en': 'Group DM / Other',
    'fr': 'DM de groupe / Autre',
  },
  'command_permissions_title': {
    'en': 'Select permissions',
    'fr': 'Sélectionner les permissions',
  },
  'command_prefix_helper': {
    'en':
        'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))',
    'fr':
        'Supporte les templates et variables scopées (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))',
  },

  // ── Phase 13: actions_card.dart ────────────────────────────────────────
  'actions_title': {'en': 'Actions', 'fr': 'Actions'},
  'actions_description': {
    'en': 'Build runtime actions for this command',
    'fr': 'Construire les actions d\'exécution pour cette commande',
  },
  'actions_active_route': {
    'en': 'Active route: {route}',
    'fr': 'Route active : {route}',
  },
  '@actions_active_route': {'en': '', 'fr': ''},
  'actions_build_button': {
    'en': 'Build Actions ({count})',
    'fr': 'Construire les actions ({count})',
  },
  '@actions_build_button': {'en': '', 'fr': ''},
  'actions_save_workflow_title': {
    'en': 'Save as Workflow',
    'fr': 'Enregistrer comme workflow',
  },
  'actions_workflow_name_label': {
    'en': 'Workflow name',
    'fr': 'Nom du workflow',
  },
  'actions_global_variables': {
    'en': 'Global Variables',
    'fr': 'Variables globales',
  },
  'actions_workflows': {'en': 'Workflows', 'fr': 'Workflows'},

  // ── Phase 14: Remaining files ──────────────────────────────────────────

  // command.create.wizard.dart
  'wizard_quick_start_applied': {
    'en': 'Quick start applied to the command draft.',
    'fr':
        'Démarrage rapide appliqué au brouillon de commande.',
  },
  'wizard_advanced_trigger': {
    'en': 'Advanced trigger settings',
    'fr': 'Paramètres de déclenchement avancés',
  },
  'wizard_edit_reply': {
    'en': 'Edit reply details',
    'fr': 'Modifier les détails de la réponse',
  },
  'wizard_quick_starts': {'en': 'Quick starts', 'fr': 'Démarrages rapides'},
  'wizard_apply_quick_start': {
    'en': 'Apply quick start to draft',
    'fr': 'Appliquer le démarrage rapide au brouillon',
  },
  'wizard_code_advanced': {
    'en': 'Code / Advanced',
    'fr': 'Code / Avancé',
  },

  // command.create.serialization.dart
  'serialization_export_json_title': {
    'en': 'Export command as JSON',
    'fr': 'Exporter la commande en JSON',
  },
  'serialization_export_json_subtitle': {
    'en': 'Copy readable JSON to clipboard',
    'fr': 'Copier le JSON lisible dans le presse-papiers',
  },
  'serialization_export_base64_title': {
    'en': 'Export command as Base64',
    'fr': 'Exporter la commande en Base64',
  },
  'serialization_import_title': {
    'en': 'Import command',
    'fr': 'Importer une commande',
  },
  'serialization_import_desc': {
    'en': 'Paste a command payload (JSON or Base64).',
    'fr': 'Collez un payload de commande (JSON ou Base64).',
  },
  'serialization_invalid_format': {
    'en': 'Invalid command payload format.',
    'fr': 'Format de payload de commande invalide.',
  },
  'serialization_invalid_structure': {
    'en': 'Invalid command payload structure.',
    'fr': 'Structure de payload de commande invalide.',
  },
  'serialization_imported': {
    'en': 'Command imported into editor.',
    'fr': 'Commande importée dans l\'éditeur.',
  },

  // command.response_workflow.dart
  'response_workflow_title': {
    'en': 'Response Workflow',
    'fr': 'Workflow de réponse',
  },
  'response_workflow_auto_defer': {
    'en': 'Auto defer if actions exist',
    'fr': 'Auto-defer si des actions existent',
  },
  'response_workflow_public': {'en': 'Public', 'fr': 'Public'},
  'response_workflow_error_policy': {
    'en': 'Error policy',
    'fr': "Politique d'erreur",
  },
  'response_workflow_enable_condition': {
    'en': 'Enable condition',
    'fr': 'Activer la condition',
  },
  'response_workflow_mode_normal': {'en': 'Normal', 'fr': 'Normal'},
  'response_workflow_mode_component': {
    'en': 'Component',
    'fr': 'Composant',
  },
  'response_workflow_mode_modal': {'en': 'Modal', 'fr': 'Modal'},
  'response_workflow_revert_tooltip': {
    'en': 'Revert all changes',
    'fr': 'Annuler toutes les modifications',
  },
  'response_workflow_then_text': {
    'en': 'THEN response text (optional)',
    'fr': 'Texte de réponse THEN (optionnel)',
  },
  'response_workflow_else_text': {
    'en': 'ELSE response text (optional)',
    'fr': 'Texte de réponse ELSE (optionnel)',
  },

  // app.dart
  'recovery_label': {'en': 'Recovery', 'fr': 'Récupération'},
  'recovery_title': {'en': 'Recovery mode', 'fr': 'Mode récupération'},
  'recovery_retry_discord': {
    'en': 'Retry Discord connection',
    'fr': 'Retenter la connexion Discord',
  },
  'recovery_delete_bot': {
    'en': 'Delete bot locally',
    'fr': 'Supprimer le bot localement',
  },
  'nav_webhooks': {'en': 'Webhooks', 'fr': 'Webhooks'},
  'nav_webhooks_compact': {'en': 'Hooks', 'fr': 'Hooks'},

  // reply_card.dart
  'reply_configure_workflow': {
    'en': 'Configure Response Workflow',
    'fr': 'Configurer le workflow de réponse',
  },
  'reply_buttons_optional': {
    'en': 'Buttons & Select Menus (optional)',
    'fr': 'Boutons et menus de sélection (optionnel)',
  },
  'reply_mode_standard': {
    'en': 'Standard Message',
    'fr': 'Message standard',
  },
  'reply_mode_layout': {'en': 'Layout Mode', 'fr': 'Mode mise en page'},
  'reply_mode_modal': {'en': 'Modal Form', 'fr': 'Formulaire modal'},

  // emojis.page.dart
  'emojis_rename_tooltip': {'en': 'Rename', 'fr': 'Renommer'},
  'emojis_delete_tooltip': {'en': 'Delete', 'fr': 'Supprimer'},

  // normal_component_editor.dart
  'component_remove_row_title': {
    'en': 'Remove action row',
    'fr': "Supprimer la ligne d'action",
  },
  'component_add_tooltip': {
    'en': 'Add Component',
    'fr': 'Ajouter un composant',
  },

  // component_v2_editor.dart
  'component_add_root': {
    'en': 'Add Root Component',
    'fr': 'Ajouter un composant racine',
  },

  // command.create.edit_shell.dart
  'edit_shell_save_changes': {
    'en': 'Save changes',
    'fr': 'Enregistrer les modifications',
  },
  'edit_shell_local_only': {
    'en': 'Local-only',
    'fr': 'Local uniquement',
  },
  'edit_shell_local_draft': {
    'en': 'Local draft',
    'fr': 'Brouillon local',
  },
  'edit_shell_unsaved': {
    'en': 'Unsaved changes',
    'fr': 'Modifications non enregistrées',
  },

  // command.reply_editor.dart
  'reply_editor_title': {
    'en': 'Reply Details',
    'fr': 'Détails de la réponse',
  },

  // bdfd_editor_page.dart
  'bdfd_editor_ux_title': {'en': 'Editor UX', 'fr': 'UX de l\'éditeur'},
  'bdfd_editor_includes': {'en': 'Includes:', 'fr': 'Inclut :'},
  'bdfd_editor_auto_indent': {
    'en': '• Smart auto indentation on Enter',
    'fr': '• Indentation automatique intelligente sur Entrée',
  },
  'bdfd_editor_indent_guides': {
    'en': '• Live indentation guides',
    'fr': "• Guides d'indentation en temps réel",
  },
  'bdfd_editor_quick_keys': {
    'en': '• Mobile quick-keys for BDFD symbols',
    'fr': '• Touches rapides mobiles pour les symboles BDFD',
  },
  'bdfd_editor_toggle_indent': {
    'en': 'Toggle indentation guides',
    'fr': "Activer/désactiver les guides d'indentation",
  },

  // main.dart
  'startup_error_title': {
    'en': 'Startup Error',
    'fr': 'Erreur de démarrage',
  },
  'startup_failed_message': {
    'en': 'Bot Creator failed to start on this device.',
    'fr': "Bot Creator n'a pas pu démarrer sur cet appareil.",
  },
  'startup_copy_diagnostics': {
    'en': 'Copy diagnostics',
    'fr': 'Copier les diagnostics',
  },
  'startup_refresh_diagnostics': {
    'en': 'Refresh diagnostics',
    'fr': 'Actualiser les diagnostics',
  },
  'startup_diagnostics_copied': {
    'en': 'Diagnostics copied to clipboard',
    'fr': 'Diagnostics copiés dans le presse-papiers',
  },

  // export_import.page.dart
  'export_failed': {
    'en': 'Export failed: {error}',
    'fr': "Échec de l'export : {error}",
  },
  '@export_failed': {'en': '', 'fr': ''},
  'import_parse_failed': {
    'en': 'Failed to parse ZIP: {error}',
    'fr': "Échec de l'analyse du ZIP : {error}",
  },
  '@import_parse_failed': {'en': '', 'fr': ''},
  'import_nothing': {
    'en': 'Nothing imported.',
    'fr': 'Rien n\'a été importé.',
  },
  'import_failed': {
    'en': 'Import failed: {error}',
    'fr': "Échec de l'import : {error}",
  },
  '@import_failed': {'en': '', 'fr': ''},

  // workflows.page.dart (UI strings only, not event names)
  'workflows_no_match': {
    'en': 'No workflows match the current filters.',
    'fr': 'Aucun workflow ne correspond aux filtres actuels.',
  },

  // settings.dart (new strings)
  'settings_run_diagnostics': {
    'en': 'Run Diagnostics',
    'fr': 'Lancer les diagnostics',
  },
  'settings_open_ad_inspector': {
    'en': 'Open Ad Inspector',
    'fr': "Ouvrir l'inspecteur de publicités",
  },
  'settings_builtin_help': {
    'en': 'Built-in legacy !help command',
    'fr': 'Commande !help legacy intégrée',
  },

  // drive.dart
  'drive_manual_backup': {
    'en': 'Manual backup',
    'fr': 'Sauvegarde manuelle',
  },
  'drive_legacy_snapshot': {
    'en': 'Legacy snapshot',
    'fr': 'Snapshot legacy',
  },
};

// ── ARB metadata for parameterized keys ─────────────────────────────────

final Map<String, Map<String, dynamic>> _placeholders = {
  'embed_response_header': {
    'placeholders': {
      'count': {'type': 'int'},
      'max': {'type': 'int'},
    },
  },
  'embed_empty_message': {
    'placeholders': {
      'max': {'type': 'int'},
    },
  },
  'embed_number': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'embed_fields_header': {
    'placeholders': {
      'count': {'type': 'int'},
    },
  },
  'embed_field_number': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'option_static_label_n': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'option_static_value_n': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'option_default_name': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'option_choice_number': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'action_http_status': {
    'placeholders': {
      'status': {'type': 'String'},
    },
  },
  'action_http_paths_parsed': {
    'placeholders': {
      'count': {'type': 'int'},
    },
  },
  'action_else_if_label': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'action_edit_param': {
    'placeholders': {
      'name': {'type': 'String'},
    },
  },
  'action_choose_param': {
    'placeholders': {
      'name': {'type': 'String'},
    },
  },
  'validation_awaited_callback_length': {
    'placeholders': {
      'max': {'type': 'int'},
    },
  },
  'validation_command_name_length': {
    'placeholders': {
      'max': {'type': 'int'},
    },
  },
  'scheduler_limit_reached': {
    'placeholders': {
      'limit': {'type': 'int'},
    },
  },
  'scheduler_save_failed': {
    'placeholders': {
      'error': {'type': 'String'},
    },
  },
  'scheduler_delete_confirm': {
    'placeholders': {
      'label': {'type': 'String'},
    },
  },
  'scheduler_triggers_count': {
    'placeholders': {
      'count': {'type': 'int'},
      'limit': {'type': 'String'},
    },
  },
  'webhooks_limit_reached': {
    'placeholders': {
      'limit': {'type': 'int'},
    },
  },
  'webhooks_save_failed': {
    'placeholders': {
      'error': {'type': 'String'},
    },
  },
  'webhooks_delete_confirm': {
    'placeholders': {
      'label': {'type': 'String'},
    },
  },
  'webhooks_workflow_subtitle': {
    'placeholders': {
      'workflow': {'type': 'String'},
    },
  },
  'actions_active_route': {
    'placeholders': {
      'route': {'type': 'String'},
    },
  },
  'actions_build_button': {
    'placeholders': {
      'count': {'type': 'int'},
    },
  },
  'actions_key_label': {
    'placeholders': {
      'key': {'type': 'String'},
    },
  },
  'modal_field_default_label': {
    'placeholders': {
      'index': {'type': 'int'},
    },
  },
  'export_failed': {
    'placeholders': {
      'error': {'type': 'String'},
    },
  },
  'import_parse_failed': {
    'placeholders': {
      'error': {'type': 'String'},
    },
  },
  'import_failed': {
    'placeholders': {
      'error': {'type': 'String'},
    },
  },
};

// ── Source file replacements ────────────────────────────────────────────

/// Each entry: filePath → list of (old, new) pairs.
/// Applied with simple string replacement.
/// Order matters — first match wins, so put specific patterns first.
class _R {
  final String old;
  final String replacement;
  const _R(this.old, this.replacement);
}

String _lib(String rel) =>
    '/Users/jeremy/Code/bot-creator/packages/app/lib/$rel';

final Map<String, List<_R>> _replacements = {
  // Will be populated by the buildReplacements() call
};

void _buildReplacements() {
  // ── response_embeds_editor.dart ────────────────────────────────────────
  _replacements[_lib('widgets/response_embeds_editor.dart')] = [
    // Add import
    _R(
      "import 'package:bot_creator/widgets/variable_text_field.dart';",
      "import 'package:bot_creator/widgets/variable_text_field.dart';\nimport 'package:bot_creator/utils/i18n.dart';",
    ),
    // Dialog title
    _R(
      "title: const Text('Pick embed color')",
      "title: Text(context.tr.embed_color_picker_title)",
    ),
    // Cancel button (multiple occurrences - handled by replaceAll)
    // Apply button
    _R(
      "child: const Text('Apply')",
      "child: Text(context.tr.common_apply)",
    ),
    // Delete embed dialog
    _R(
      "title: const Text('Delete embed')",
      "title: Text(context.tr.embed_delete_title)",
    ),
    _R(
      "content: const Text('This embed will be removed. Continue?')",
      "content: Text(context.tr.embed_delete_confirm)",
    ),
    // Delete field dialog
    _R(
      "title: const Text('Delete field')",
      "title: Text(context.tr.embed_field_delete_title)",
    ),
    _R(
      "const Text(\n                  'This field will be removed from the embed. Continue?',\n                )",
      "Text(\n                  context.tr.embed_field_delete_confirm,\n                )",
    ),
    // Cancel (replaceAll handles all 3 occurrences)
    _R(
      "child: const Text('Cancel')",
      "child: Text(context.tr.common_cancel)",
    ),
    // Delete buttons (styled ones)
    _R(
      "child: Text(\n                      'Delete',",
      "child: Text(\n                      context.tr.common_delete,",
    ),
    // Header
    _R(
      "'Response Embeds (\${_embeds.length}/\${widget.maxEmbeds})'",
      "context.tr.embed_response_header(_embeds.length, widget.maxEmbeds)",
    ),
    // Tooltip
    _R(
      "tooltip: 'Add embed'",
      "tooltip: context.tr.embed_add_tooltip",
    ),
    // Empty message
    _R(
      "'No embeds. You can add up to \${widget.maxEmbeds} embeds.'",
      "context.tr.embed_empty_message(widget.maxEmbeds)",
    ),
    // Embed #N
    _R(
      "'Embed #\${index + 1}'",
      "context.tr.embed_number(index + 1)",
    ),
    // Labels
    _R(
      "label: 'Title'",
      "label: context.tr.embed_label_title",
    ),
    _R(
      "label: 'Description'",
      "label: context.tr.common_description",
    ),
    _R(
      "label: 'URL'",
      "label: context.tr.embed_label_url",
    ),
    _R(
      "label: 'Timestamp (ISO8601)'",
      "label: context.tr.embed_label_timestamp",
    ),
    _R(
      "label: 'Color (int or #hex)'",
      "label: context.tr.embed_label_color",
    ),
    _R(
      "label: const Text('Pick')",
      "label: Text(context.tr.common_pick)",
    ),
    _R(
      "title: const Text('Footer')",
      "title: Text(context.tr.embed_section_footer)",
    ),
    _R(
      "label: 'Footer Text'",
      "label: context.tr.embed_label_footer_text",
    ),
    _R(
      "label: 'Footer Icon URL'",
      "label: context.tr.embed_label_footer_icon",
    ),
    _R(
      "title: const Text('Author')",
      "title: Text(context.tr.embed_section_author)",
    ),
    _R(
      "label: 'Author Name'",
      "label: context.tr.embed_label_author_name",
    ),
    _R(
      "label: 'Author URL'",
      "label: context.tr.embed_label_author_url",
    ),
    _R(
      "label: 'Author Icon URL'",
      "label: context.tr.embed_label_author_icon",
    ),
    _R(
      "title: const Text('Media')",
      "title: Text(context.tr.embed_section_media)",
    ),
    _R(
      "label: 'Image URL'",
      "label: context.tr.embed_label_image_url",
    ),
    _R(
      "label: 'Thumbnail URL'",
      "label: context.tr.embed_label_thumbnail_url",
    ),
    _R(
      "title: Text('Fields (\${fields.length}/25)')",
      "title: Text(context.tr.embed_fields_header(fields.length))",
    ),
    _R(
      "child: Text('No fields yet.')",
      "child: Text(context.tr.embed_fields_empty)",
    ),
    _R(
      "'Field #\${fieldIndex + 1}'",
      "context.tr.embed_field_number(fieldIndex + 1)",
    ),
    _R(
      "label: 'Name'",
      "label: context.tr.common_name",
    ),
    _R(
      "label: 'Value'",
      "label: context.tr.common_value",
    ),
    _R(
      "title: const Text('Inline')",
      "title: Text(context.tr.embed_label_inline)",
    ),
    _R(
      "label: 'Dynamic Fields Template'",
      "label: context.tr.embed_label_dynamic_fields",
    ),
  ];
}

// ── Main ─────────────────────────────────────────────────────────────────

void main() {
  final appDir = '/Users/jeremy/Code/bot-creator/packages/app';

  // ── Step 1: Update ARB files ───────────────────────────────────────────
  print('=== Step 1: Adding keys to ARB files ===');

  for (final locale in ['en', 'fr']) {
    final arbFile = File('$appDir/lib/l10n/app_$locale.arb');
    final arbContent = arbFile.readAsStringSync();
    final arbMap =
        Map<String, dynamic>.from(jsonDecode(arbContent) as Map);

    var added = 0;
    for (final entry in _keys.entries) {
      final key = entry.key;
      // Skip @-prefixed metadata marker entries
      if (key.startsWith('@')) continue;
      // Skip if key already exists
      if (arbMap.containsKey(key)) continue;

      final value = entry.value[locale];
      if (value == null) continue;

      arbMap[key] = value;
      added++;

      // Add placeholder metadata if defined
      if (_placeholders.containsKey(key)) {
        arbMap['@$key'] = _placeholders[key];
      }
    }

    // Write back with proper formatting
    final encoder = JsonEncoder.withIndent('  ');
    arbFile.writeAsStringSync('${encoder.convert(arbMap)}\n');
    print('  $locale: added $added keys (total: ${arbMap.length})');
  }

  // ── Step 2: Apply source file replacements ─────────────────────────────
  print('\n=== Step 2: Applying source file replacements ===');
  _buildReplacements();

  for (final entry in _replacements.entries) {
    final filePath = entry.key;
    final replacements = entry.value;
    final file = File(filePath);
    if (!file.existsSync()) {
      print('  SKIP (not found): $filePath');
      continue;
    }

    var content = file.readAsStringSync();
    var totalReplacements = 0;

    for (final r in replacements) {
      final count = r.old.allMatches(content).length;
      if (count > 0) {
        content = content.replaceAll(r.old, r.replacement);
        totalReplacements += count;
      }
    }

    file.writeAsStringSync(content);
    print(
      '  ${filePath.split('/').last}: $totalReplacements replacements',
    );
  }

  print('\n=== Done! Run flutter gen-l10n to regenerate. ===');
}
