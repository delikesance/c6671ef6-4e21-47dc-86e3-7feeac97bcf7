// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class StudioLocalizationsPt extends StudioLocalizations {
  StudioLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get navHome => 'Início';

  @override
  String get navDocs => 'Documentacao';

  @override
  String get navSettings => 'Definições';

  @override
  String get navBack => 'Voltar';

  @override
  String get navCommands => 'Comandos';

  @override
  String get navCommandsShort => 'Cmd';

  @override
  String get navCopilot => 'Copiloto IA';

  @override
  String get navFlows => 'Fluxo';

  @override
  String get navVars => 'Vars';

  @override
  String get navSched => 'Agend';

  @override
  String get navHooks => 'Webhooks de entrada';

  @override
  String get navEmojis => 'Emoji';

  @override
  String get navTeam => 'Team';

  @override
  String get navGuilds => 'Servidores';

  @override
  String get navDashboard => 'Painel';

  @override
  String get navModules => 'Modules';

  @override
  String get navBeginner => 'Modo iniciante';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesSearch => 'Buscar';

  @override
  String get modulesGroupCreate => 'Criação';

  @override
  String get modulesGroupAutomation => 'Automação';

  @override
  String get modulesGroupManagement => 'Gestão';

  @override
  String get modulesGroupTools => 'Tools';

  @override
  String get modulesWorkflows => 'Fluxos de Trabalho';

  @override
  String get modulesVariables => 'Variáveis Globais';

  @override
  String get modulesEmojis => 'Emojis';

  @override
  String get modulesScheduler => 'Agendador';

  @override
  String get modulesDescWorkflows => 'Automatize suas ações e eventos';

  @override
  String get modulesDescVariables => 'Compartilhadas entre todos os comandos';

  @override
  String get modulesDescEmojis => 'Emojis de aplicativo do bot';

  @override
  String get modulesDescScheduler => 'Executa um workflow a cada X min';

  @override
  String get modulesDescHooks => 'Chamadas HTTP roteadas para um workflow';

  @override
  String get modulesDescTeam => 'Colaboradores e chat da equipe';

  @override
  String get modulesDescGuilds => 'Servidores onde o bot está presente';

  @override
  String get modulesDescDashboard => 'Command usage over 24 h, 7 d, 30 d';

  @override
  String get modulesDescCopilot => 'Assistant to build your commands';

  @override
  String get beginnerOnHint => 'Mostrando apenas abas essenciais';

  @override
  String get beginnerOffHint => 'Mostrando todos os recursos';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonSend => 'Send';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusStopped => 'Parado';

  @override
  String get loadError => 'Erro ao carregar';

  @override
  String get comingSoonBody =>
      'This section is coming soon to Studio. It is still available in the Bot Creator app.';

  @override
  String get comingSoonShort => 'Coming soon to Studio.';

  @override
  String get appTitle => 'Bot Creator Studio';

  @override
  String get loginSubtitle =>
      'Sign in with Discord to access your bots. Studio always requires a valid sign-in.';

  @override
  String get loginDiscord => 'Conectar com Discord';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSignedIn => 'Signed in with Discord';

  @override
  String accountSignedInAs(String name) {
    return 'Signed in with Discord: $name';
  }

  @override
  String get accountPlanPremium => 'Premium plan';

  @override
  String get accountPlanFree =>
      'Free plan: manage your subscription from the mobile app.';

  @override
  String get accountSignOut => 'Sair';

  @override
  String get settingsTitle => 'Definições';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get botsOverline => 'My projects';

  @override
  String get botsTitle => 'Meus bots';

  @override
  String get botsCreate => 'Criar um bot';

  @override
  String get botsManage => 'Gerir';

  @override
  String get botStop => 'Parar';

  @override
  String get botStart => 'Iniciar Bot';

  @override
  String get botsEmptyTitle => 'Nenhuma aplicação encontrada';

  @override
  String get botsEmptyHint =>
      'Create your first bot from the Bot Creator app: it will show up here.';

  @override
  String get hostingIncludedTitle => 'Alojamento incluído';

  @override
  String get hostingIncludedValue => 'Ilimitado com a tua subscrição';

  @override
  String get hostingRemainingTitle => 'Tempo restante';

  @override
  String get hostingExpired => 'Hospedagem expirada';

  @override
  String get hostingSessionActive => 'Sessão ativa';

  @override
  String get hostingSessionActiveOnline => 'Sessão ativa (online)';

  @override
  String get hostingPreservedTitle => 'Tempo preservado';

  @override
  String hostingReserve(String time) {
    return 'Reserve: $time';
  }

  @override
  String get hostingReserveAvailable => 'Tempo reservado (em pausa)';

  @override
  String get hostingPreservedDetail =>
      'O tempo é preservado enquanto o bot estiver parado.';

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createBotToken => 'Discord bot token';

  @override
  String get createBotTokenHint =>
      'It is sent over HTTPS to the Bot Creator server and never kept in the browser.';

  @override
  String createBotValidNamed(String name) {
    return 'Valid token: $name';
  }

  @override
  String createBotValidId(String id) {
    return 'Valid token (ID $id)';
  }

  @override
  String get createBotSamplePing => 'Adicionar comando /ping de exemplo';

  @override
  String get createBotBusy =>
      'Creating the bot: this can take up to two minutes. Do not close this page.';

  @override
  String get createBotVerify => 'Check token';

  @override
  String get createBotSubmit => 'Create bot';

  @override
  String get createBotSyncBusy =>
      'This bot is already being synchronized. Please wait a few minutes.';

  @override
  String get createBotNoId => 'Could not read the bot ID from this token.';

  @override
  String get overviewLogs => 'Logs';

  @override
  String overviewLogsUnavailable(String error) {
    return 'Logs unavailable: $error';
  }

  @override
  String get overviewNoLogs => 'No logs yet.';

  @override
  String get commandsSearch => 'Pesquisar comandos...';

  @override
  String get commandsEmpty =>
      'No commands yet. Create one from the Bot Creator app.';

  @override
  String get commandsNoMatch =>
      'Nenhum comando corresponde aos filtros atuais.';

  @override
  String get teamSubtitle => 'Collaborators and team chat.';

  @override
  String get teamChatTitle => 'Team chat';

  @override
  String get teamNoChatAccess =>
      'The owner has not given you access to the chat.';

  @override
  String get teamNoMessages => 'No messages.';

  @override
  String get teamWriteHint => 'Write a message…';

  @override
  String get teamOwner => 'Proprietário';

  @override
  String get teamNoPermissions => 'No specific permissions';

  @override
  String get teamRemove => 'Remove from team';

  @override
  String get teamPermEditCommands => 'Edit commands';

  @override
  String get teamPermStartStop => 'Start / stop';

  @override
  String get teamPermClaimAds => 'Earn time (ads)';

  @override
  String get teamPermInvite => 'Invite';

  @override
  String get premiumHint =>
      'Your account is on the free plan: subscriptions are activated from the mobile app (Studio shows no ads or purchases).';

  @override
  String get featureSchedulerTitle => 'Gatilhos de agendamento';

  @override
  String get featureSchedulerDesc =>
      'Execute fluxos de trabalho automaticamente a cada X minutos (até 10 ativos).';

  @override
  String get featureAnalyticsTitle => 'Análises Premium';

  @override
  String get featureAnalyticsDesc =>
      'Desbloqueie taxa de erro, percentis de latência e insights de idioma.';

  @override
  String get featureHooksTitle => 'Webhooks de entrada';

  @override
  String get featureHooksDesc =>
      'Crie endpoints de webhook seguros e direcione chamadas para fluxos de trabalho.';

  @override
  String get commonSaved => 'Salvo';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get deleteIrreversible => 'Esta ação é definitiva.';

  @override
  String deleteNamedTitle(String name) {
    return 'Excluir “$name”?';
  }

  @override
  String get commandNew => 'Novo comando';

  @override
  String get commandSaved => 'Comando salvo.';

  @override
  String get commandChangedElsewhere =>
      'Este bot foi modificado em outro lugar (app ou outra sessão). Recarregue o comando antes de salvar.';

  @override
  String get scriptEdit => 'Editar script';

  @override
  String get commandTriggerHybrid => 'Slash + mensagem de texto';

  @override
  String get workflowNew => 'Novo fluxo de trabalho';

  @override
  String get workflowsEmpty =>
      'Nenhum fluxo de trabalho. Crie um para reutilizar uma sequência de ações ou reagir a um evento.';

  @override
  String get workflowSaved => 'Fluxo de trabalho salvo.';

  @override
  String get workflowDeleteBody =>
      'Os comandos que chamam este fluxo de trabalho não terão mais nada para executar.';

  @override
  String get workflowTypeGeneral => 'Geral (chamado por um comando)';

  @override
  String get workflowCategory => 'Categoria';

  @override
  String workflowScriptNotice(String mode) {
    return 'Este fluxo de trabalho está escrito em $mode: o Studio só edita fluxos visuais. Ele permanece salvo como está.';
  }

  @override
  String get variablesGlobalSubtitle => 'Dados memorizados para todo o bot.';

  @override
  String get variablesScopedHint =>
      'Uma definição fornece o valor padrão; cada servidor, canal ou membro mantém depois o seu próprio valor.';

  @override
  String get variableScopedRemoveNote =>
      'A definição é removida; os valores já memorizados não são apagados.';

  @override
  String get copilotNoCredits =>
      'Créditos de IA insuficientes. Recarregue-os pelo app móvel.';

  @override
  String get copilotChatTooLong =>
      'Esta conversa é muito longa: inicie uma nova.';

  @override
  String get copilotUnavailable => 'O Copiloto está indisponível no momento.';

  @override
  String get copilotGenerationFailed => 'A geração falhou.';

  @override
  String get copilotDeleteChat => 'Excluir conversa';

  @override
  String copilotWants(String tool) {
    return 'O Copiloto quer: $tool';
  }

  @override
  String get dashboardRuns => 'Execuções';

  @override
  String get dashboardSinceStart => 'Desde o início';

  @override
  String get dashboardLatencyP50P95 => 'Latência P50 / P95';

  @override
  String get dashboardActivity => 'Atividade';

  @override
  String get dashboardLanguages => 'Idiomas';

  @override
  String get dashboardNoRuns => 'Nenhuma execução neste período.';

  @override
  String get dashboardNoActivity => 'Nenhuma atividade neste período.';

  @override
  String get dashboardOneExecution => '1 execução';

  @override
  String dashboardAgoDays(int days) {
    return 'há $days d';
  }

  @override
  String dashboardAgoHours(int hours) {
    return 'há $hours h';
  }

  @override
  String dashboardErrorRateOf(String rate) {
    return '$rate % de erros';
  }

  @override
  String dashboardLatencyPercentiles(int p50, int p95) {
    return 'P50 $p50 ms · P95 $p95 ms';
  }

  @override
  String get dashboardLatencyNone => 'latência —';

  @override
  String get botStopFailed => 'Não foi possível parar o bot';

  @override
  String get botStartFailed => 'Não foi possível iniciar o bot';

  @override
  String get refusalNoFreeTimeTitle => 'Tempo de hospedagem esgotado';

  @override
  String get refusalNoFreeTimeBody =>
      'Este bot não tem mais tempo de hospedagem gratuito. Assista a um anúncio no app móvel para ganhar mais ou assine o Premium. O Studio não oferece anúncios nem compras.';

  @override
  String get authSessionExpired => 'Sessão expirada. Faça login novamente.';

  @override
  String authDiscordRefused(String reason) {
    return 'Login com o Discord recusado ($reason).';
  }

  @override
  String get authInvalidResponse =>
      'Resposta de login inválida. Tente novamente.';

  @override
  String get validationCommandNameFormat =>
      'Nome inválido: apenas minúsculas, números, “-” e “_”, sem espaços.';

  @override
  String validationDescriptionTooLong(int max) {
    return 'A descrição deve ter no máximo $max caracteres.';
  }

  @override
  String get validationWorkflowNameRequired =>
      'O nome do fluxo de trabalho é obrigatório.';

  @override
  String validationWorkflowNameTooLong(int max) {
    return 'O nome deve ter no máximo $max caracteres.';
  }

  @override
  String validationWorkflowTooManyBlocks(int max) {
    return 'No máximo $max blocos por fluxo de trabalho.';
  }

  @override
  String validationOptionNameInvalid(String name) {
    return 'Opção “$name”: minúsculas, números, “-” e “_”, no máximo 32 caracteres.';
  }

  @override
  String validationOptionDescription(String name) {
    return 'Opção “$name”: descrição obrigatória (no máximo 100 caracteres).';
  }

  @override
  String validationOptionRequiredOrder(String name) {
    return 'As opções obrigatórias devem vir antes das facultativas (“$name”).';
  }

  @override
  String get schedulerPremiumOnly =>
      'O agendador é reservado a contas Premium. A assinatura é gerenciada no app.';

  @override
  String get webhooksPremiumOnly =>
      'Os webhooks de entrada são reservados a contas Premium. A assinatura é gerenciada no app.';
}
