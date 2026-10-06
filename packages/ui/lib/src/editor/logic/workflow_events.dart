/// Libellé d'une catégorie d'événements Discord (celles de `EventCatalog`).
String workflowEventCategoryLabel(String category) {
  switch (category) {
    case 'core':
      return 'Core';
    case 'commands':
      return 'Commands';
    case 'automod':
      return 'Auto Moderation';
    case 'channels':
      return 'Channels';
    case 'threads':
      return 'Threads';
    case 'entitlements':
      return 'Entitlements';
    case 'guilds':
      return 'Guilds';
    case 'members':
      return 'Members';
    case 'roles':
      return 'Roles';
    case 'scheduled':
      return 'Scheduled Events';
    case 'integrations':
      return 'Integrations';
    case 'invites':
      return 'Invites';
    case 'messages':
      return 'Messages';
    case 'reactions':
      return 'Reactions';
    case 'presence':
      return 'Presence';
    case 'stages':
      return 'Stage Instances';
    case 'voice':
      return 'Voice';
    case 'webhooks':
      return 'Webhooks';
    case 'soundboard':
      return 'Soundboard';
    default:
      return category;
  }
}
