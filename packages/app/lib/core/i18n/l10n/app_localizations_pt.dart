// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get action_add_else_if => 'Adicionar ELSE IF';

  @override
  String get action_add_header => 'Adicionar cabeÃƒÂ§alho';

  @override
  String get action_add_new_item => 'Adicionar novo item';

  @override
  String get action_advanced_settings => 'ConfiguraÃƒÂ§ÃƒÂµes avanÃƒÂ§adas';

  @override
  String action_and_more(int count) {
    return 'Ã¢â‚¬Â¦ e mais $count';
  }

  @override
  String get action_bulk_import_hint =>
      'ImportaÃƒÂ§ÃƒÂ£o em massa (Cole cabeÃƒÂ§alhos como Chave: Valor)';

  @override
  String get action_cannot_format_json =>
      'NÃƒÂ£o ÃƒÂ© possÃƒÂ­vel formatar: JSON InvÃƒÂ¡lido';

  @override
  String get action_category_channels => 'Canais';

  @override
  String get action_category_components => 'Componentes';

  @override
  String get action_category_guild_members => 'Servidor & Membros';

  @override
  String get action_category_http_variables => 'HTTP & VariÃƒÂ¡veis';

  @override
  String get action_category_interactions => 'InteraÃƒÂ§ÃƒÂµes';

  @override
  String get action_category_logic_flow => 'LÃƒÂ³gica & Fluxo';

  @override
  String get action_category_messages => 'Mensagens';

  @override
  String get action_category_moderation => 'ModeraÃƒÂ§ÃƒÂ£o';

  @override
  String get action_category_music => 'MÃƒÂºsica';

  @override
  String get action_category_reactions => 'ReaÃƒÂ§ÃƒÂµes';

  @override
  String get action_category_webhooks => 'Webhooks';

  @override
  String get action_category_workflows => 'Fluxos de Trabalho';

  @override
  String action_choose_param(String name) {
    return 'Escolher $name';
  }

  @override
  String get action_clear_all => 'Limpar tudo';

  @override
  String get action_condition_value => 'Valor da CondiÃƒÂ§ÃƒÂ£o';

  @override
  String get action_condition_variable => 'VariÃƒÂ¡vel de CondiÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_addReaction =>
      'Adiciona uma reaÃƒÂ§ÃƒÂ£o de emoji a uma mensagem';

  @override
  String get action_description_addRole => 'Atribui um cargo a um membro';

  @override
  String get action_description_addThreadMember =>
      'Adicionar um membro a um tÃƒÂ³pico';

  @override
  String get action_description_appendArrayElement =>
      'Adicionar um novo elemento em uma matriz JSON global ou de escopo';

  @override
  String get action_description_attachImage =>
      'Anexar um arquivo de imagem ÃƒÂ  resposta da mensagem (URL, URL de dados ou base64)';

  @override
  String get action_description_banUser =>
      'Bane permanentemente um usuÃƒÂ¡rio do servidor';

  @override
  String get action_description_calculate =>
      'Realizar operaÃƒÂ§ÃƒÂµes matemÃƒÂ¡ticas e armazenar o resultado';

  @override
  String get action_description_canvasCreateBlock =>
      'Criar uma tela de imagem em branco';

  @override
  String get action_description_canvasDrawCircleBlock =>
      'Desenhar um cÃƒÂ­rculo na tela de imagem';

  @override
  String get action_description_canvasDrawLineBlock =>
      'Desenhar uma linha na tela';

  @override
  String get action_description_canvasDrawRectBlock =>
      'Desenhar um retÃƒÂ¢ngulo na tela de imagem';

  @override
  String get action_description_canvasDrawTextBlock =>
      'Desenhar texto na tela de imagem com opÃƒÂ§ÃƒÂµes de estilo';

  @override
  String get action_description_canvasLoadImageBlock =>
      'Carregar uma imagem de uma URL ou origem na tela';

  @override
  String get action_description_clearAllReactions =>
      'Remove todas as reaÃƒÂ§ÃƒÂµes de uma mensagem';

  @override
  String get action_description_cooldown =>
      'Aplica um tempo de espera para o usuÃƒÂ¡rio ou servidor';

  @override
  String get action_description_createAutoModRule =>
      'Criar uma regra de moderaÃƒÂ§ÃƒÂ£o automÃƒÂ¡tica no servidor';

  @override
  String get action_description_createChannel => 'Criar um novo canal';

  @override
  String get action_description_createEmoji =>
      'Criar um emoji de servidor a partir de dados de imagem';

  @override
  String get action_description_createInvite =>
      'Criar um novo link de convite para um canal';

  @override
  String get action_description_createPoll =>
      'Criar uma mensagem de enquete em um canal';

  @override
  String get action_description_createThread =>
      'Criar um tÃƒÂ³pico em um canal de texto suportado';

  @override
  String get action_description_debugProfile =>
      'Gerar perfil de execuÃƒÂ§ÃƒÂ£o e informaÃƒÂ§ÃƒÂµes de diagnÃƒÂ³stico';

  @override
  String get action_description_deferInteraction =>
      'Adiar a resposta da interaÃƒÂ§ÃƒÂ£o para evitar expiraÃƒÂ§ÃƒÂ£o do Discord';

  @override
  String get action_description_deleteAutoModRule =>
      'Excluir uma regra de moderaÃƒÂ§ÃƒÂ£o automÃƒÂ¡tica';

  @override
  String get action_description_deleteChannelPermission =>
      'Excluir uma sobreposiÃƒÂ§ÃƒÂ£o de permissÃƒÂ£o de canal';

  @override
  String get action_description_deleteEmoji => 'Excluir um emoji de servidor';

  @override
  String get action_description_deleteInvite =>
      'Excluir um convite existente por cÃƒÂ³digo';

  @override
  String get action_description_deleteMessages => 'Apaga uma ou mais mensagens';

  @override
  String get action_description_deleteTrigger =>
      'Apaga a mensagem que acionou este comando';

  @override
  String get action_description_deleteWebhook => 'Excluir um Webhook';

  @override
  String get action_description_disconnectFromVoice =>
      'Desconectar um membro da voz';

  @override
  String get action_description_editChannelPermissions =>
      'Criar ou atualizar sobreposiÃƒÂ§ÃƒÂµes de permissÃƒÂ£o de canal';

  @override
  String get action_description_editComponentV2 =>
      'Editar componentes existentes';

  @override
  String get action_description_editInteractionMessage =>
      'Editar a resposta da interaÃƒÂ§ÃƒÂ£o adiada ou original';

  @override
  String get action_description_editMessage => 'Edita uma mensagem existente';

  @override
  String get action_description_editWebhook => 'Editar um Webhook existente';

  @override
  String get action_description_endPoll =>
      'Encerrar uma enquete ativa imediatamente';

  @override
  String get action_description_forLoop =>
      'Repetir por um intervalo de nÃƒÂºmeros (loop for)';

  @override
  String get action_description_getGlobalVariable =>
      'Ler uma variÃƒÂ¡vel global e injetar nas variÃƒÂ¡veis de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_getGuildOnboarding =>
      'Buscar a configuraÃƒÂ§ÃƒÂ£o de integraÃƒÂ§ÃƒÂ£o atual do servidor';

  @override
  String get action_description_getInvite =>
      'Buscar informaÃƒÂ§ÃƒÂµes do convite por cÃƒÂ³digo';

  @override
  String get action_description_getMember =>
      'Obter informaÃƒÂ§ÃƒÂµes do membro';

  @override
  String get action_description_getMessage =>
      'Buscar uma mensagem e expor seus campos';

  @override
  String get action_description_getMusicInfo =>
      'Obter informaÃƒÂ§ÃƒÂµes sobre a mÃƒÂºsica que estÃƒÂ¡ tocando';

  @override
  String get action_description_getScopedVariable =>
      'Ler uma variÃƒÂ¡vel de escopo e injetar nas variÃƒÂ¡veis de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_getWebhook =>
      'Obter informaÃƒÂ§ÃƒÂµes do Webhook por ID';

  @override
  String get action_description_httpRequest =>
      'Enviar requisiÃƒÂ§ÃƒÂ£o HTTP com URL, mÃƒÂ©todo, cabeÃƒÂ§alhos e corpo dinÃƒÂ¢micos';

  @override
  String get action_description_ifBlock =>
      'RamificaÃƒÂ§ÃƒÂ£o condicional: executar aÃƒÂ§ÃƒÂµes diferentes com base em uma condiÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_jumpToAction =>
      'Saltar para uma aÃƒÂ§ÃƒÂ£o especÃƒÂ­fica por chave, ID ou posiÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_joinVoice => 'Conectar-se a um canal de voz';

  @override
  String get action_description_jsonForEachLoop =>
      'Repetir por cada elemento de um objeto ou matriz JSON (forEach)';

  @override
  String get action_description_kickUser => 'Expulsa um membro do servidor';

  @override
  String get action_description_leaveGuild =>
      'Fazer o bot sair do servidor/guilda';

  @override
  String get action_description_leaveVoice =>
      'Sair do canal de voz e desconectar o reprodutor';

  @override
  String get action_description_listAutoModRules =>
      'Listar todas as regras de moderaÃƒÂ§ÃƒÂ£o automÃƒÂ¡tica no servidor';

  @override
  String get action_description_listMembers =>
      'Listar membros em um servidor com opÃƒÂ§ÃƒÂµes';

  @override
  String get action_description_listScopedVariableIndex =>
      'Listar valores de escopo indexados ordenados por valor com deslocamento e limite';

  @override
  String get action_description_listWebhooks =>
      'Listar todos os Webhooks em um canal ou servidor';

  @override
  String get action_description_listenAndExecute =>
      'Registrar um fluxo de trabalho para rodar quando um botÃƒÂ£o for clicado, um menu de seleÃƒÂ§ÃƒÂ£o for usado ou um modal for enviado';

  @override
  String get action_description_listenForButtonClick =>
      'Registrar um fluxo de trabalho para rodar quando um botÃƒÂ£o for clicado';

  @override
  String get action_description_listenForModalSubmit =>
      'Registrar um fluxo de trabalho para rodar quando um modal for enviado';

  @override
  String get action_description_listenForSelectMenu =>
      'Registrar um fluxo de trabalho para rodar quando um menu de seleÃƒÂ§ÃƒÂ£o for usado';

  @override
  String get action_description_log =>
      'Imprimir ou armazenar mensagem de diagnÃƒÂ³stico nos registros de aÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_moveToVoiceChannel =>
      'Mover um membro para um canal de voz especÃƒÂ­fico';

  @override
  String get action_description_muteUser =>
      'Exclui temporariamente (timeout) um membro';

  @override
  String get action_description_pauseMusic => 'Pausar a mÃƒÂºsica atual';

  @override
  String get action_description_pinMessage => 'Fixar uma mensagem em um canal';

  @override
  String get action_description_playMusic =>
      'Tocar uma mÃƒÂºsica por pesquisa ou URL';

  @override
  String get action_description_queryArray =>
      'Filtrar, ordenar e paginar qualquer matriz JSON de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_randomChoice =>
      'Escolhe um item aleatÃƒÂ³rio de uma lista e armazena em uma variÃƒÂ¡vel';

  @override
  String get action_description_registerGuildCommands =>
      'Registrar comandos de aplicativo em um servidor';

  @override
  String get action_description_removeArrayElement =>
      'Remover um elemento de uma matriz JSON global ou de escopo por ÃƒÂ­ndice';

  @override
  String get action_description_removeChannel => 'Excluir um canal';

  @override
  String get action_description_removeGlobalVariable =>
      'Excluir uma variÃƒÂ¡vel global';

  @override
  String get action_description_removeReaction =>
      'Remove uma reaÃƒÂ§ÃƒÂ£o de uma mensagem';

  @override
  String get action_description_removeRole => 'Remove um cargo de um membro';

  @override
  String get action_description_removeScopedVariable =>
      'Excluir uma variÃƒÂ¡vel de escopo';

  @override
  String get action_description_removeThreadMember =>
      'Remover um membro de um tÃƒÂ³pico';

  @override
  String get action_description_renameScopedVariable =>
      'Renomear a chave de uma variÃƒÂ¡vel de escopo';

  @override
  String get action_description_respondWithAutocomplete =>
      'Responder a uma interaÃƒÂ§ÃƒÂ£o de preenchimento automÃƒÂ¡tico do Discord com atÃƒÂ© 25 escolhas dinÃƒÂ¢micas';

  @override
  String get action_description_respondWithComponentV2 =>
      'Responder ao comando com botÃƒÂµes/menus de seleÃƒÂ§ÃƒÂ£o';

  @override
  String get action_description_respondWithMessage =>
      'Responder ao comando com uma mensagem normal';

  @override
  String get action_description_respondWithModal =>
      'Mostrar uma caixa de diÃƒÂ¡logo modal ao usuÃƒÂ¡rio';

  @override
  String get action_description_resumeMusic => 'Retomar uma mÃƒÂºsica pausada';

  @override
  String get action_description_runBdfdScript =>
      'Compilar e executar um script BDFD em linha como aÃƒÂ§ÃƒÂµes de fluxo de trabalho';

  @override
  String get action_description_runWorkflow =>
      'Executar um fluxo de trabalho salvo (suporta ponto de entrada + argumentos)';

  @override
  String get action_description_runtimeImageBlock =>
      'Executar um bloco de aÃƒÂ§ÃƒÂµes de processamento de tela de imagem';

  @override
  String get action_description_runtimeJsonBlock =>
      'Executar um bloco de aÃƒÂ§ÃƒÂµes de processamento JSON';

  @override
  String get action_description_seekMusic =>
      'Ir para uma posiÃƒÂ§ÃƒÂ£o especÃƒÂ­fica na mÃƒÂºsica atual';

  @override
  String get action_description_sendComponentV2 =>
      'Enviar componentes interativos';

  @override
  String get action_description_sendDm =>
      'Envia uma mensagem privada para um usuÃƒÂ¡rio especÃƒÂ­fico';

  @override
  String get action_description_sendMessage =>
      'Envia uma mensagem para um canal especÃƒÂ­fico';

  @override
  String get action_description_sendWebhook => 'Enviar mensagem via Webhook';

  @override
  String get action_description_serverDeafenMember =>
      'Ensurdecer ou desensurdecer um membro no servidor';

  @override
  String get action_description_serverMuteMember =>
      'Mutar ou desmutar um membro no servidor';

  @override
  String get action_description_setGlobalVariable =>
      'Criar ou atualizar uma variÃƒÂ¡vel global para este bot';

  @override
  String get action_description_setMusicLoop =>
      'Ativar ou desativar a repetiÃƒÂ§ÃƒÂ£o da fila';

  @override
  String get action_description_setMusicVolume =>
      'Ajustar o volume do reprodutor (0 a 200)';

  @override
  String get action_description_setNickname =>
      'Altera o apelido de um membro do servidor';

  @override
  String get action_description_setScopedVariable =>
      'Criar ou atualizar uma variÃƒÂ¡vel de escopo (servidor/usuÃƒÂ¡rio/canal/membro/mensagem)';

  @override
  String get action_description_setTemporaryVariable =>
      'Criar ou atualizar uma variÃƒÂ¡vel temporÃƒÂ¡ria na execuÃƒÂ§ÃƒÂ£o local';

  @override
  String get action_description_skipActions =>
      'Saltar um nÃƒÂºmero especificado de aÃƒÂ§ÃƒÂµes seguintes';

  @override
  String get action_description_skipMusic =>
      'Pular para a prÃƒÂ³xima mÃƒÂºsica na fila';

  @override
  String get action_description_slowmode =>
      'Define a duraÃƒÂ§ÃƒÂ£o do modo lento para um canal';

  @override
  String get action_description_stop =>
      'Para imediatamente a execuÃƒÂ§ÃƒÂ£o do fluxo atual';

  @override
  String get action_description_stopMusic =>
      'Parar a reproduÃƒÂ§ÃƒÂ£o e limpar a fila';

  @override
  String get action_description_stopUnless =>
      'Parar o fluxo de trabalho se uma condiÃƒÂ§ÃƒÂ£o nÃƒÂ£o for atendida (guarda/filtro)';

  @override
  String get action_description_unbanUser =>
      'Revoga o banimento de um usuÃƒÂ¡rio';

  @override
  String get action_description_unmuteUser =>
      'Remove a exclusÃƒÂ£o temporÃƒÂ¡ria de um membro';

  @override
  String get action_description_unpinMessage =>
      'Desafixar uma mensagem em um canal';

  @override
  String get action_description_unregisterGuildCommands =>
      'Cancelar registro de comandos de aplicativo em um servidor';

  @override
  String get action_description_updateAutoMod =>
      'Atualizar configuraÃƒÂ§ÃƒÂµes de moderaÃƒÂ§ÃƒÂ£o automÃƒÂ¡tica';

  @override
  String get action_description_updateChannel =>
      'Atualizar as configuraÃƒÂ§ÃƒÂµes do canal';

  @override
  String get action_description_updateEmoji =>
      'Atualizar o nome do emoji ou acesso a cargos no servidor';

  @override
  String get action_description_updateGuild =>
      'Atualizar as configuraÃƒÂ§ÃƒÂµes do servidor';

  @override
  String get action_description_updateGuildOnboarding =>
      'Atualizar a configuraÃƒÂ§ÃƒÂ£o de integraÃƒÂ§ÃƒÂ£o do servidor';

  @override
  String get action_description_updateSelfUser =>
      'Atualizar o perfil do prÃƒÂ³prio bot (nome de usuÃƒÂ¡rio/avatar)';

  @override
  String get action_description_wait =>
      'Pausa a execuÃƒÂ§ÃƒÂ£o do fluxo por uma duraÃƒÂ§ÃƒÂ£o especÃƒÂ­fica';

  @override
  String get action_dynamic => 'DinÃƒÂ¢mico';

  @override
  String get action_dynamic_bool_hint => 'true/false ou ((variÃƒÂ¡vel))';

  @override
  String action_dynamic_id_hint(String type) {
    return '$type dinÃƒÂ¢mico (suporta ((...)))';
  }

  @override
  String get action_dynamic_multiselect_hint =>
      'Valor dinÃƒÂ¢mico (suporta ((...)))';

  @override
  String get action_dynamic_numeric => 'SugestÃƒÂµes numÃƒÂ©ricas dinÃƒÂ¢micas';

  @override
  String get action_dynamic_variable =>
      'SugestÃƒÂµes de variÃƒÂ¡veis dinÃƒÂ¢micas';

  @override
  String action_edit_nested(int count) {
    return 'Editar $count';
  }

  @override
  String action_edit_nested_parens(int count) {
    return 'Editar ($count)';
  }

  @override
  String action_edit_param(String name) {
    return 'Editar $name';
  }

  @override
  String get action_edit_raw_json => 'Editar JSON Bruto';

  @override
  String action_else_if_label(int index) {
    return 'ELSE IF $index Ã¢â‚¬â€ aÃƒÂ§ÃƒÂµes';
  }

  @override
  String get action_error_continue => 'Continuar';

  @override
  String get action_error_stop => 'Parar';

  @override
  String get action_expression => 'ExpressÃƒÂ£o';

  @override
  String get action_format_json => 'Formatar JSON';

  @override
  String get action_hint_color => '#FFFFFF ou rgb(255,255,255)';

  @override
  String get action_hint_condition_value => 'Valor para comparar';

  @override
  String get action_hint_condition_var =>
      'Use ((nomeVariavel)) ou um valor de tempo de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get action_hint_cooldown_error =>
      'Mensagem de erro personalizada (suporta %time%)';

  @override
  String get action_hint_cooldown_time => 'Tempo (ex: 10s, 1m)';

  @override
  String get action_hint_duration => 'ex: 5m, 1h, 30s';

  @override
  String get action_hint_emoji => 'Emoji (ex. Ã°Å¸ÂªÅ“) ou <:nome:id>';

  @override
  String action_hint_enter_type(String type) {
    return 'Digite $type';
  }

  @override
  String get action_hint_random_choices =>
      'Lista de escolhas (separadas por ;)';

  @override
  String get action_hint_random_var =>
      'Nome da variÃƒÂ¡vel para armazenar o resultado';

  @override
  String get action_hint_variable_key => 'Selecionar chave de variÃƒÂ¡vel';

  @override
  String get action_hint_workflow => 'Nome do workflow salvo';

  @override
  String get action_http_headers_title =>
      'CabeÃƒÂ§alhos HTTP (Pares Chave/Valor)';

  @override
  String action_http_paths_parsed(int count) {
    return '$count caminhos analisados';
  }

  @override
  String get action_http_response_body => 'Corpo da Resposta (Bruto):';

  @override
  String action_http_status(int status) {
    return 'Status: $status';
  }

  @override
  String get action_http_test_button =>
      'Enviar RequisiÃƒÂ§ÃƒÂ£o de Teste e Detectar Rotas';

  @override
  String get action_http_test_title =>
      'Resultados da RequisiÃƒÂ§ÃƒÂ£o de Teste';

  @override
  String get action_json_editor_hint =>
      'Editor de objeto JSON (suporta objetos/arrays aninhados)';

  @override
  String get action_key_field => 'Chave da AÃƒÂ§ÃƒÂ£o';

  @override
  String get action_key_value_pairs => 'Pares Chave / Valor';

  @override
  String get action_literal => 'Literal';

  @override
  String get action_loading_keys => 'Carregando chaves...';

  @override
  String get action_manage_variable_keys => 'Gerenciar Chaves de VariÃƒÂ¡veis';

  @override
  String get action_name_addReaction => 'Adicionar ReaÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_addRole => 'Adicionar Cargo';

  @override
  String get action_name_addThreadMember => 'Adicionar Membro da Thread';

  @override
  String get action_name_appendArrayElement => 'Adicionar Elemento ao Array';

  @override
  String get action_name_attachImage => 'Anexar Imagem';

  @override
  String get action_name_banUser => 'Banir Utilizador';

  @override
  String get action_name_calculate => 'Calcular';

  @override
  String get action_name_canvasCreateBlock => 'Criar Tela';

  @override
  String get action_name_canvasDrawCircleBlock => 'Desenhar CÃƒÂ­rculo';

  @override
  String get action_name_canvasDrawLineBlock => 'Desenhar Linha';

  @override
  String get action_name_canvasDrawRectBlock => 'Desenhar RetÃƒÂ¢ngulo';

  @override
  String get action_name_canvasDrawTextBlock => 'Desenhar Texto';

  @override
  String get action_name_canvasLoadImageBlock => 'Carregar Imagem';

  @override
  String get action_name_clearAllReactions => 'Limpar Todas as ReaÃƒÂ§ÃƒÂµes';

  @override
  String get action_name_cooldown => 'Cooldown';

  @override
  String get action_name_createAutoModRule => 'Criar Regra AutoMod';

  @override
  String get action_name_createChannel => 'Criar Canal';

  @override
  String get action_name_createEmoji => 'Criar Emoji';

  @override
  String get action_name_createInvite => 'Criar Convite';

  @override
  String get action_name_createPoll => 'Criar Sondagem';

  @override
  String get action_name_createThread => 'Criar Thread';

  @override
  String get action_name_debugProfile => 'Perfil de DepuraÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_deferInteraction => 'Adiar InteraÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_deleteAutoModRule => 'Eliminar Regra AutoMod';

  @override
  String get action_name_deleteChannelPermission =>
      'Eliminar PermissÃƒÂ£o do Canal';

  @override
  String get action_name_deleteEmoji => 'Eliminar Emoji';

  @override
  String get action_name_deleteInvite => 'Eliminar Convite';

  @override
  String get action_name_deleteMessages => 'Eliminar Mensagens';

  @override
  String get action_name_deleteTrigger => 'Apagar Gatilho';

  @override
  String get action_name_deleteWebhook => 'Eliminar Webhook';

  @override
  String get action_name_disconnectFromVoice => 'Desligar da Voz';

  @override
  String get action_name_editChannelPermissions =>
      'Editar PermissÃƒÂµes do Canal';

  @override
  String get action_name_editComponentV2 => 'Editar Componente V2';

  @override
  String get action_name_editInteractionMessage =>
      'Editar Mensagem de InteraÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_editMessage => 'Editar Mensagem';

  @override
  String get action_name_editWebhook => 'Editar Webhook';

  @override
  String get action_name_endPoll => 'Terminar Sondagem';

  @override
  String get action_name_forLoop => 'Loop For';

  @override
  String get action_name_getGlobalVariable => 'Obter VariÃƒÂ¡vel Global';

  @override
  String get action_name_getGuildOnboarding =>
      'Obter IntroduÃƒÂ§ÃƒÂ£o do Servidor';

  @override
  String get action_name_getInvite => 'Obter Convite';

  @override
  String get action_name_getMember => 'Obter Membro';

  @override
  String get action_name_getMessage => 'Obter Mensagem';

  @override
  String get action_name_getMusicInfo => 'Obter Info da MÃƒÂºsica';

  @override
  String get action_name_getScopedVariable => 'Obter VariÃƒÂ¡vel de Ãƒâ€šmbito';

  @override
  String get action_name_getWebhook => 'Obter Webhook';

  @override
  String get action_name_httpRequest => 'Pedido HTTP';

  @override
  String get action_name_ifBlock => 'Bloco IF / ELSE';

  @override
  String get action_name_jumpToAction => 'Saltar para aÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_joinVoice => 'Entrar no Canal de Voz';

  @override
  String get action_name_jsonForEachLoop => 'Loop For Each JSON';

  @override
  String get action_name_kickUser => 'Expulsar Utilizador';

  @override
  String get action_name_leaveGuild => 'Sair do Servidor';

  @override
  String get action_name_leaveVoice => 'Sair do Canal de Voz';

  @override
  String get action_name_listAutoModRules => 'Listar Regras AutoMod';

  @override
  String get action_name_listMembers => 'Listar Membros';

  @override
  String get action_name_listScopedVariableIndex =>
      'Listar ÃƒÂndice de VariÃƒÂ¡veis de Ãƒâ€šmbito';

  @override
  String get action_name_listWebhooks => 'Listar Webhooks';

  @override
  String get action_name_listenAndExecute => 'Ouvir e Executar';

  @override
  String get action_name_listenForButtonClick => 'Ouvir Clique de BotÃƒÂ£o';

  @override
  String get action_name_listenForModalSubmit => 'Ouvir SubmissÃƒÂ£o de Modal';

  @override
  String get action_name_listenForSelectMenu => 'Ouvir Menu de SeleÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_log => 'Registrar Mensagem';

  @override
  String get action_name_moveToVoiceChannel => 'Mover para Canal de Voz';

  @override
  String get action_name_muteUser => 'Silenciar Utilizador';

  @override
  String get action_name_pauseMusic => 'Pausar MÃƒÂºsica';

  @override
  String get action_name_pinMessage => 'Fixar Mensagem';

  @override
  String get action_name_playMusic => 'Tocar MÃƒÂºsica';

  @override
  String get action_name_queryArray => 'Consultar Array';

  @override
  String get action_name_randomChoice => 'Escolha AleatÃƒÂ³ria';

  @override
  String get action_name_registerGuildCommands =>
      'Registrar Comandos de Servidor';

  @override
  String get action_name_removeArrayElement => 'Remover Elemento do Array';

  @override
  String get action_name_removeChannel => 'Remover Canal';

  @override
  String get action_name_removeGlobalVariable => 'Remover VariÃƒÂ¡vel Global';

  @override
  String get action_name_removeReaction => 'Remover ReaÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_removeRole => 'Remover Cargo';

  @override
  String get action_name_removeScopedVariable =>
      'Remover VariÃƒÂ¡vel de Ãƒâ€šmbito';

  @override
  String get action_name_removeThreadMember => 'Remover Membro da Thread';

  @override
  String get action_name_renameScopedVariable =>
      'Renomear VariÃƒÂ¡vel de Ãƒâ€šmbito';

  @override
  String get action_name_respondWithAutocomplete =>
      'Responder com Autocomplete';

  @override
  String get action_name_respondWithComponentV2 =>
      'Responder com Componente V2';

  @override
  String get action_name_respondWithMessage => 'Responder com Mensagem';

  @override
  String get action_name_respondWithModal => 'Responder com Modal';

  @override
  String get action_name_resumeMusic => 'Retomar MÃƒÂºsica';

  @override
  String get action_name_runBdfdScript => 'Executar Script BDFD';

  @override
  String get action_name_runWorkflow => 'Executar Fluxo de Trabalho';

  @override
  String get action_name_runtimeImageBlock =>
      'Executar OperaÃƒÂ§ÃƒÂµes de Imagem';

  @override
  String get action_name_runtimeJsonBlock => 'Executar OperaÃƒÂ§ÃƒÂµes JSON';

  @override
  String get action_name_seekMusic => 'AvanÃƒÂ§ar/Retroceder PosiÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_sendComponentV2 => 'Enviar Componente V2';

  @override
  String get action_name_sendDm => 'Enviar MP';

  @override
  String get action_name_sendMessage => 'Enviar Mensagem';

  @override
  String get action_name_sendWebhook => 'Enviar Webhook';

  @override
  String get action_name_serverDeafenMember => 'Ensurdecer Membro no Servidor';

  @override
  String get action_name_serverMuteMember => 'Silenciar Membro no Servidor';

  @override
  String get action_name_setGlobalVariable => 'Definir VariÃƒÂ¡vel Global';

  @override
  String get action_name_setMusicLoop => 'Configurar RepetiÃƒÂ§ÃƒÂ£o';

  @override
  String get action_name_setMusicVolume => 'Ajustar Volume';

  @override
  String get action_name_setNickname => 'Definir Apelido';

  @override
  String get action_name_setScopedVariable =>
      'Definir VariÃƒÂ¡vel de Ãƒâ€šmbito';

  @override
  String get action_name_setTemporaryVariable =>
      'Definir VariÃƒÂ¡vel TemporÃƒÂ¡ria';

  @override
  String get action_name_skipActions => 'Saltar aÃƒÂ§ÃƒÂµes';

  @override
  String get action_name_skipMusic => 'Pular MÃƒÂºsica';

  @override
  String get action_name_slowmode => 'Modo Lento';

  @override
  String get action_name_stop => 'Parar';

  @override
  String get action_name_stopMusic => 'Parar MÃƒÂºsica';

  @override
  String get action_name_stopUnless =>
      'Parar a menos que a condiÃƒÂ§ÃƒÂ£o seja cumprida';

  @override
  String get action_name_unbanUser => 'Desbanir Utilizador';

  @override
  String get action_name_unmuteUser => 'Reativar Som do Utilizador';

  @override
  String get action_name_unpinMessage => 'Desafixar Mensagem';

  @override
  String get action_name_unregisterGuildCommands =>
      'Cancelar Registro de Comandos de Servidor';

  @override
  String get action_name_updateAutoMod => 'Atualizar AutoMod';

  @override
  String get action_name_updateChannel => 'Atualizar Canal';

  @override
  String get action_name_updateEmoji => 'Atualizar Emoji';

  @override
  String get action_name_updateGuild => 'Atualizar Servidor';

  @override
  String get action_name_updateGuildOnboarding =>
      'Atualizar IntroduÃƒÂ§ÃƒÂ£o do Servidor';

  @override
  String get action_name_updateSelfUser =>
      'Atualizar PrÃƒÂ³prio Utilizador (Perfil do Bot)';

  @override
  String get action_name_wait => 'Aguardar';

  @override
  String get action_no_actions_yet => 'Nenhuma aÃƒÂ§ÃƒÂ£o neste ramo ainda.';

  @override
  String get action_no_args_tap_edit =>
      'Sem argumentos - toque em editar para adicionar';

  @override
  String get action_no_else_if_yet =>
      'Nenhum ramo ELSE IF ainda. Adicione um para testar mais condiÃƒÂ§ÃƒÂµes antes do ELSE.';

  @override
  String get action_no_headers_tap_edit =>
      'Sem cabeÃƒÂ§alhos - toque em editar para adicionar';

  @override
  String get action_no_items_tap_edit =>
      'Sem itens - toque em editar para adicionar';

  @override
  String get action_no_properties_tap_edit =>
      'Sem propriedades - toque em editar para configurar';

  @override
  String get action_no_saved_keys =>
      'Nenhuma chave salva encontrada. As chaves sÃƒÂ£o criadas automaticamente no primeiro acesso.';

  @override
  String get action_on_error => 'Em caso de erro';

  @override
  String get action_options_tooltip => 'OpÃƒÂ§ÃƒÂµes de aÃƒÂ§ÃƒÂ£o';

  @override
  String get action_or_type_workflow => 'Ou digite o nome do workflow';

  @override
  String get action_order_tip =>
      'Dica: use as setas para alterar a ordem das aÃƒÂ§ÃƒÂµes.';

  @override
  String action_position(int index, int total) {
    return 'AÃƒÂ§ÃƒÂ£o $index/$total';
  }

  @override
  String get action_preview_json => 'Visualizar JSON Destacado';

  @override
  String get action_provide_valid_url =>
      'Por favor, forneÃƒÂ§a uma URL vÃƒÂ¡lida.';

  @override
  String get action_refresh_keys => 'Atualizar chaves';

  @override
  String get action_remove_confirm =>
      'Esta aÃƒÂ§ÃƒÂ£o serÃƒÂ¡ removida do fluxo de trabalho. Continuar?';

  @override
  String get action_remove_else_if => 'Remover ELSE IF';

  @override
  String get action_remove_menu => 'Remover aÃƒÂ§ÃƒÂ£o';

  @override
  String get action_remove_title => 'Remover aÃƒÂ§ÃƒÂ£o';

  @override
  String get action_root_must_json => 'A raiz deve ser um objeto JSON';

  @override
  String get action_select_saved_key => 'Selecione uma chave salva';

  @override
  String get action_select_stored_key =>
      'Selecione uma chave armazenada (o prefixo bc_ ÃƒÂ© opcional)';

  @override
  String get action_static_badge => '(estÃƒÂ¡tico)';

  @override
  String get action_status_disabled => 'Desativado';

  @override
  String get action_status_enabled => 'Ativado';

  @override
  String get action_store_results =>
      'Armazenar resultados em variÃƒÂ¡veis globais';

  @override
  String actions_active_route(String label) {
    return 'Rota ativa: $label';
  }

  @override
  String get actions_add_label => 'Adicionar AÃƒÂ§ÃƒÂ£o';

  @override
  String get actions_add_new_title => 'Adicionar Nova AÃƒÂ§ÃƒÂ£o';

  @override
  String actions_build_button(int count) {
    return 'Construir AÃƒÂ§ÃƒÂµes ($count)';
  }

  @override
  String get actions_empty_subtitle =>
      'Adicione uma aÃƒÂ§ÃƒÂ£o e depois abra-a para configurar os detalhes.';

  @override
  String get actions_empty_title => 'Nenhuma aÃƒÂ§ÃƒÂ£o';

  @override
  String get actions_builder_title => 'Construtor de AÃƒÂ§ÃƒÂµes';

  @override
  String get actions_description =>
      'Construa aÃƒÂ§ÃƒÂµes de tempo de execuÃƒÂ§ÃƒÂ£o para este comando';

  @override
  String get actions_global_variables => 'VariÃƒÂ¡veis Globais';

  @override
  String actions_key_label(String key) {
    return 'Chave: $key';
  }

  @override
  String actions_missing_field_content(String action, String field) {
    return '\"$action\": \"$field\" ÃƒÂ© obrigatÃƒÂ³rio.';
  }

  @override
  String get actions_missing_field_title => 'Campo ObrigatÃƒÂ³rio Ausente';

  @override
  String get actions_no_matches =>
      'Nenhuma aÃƒÂ§ÃƒÂ£o corresponde ÃƒÂ  sua busca.';

  @override
  String actions_save_count(int count) {
    return 'Salvar $count aÃƒÂ§ÃƒÂµes';
  }

  @override
  String get actions_save_tooltip => 'Salvar AÃƒÂ§ÃƒÂµes';

  @override
  String get actions_save_workflow_title => 'Salvar como Fluxo';

  @override
  String get actions_search_hint => 'Buscar aÃƒÂ§ÃƒÂµes...';

  @override
  String get actions_search_sequence_hint => 'Pesquisar sequÃƒÂªncia...';

  @override
  String actions_sequence_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aÃƒÂ§ÃƒÂµes',
      one: '1 aÃƒÂ§ÃƒÂ£o',
      zero: 'Nenhuma aÃƒÂ§ÃƒÂ£o',
    );
    return '$_temp0';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Passo $index de $total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'Script BDFD | $lines linha(s) | $diagnostics diagnÃƒÂ³stico(s)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count aÃƒÂ§ÃƒÂ£o(ÃƒÂµes) configurada(s)';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Script Dart | $lines linha(s) | $diagnostics diagnÃƒÂ³stico(s)';
  }

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count aÃƒÂ§ÃƒÂ£o(ÃƒÂµes) na rota ativa | $routes rota(s)';
  }

  @override
  String get actions_title => 'AÃƒÂ§ÃƒÂµes';

  @override
  String get actions_workflow_name_label => 'Nome do fluxo';

  @override
  String get actions_workflows => 'Fluxos de trabalho';

  @override
  String get ads_consent_accept => 'Eu aceito';

  @override
  String get ads_consent_message =>
      'Para cumprir o RGPD, precisamos do seu consentimento antes de mostrar anÃƒÂºncios. Pode continuar a usar a app mesmo que recuse.';

  @override
  String get ads_consent_refuse => 'Eu recuso';

  @override
  String get ads_consent_refused_info =>
      'Consentimento de anÃƒÂºncios recusado. O bot iniciarÃƒÂ¡ normalmente.';

  @override
  String get ads_consent_title => 'Consentimento de anÃƒÂºncios';

  @override
  String get app_bot_token => 'Token de Bot';

  @override
  String get app_create_button => 'Criar AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get app_create_hero_desc =>
      'Uma configuraÃƒÂ§ÃƒÂ£o guiada para abrir as pÃƒÂ¡ginas corretas, copiar o seu token e importar o bot com seguranÃƒÂ§a.';

  @override
  String get app_create_hero_title => 'Ligue o seu bot do Discord';

  @override
  String get app_create_new => 'Criar nova AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get app_create_page_title => 'Criar AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get app_enter_token => 'Introduza o token do seu bot aqui';

  @override
  String get app_external_link_badge => 'Link externo';

  @override
  String get app_hide_token => 'Ocultar token';

  @override
  String get app_how_to_create_token => 'Como criar um Token de Bot?';

  @override
  String get app_loading_error => 'Erro ao carregar';

  @override
  String get app_no_apps => 'Nenhuma aplicaÃƒÂ§ÃƒÂ£o encontrada';

  @override
  String get app_note =>
      'Nota: Precisa de criar uma nova AplicaÃƒÂ§ÃƒÂ£o no Portal de Programadores do Discord e obter o token do seu bot.';

  @override
  String get app_open_discord_portal =>
      'Abrir Portal de Programadores do Discord';

  @override
  String get app_open_discord_portal_desc =>
      'Crie a sua aplicaÃƒÂ§ÃƒÂ£o e ative a secÃƒÂ§ÃƒÂ£o de bot.';

  @override
  String get app_open_link_error =>
      'NÃƒÂ£o foi possÃƒÂ­vel abrir esta pÃƒÂ¡gina externa.';

  @override
  String get app_open_token_tutorial => 'Ler o tutorial do token';

  @override
  String get app_open_token_tutorial_desc =>
      'Um guia passo a passo para gerar e copiar o token do seu bot.';

  @override
  String get app_resources_desc =>
      'Estas aÃƒÂ§ÃƒÂµes abrem as pÃƒÂ¡ginas oficiais de que precisa antes de guardar o seu bot aqui.';

  @override
  String get app_resources_title => 'ConfiguraÃƒÂ§ÃƒÂ£o guiada';

  @override
  String get app_save => 'Guardar AlteraÃƒÂ§ÃƒÂµes';

  @override
  String get app_save_bot => 'Adicionar bot';

  @override
  String get app_show_token => 'Mostrar token';

  @override
  String get app_sync_manager_connect => 'Ligar Discord';

  @override
  String get app_sync_manager_desc =>
      'Este bot jÃƒÂ¡ estÃƒÂ¡ armazenado no Bot Creator Manager. Ligar com o Discord para sincronizar todos os seus bots automaticamente?';

  @override
  String get app_sync_manager_manual => 'Manter local';

  @override
  String get app_sync_manager_title => 'Bot jÃƒÂ¡ gerido';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_invalid_content =>
      'O token parece ter sido redefinido. Por favor, forneÃƒÂ§a o novo token do Portal de Programadores do Discord.';

  @override
  String get app_token_invalid_title => 'RedefiniÃƒÂ§ÃƒÂ£o de token detectada';

  @override
  String get app_token_field_helper =>
      'Cole o token exatamente como fornecido pelo Discord.';

  @override
  String get app_token_section_desc =>
      'Assim que o token for copiado, cole-o abaixo para adicionar o seu bot ÃƒÂ  app.';

  @override
  String get app_token_section_title => 'Cole o token do seu bot';

  @override
  String get app_token_security_hint =>
      'Mantenha este token privado. Qualquer pessoa com ele pode controlar o seu bot.';

  @override
  String get autocomplete_dynamic => 'Autocompletar DinÃƒÂ¢mico';

  @override
  String get autocomplete_dynamic_desc =>
      'Resolva as escolhas de um fluxo em vez de valores estÃƒÂ¡ticos.';

  @override
  String get autocomplete_filter_hint =>
      'As sugestÃƒÂµes sÃƒÂ£o filtradas pelo que o usuÃƒÂ¡rio digita.';

  @override
  String get autocomplete_loading => 'Carregando fluxosÃ¢â‚¬Â¦';

  @override
  String get autocomplete_no_workflows => 'Nenhum fluxo salvo encontrado';

  @override
  String get autocomplete_select_workflow => 'Selecione um fluxo salvo';

  @override
  String get autocomplete_type_name => 'Ou digite o nome do fluxo';

  @override
  String get autocomplete_workflow_label => 'Fluxo de Autocompletar';

  @override
  String backup_completed(String id) {
    return 'CÃƒÂ³pia de seguranÃƒÂ§a concluÃƒÂ­da: $id';
  }

  @override
  String backup_failed(String error) {
    return 'CÃƒÂ³pia de seguranÃƒÂ§a falhou: $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Este script BDFD nÃƒÂ£o pÃƒÂ´de ser compilado:\n$summary';
  }

  @override
  String get bdfd_compile_error_simple =>
      'Este script BDFD nÃƒÂ£o pÃƒÂ´de ser compilado.';

  @override
  String get bdfd_compiled_no_actions =>
      'Este script BDFD foi compilado com sucesso, mas nÃƒÂ£o produziu nenhuma aÃƒÂ§ÃƒÂ£o.';

  @override
  String get bdfd_docs_category_channels => 'Canais & TÃƒÂ³picos';

  @override
  String get bdfd_docs_category_components => 'Componentes';

  @override
  String get bdfd_docs_category_control => 'Fluxo de Controlo';

  @override
  String get bdfd_docs_category_cooldowns => 'Tempos de espera';

  @override
  String get bdfd_docs_category_embeds => 'Embeds';

  @override
  String get bdfd_docs_category_guards => 'Guardas & PermissÃƒÂµes';

  @override
  String get bdfd_docs_category_http => 'RequisiÃƒÂ§ÃƒÂµes HTTP';

  @override
  String get bdfd_docs_category_json => 'JSON';

  @override
  String get bdfd_docs_category_leaderboards => 'Placares';

  @override
  String get bdfd_docs_category_math => 'MatemÃƒÂ¡tica';

  @override
  String get bdfd_docs_category_messages => 'Mensagens & ConteÃƒÂºdo';

  @override
  String get bdfd_docs_category_misc => 'Outros';

  @override
  String get bdfd_docs_category_modals => 'Modais';

  @override
  String get bdfd_docs_category_moderation => 'ModeraÃƒÂ§ÃƒÂ£o';

  @override
  String get bdfd_docs_category_reactions => 'ReaÃƒÂ§ÃƒÂµes';

  @override
  String get bdfd_docs_category_roles => 'Cargos';

  @override
  String get bdfd_docs_category_text => 'Texto & Strings';

  @override
  String get bdfd_docs_category_tickets => 'Tickets';

  @override
  String get bdfd_docs_category_variables => 'VariÃƒÂ¡veis';

  @override
  String get bdfd_docs_category_webhooks => 'Webhooks';

  @override
  String get bdfd_docs_desc_and =>
      'E lÃƒÂ³gico Ã¢â‚¬â€ combina mÃƒÂºltiplas condiÃƒÂ§ÃƒÂµes. Todas devem ser verdadeiras.\n\nUso: \$if[\$and[\$authorID==123;\$hasRole[456]]]';

  @override
  String get bdfd_docs_desc_awaitfunc =>
      'Regista um callback que espera por uma resposta do utilizador.\n\nUso: \$awaitFunc[nome;userID (opt);channelID (opt)]\n\nA funÃƒÂ§ÃƒÂ£o aguardada ÃƒÂ© armazenada e ativada quando o utilizador alvo envia uma mensagem no canal alvo.';

  @override
  String get bdfd_docs_desc_callworkflow =>
      'Apenas Bot Creator Ã¢â‚¬â€ Chama outro workflow pelo nome e passa argumentos.\n\nSintaxe: \$callWorkflow[meuWorkflow;chave1=valor1;chave2=valor2]\n\nO workflow chamado pode ler argumentos e retornar um valor via \$workflowResponse.';

  @override
  String get bdfd_docs_desc_defer =>
      'Adia a resposta da interaÃƒÂ§ÃƒÂ£o, dando-lhe mais tempo para processar. O utilizador vÃƒÂª uma mensagem \"O bot estÃƒÂ¡ a pensarÃ¢â‚¬Â¦\". Use antes de operaÃƒÂ§ÃƒÂµes longas como requisiÃƒÂ§ÃƒÂµes HTTP.';

  @override
  String get bdfd_docs_desc_elseif =>
      'Adiciona uma condiÃƒÂ§ÃƒÂ£o alternativa dentro de um bloco \$if. Deve aparecer entre \$if e \$else/\$endif.';

  @override
  String get bdfd_docs_desc_embedsuppresserrors =>
      'O mesmo que \$suppressErrors Ã¢â‚¬â€ silencia todas as mensagens de erro.';

  @override
  String get bdfd_docs_desc_ephemeral =>
      'Torna a resposta visÃƒÂ­vel apenas para o utilizador que ativou o comando. Deve ser colocado antes de qualquer conteÃƒÂºdo de resposta.';

  @override
  String get bdfd_docs_desc_eval =>
      'Executa uma string de script BDFD em tempo de execuÃƒÂ§ÃƒÂ£o. O cÃƒÂ³digo passado como argumento ÃƒÂ© recompilado e executado dinamicamente. ÃƒÅ¡til para executar scripts fornecidos pelo utilizador ou baseados em variÃƒÂ¡veis.';

  @override
  String get bdfd_docs_desc_for =>
      'Apenas Bot Creator Ã¢â‚¬â€ Repete um bloco de cÃƒÂ³digo N vezes.\n\nSimples: \$for[5]...\$endfor Ã¢â€ â€™ o corpo ÃƒÂ© repetido 5 vezes (mÃƒÂ¡x 100). Pode usar \$i para o ÃƒÂ­ndice atual (comeÃƒÂ§ando em 0) e \$loopCount para o total.\n\nEstilo C: \$for[i=0;i<10;i++]...\$endfor Ã¢â€ â€™ loop for clÃƒÂ¡ssico com inicializaÃƒÂ§ÃƒÂ£o, condiÃƒÂ§ÃƒÂ£o e atualizaÃƒÂ§ÃƒÂ£o. Suporta ++, --, +=, -=, *=.\n\nSe a contagem de iteraÃƒÂ§ÃƒÂµes for dinÃƒÂ¢mica (ex: \$for[\$args[1]]), o loop ÃƒÂ© executado em tempo de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get bdfd_docs_desc_httpaddheader =>
      'Adiciona um cabeÃƒÂ§alho ÃƒÂ  prÃƒÂ³xima requisiÃƒÂ§ÃƒÂ£o HTTP. Os cabeÃƒÂ§alhos sÃƒÂ£o acumulados atÃƒÂ© ao prÃƒÂ³ximo \$httpGet/\$httpPost/etc.\n\nUso: \$httpAddHeader[Authorization;Bearer token123]';

  @override
  String get bdfd_docs_desc_httpget =>
      'Envia uma requisiÃƒÂ§ÃƒÂ£o HTTP GET para o URL fornecido. Use \$httpAddHeader antes para definir cabeÃƒÂ§alhos. Use \$httpResult para ler a resposta.\n\nTodos os mÃƒÂ©todos HTTP (GET, POST, PUT, PATCH, DELETE) seguem o mesmo padrÃƒÂ£o.';

  @override
  String get bdfd_docs_desc_httpresult =>
      'Retorna o corpo da ÃƒÂºltima resposta HTTP. Opcionalmente, passe um caminho JSON para extrair um campo especÃƒÂ­fico.\n\nUso: \$httpResult[] para o corpo completo, ou \$httpResult[data.nome] para um campo aninhado.';

  @override
  String get bdfd_docs_desc_if =>
      'Bloco condicional. Suporta aninhamento e operadores ricos: ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nUso:\n\$if[\$authorID==123456]\n  OlÃƒÂ¡ admin!\n\$elseif[\$hasRole[789]]\n  OlÃƒÂ¡ membro!\n\$else\n  OlÃƒÂ¡ convidado!\n\$endif';

  @override
  String get bdfd_docs_desc_jsonparse =>
      'Analisa uma string JSON na memÃƒÂ³ria para manipulaÃƒÂ§ÃƒÂ£o. Todas as operaÃƒÂ§ÃƒÂµes JSON (\$jsonSet, \$json, etc.) operam neste contexto analisado.\n\nJSON estÃƒÂ¡tico ÃƒÂ© resolvido em tempo de compilaÃƒÂ§ÃƒÂ£o para melhor desempenho.';

  @override
  String get bdfd_docs_desc_jsonset =>
      'Define um valor no contexto JSON atual. Suporta caminhos com notaÃƒÂ§ÃƒÂ£o de ponto.\n\nUso: \$jsonSet[utilizador.nome;JoÃƒÂ£o]\n\nA alteraÃƒÂ§ÃƒÂ£o ÃƒÂ© aplicada na memÃƒÂ³ria Ã¢â‚¬â€ use \$jsonStringify para obter o resultado.';

  @override
  String get bdfd_docs_desc_jsonstringify =>
      'Converte o contexto JSON atual de volta para uma string. Use apÃƒÂ³s operaÃƒÂ§ÃƒÂµes \$jsonParse e \$jsonSet para produzir o resultado.';

  @override
  String get bdfd_docs_desc_loop =>
      'Apenas Bot Creator Ã¢â‚¬â€ Alias para \$for. Veja \$for para detalhes. Use \$endloop para fechar o bloco.';

  @override
  String get bdfd_docs_desc_or =>
      'OU lÃƒÂ³gico Ã¢â‚¬â€ combina mÃƒÂºltiplas condiÃƒÂ§ÃƒÂµes. Pelo menos uma deve ser verdadeira.\n\nUso: \$if[\$or[\$authorID==123;\$authorID==456]]]';

  @override
  String get bdfd_docs_desc_stop =>
      'Para imediatamente a execuÃƒÂ§ÃƒÂ£o do script atual. Nenhuma aÃƒÂ§ÃƒÂ£o apÃƒÂ³s o \$stop serÃƒÂ¡ executada.';

  @override
  String get bdfd_docs_desc_suppresserrors =>
      'Impede que mensagens de erro sejam enviadas ao utilizador. Se qualquer aÃƒÂ§ÃƒÂ£o falhar, o erro ÃƒÂ© silenciado.';

  @override
  String get bdfd_docs_desc_try =>
      'Envolve um bloco para tratamento de erros.\n\nUso:\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  A requisiÃƒÂ§ÃƒÂ£o falhou!\n\$endtry\n\nSe qualquer funÃƒÂ§ÃƒÂ£o no bloco \$try falhar, a execuÃƒÂ§ÃƒÂ£o salta para o \$catch.';

  @override
  String get bdfd_docs_desc_url =>
      'Codifica ou decodifica texto para uso em URLs. Use \'encode\' para tornar o texto seguro para URL ou \'decode\' para reverter.\\n\\nUso: \$url[encode;Hello world!!]';

  @override
  String get bdfd_docs_desc_workflowresponse =>
      'Apenas Bot Creator Ã¢â‚¬â€ Retorna a resposta do ÃƒÂºltimo \$callWorkflow.\n\nUse \$workflowResponse[] para a resposta completa, ou \$workflowResponse[propriedade] para aceder a um campo especÃƒÂ­fico.';

  @override
  String get bdfd_docs_empty => 'Nenhuma funÃƒÂ§ÃƒÂ£o correspondente.';

  @override
  String get bdfd_docs_no_params =>
      'Sem parÃƒÂ¢metros Ã¢â‚¬â€ use como \$nomeFuncao';

  @override
  String get bdfd_docs_parameters => 'PARÃƒâ€šMETROS';

  @override
  String get bdfd_docs_search_hint => 'Procurar funÃƒÂ§ÃƒÂµesÃ¢â‚¬Â¦';

  @override
  String get bdfd_docs_syntax => 'SINTAXE';

  @override
  String get bdfd_docs_title => 'DocumentaÃƒÂ§ÃƒÂ£o BDFD';

  @override
  String get bdfd_editor_auto_indent =>
      'Ã¢â‚¬Â¢ Recuo automÃƒÂ¡tico inteligente ao pressionar Enter';

  @override
  String get bdfd_editor_diagnostics_toggle =>
      'Alternar painel de diagnÃƒÂ³sticos';

  @override
  String get bdfd_editor_docs => 'ReferÃƒÂªncia de FunÃƒÂ§ÃƒÂµes BDFD';

  @override
  String get bdfd_editor_empty =>
      'Script vazio Ã¢â‚¬â€ comece a escrever para ver os diagnÃƒÂ³sticos.';

  @override
  String get bdfd_editor_includes => 'Inclui:';

  @override
  String get bdfd_editor_indent_guides => 'Ã¢â‚¬Â¢ Guias de recuo ao vivo';

  @override
  String get bdfd_editor_quick_keys =>
      'Ã¢â‚¬Â¢ Teclas rÃƒÂ¡pidas mÃƒÂ³veis para sÃƒÂ­mbolos BDFD';

  @override
  String get bdfd_editor_tap_hint => 'Toque para abrir o editor';

  @override
  String get bdfd_editor_title => 'Editor BDFD';

  @override
  String get bdfd_editor_toggle_indent => 'Alternar guias de recuo';

  @override
  String get bdfd_editor_ux_title => 'UX do Editor';

  @override
  String get bdfd_editor_wrap_toggle => 'Alternar quebra de linha';

  @override
  String get bdfd_runtime_execution_error =>
      'Ocorreu um erro ao executar este script BDFD.';

  @override
  String get bot_home_create_command => 'Criar o meu primeiro comando';

  @override
  String get bot_home_customize => 'Personalizar o meu bot';

  @override
  String get bot_home_delete => 'Eliminar App';

  @override
  String get bot_home_delete_confirm =>
      'Tem a certeza que deseja eliminar esta app?';

  @override
  String get bot_home_invite => 'Convidar Bot';

  @override
  String get bot_home_invite_error =>
      'NÃƒÂ£o foi possÃƒÂ­vel abrir o link de convite';

  @override
  String get bot_home_ios_notice_content =>
      'No modo local, o iOS pode suspender a app em segundo plano. O bot pode iniciar, mas manter a ligaÃƒÂ§ÃƒÂ£o ao Discord ativa nÃƒÂ£o ÃƒÂ© garantido como acontece com um Runner.';

  @override
  String get bot_home_ios_notice_title => 'RestriÃƒÂ§ÃƒÂ£o local do iOS';

  @override
  String get bot_home_log_desktop_stop =>
      'Paragem do bot de desktop solicitada';

  @override
  String get bot_home_log_start => 'Arranque do bot solicitado';

  @override
  String get bot_home_log_stop => 'Paragem do bot solicitada';

  @override
  String get bot_home_notif_required =>
      'A permissÃƒÂ£o de notificaÃƒÂ§ÃƒÂ£o ÃƒÂ© necessÃƒÂ¡ria para iniciar o serviÃƒÂ§o do bot.';

  @override
  String get bot_home_section_danger => 'ZONA DE PERIGO';

  @override
  String get bot_home_section_getting_started => 'INTRODUÃƒâ€¡ÃƒÆ’O';

  @override
  String get bot_home_section_monitoring => 'MONITORIZAÃƒâ€¡ÃƒÆ’O';

  @override
  String get bot_home_section_tools => 'FERRAMENTAS';

  @override
  String get bot_home_service_not_started =>
      'O serviÃƒÂ§o de primeiro plano nÃƒÂ£o iniciou.';

  @override
  String get bot_home_start => 'Iniciar Bot';

  @override
  String bot_home_start_error(String error) {
    return 'NÃƒÂ£o foi possÃƒÂ­vel iniciar: $error';
  }

  @override
  String get bot_home_starting => 'A iniciarÃ¢â‚¬Â¦';

  @override
  String get bot_home_stop => 'Parar Bot';

  @override
  String get bot_home_sync => 'Sincronizar App';

  @override
  String get bot_home_sync_success => 'App sincronizada com sucesso';

  @override
  String get bot_home_pull => 'Baixar da Nuvem';

  @override
  String get bot_home_push => 'Enviar para a Nuvem';

  @override
  String get bot_home_pull_success => 'App baixado da nuvem com sucesso';

  @override
  String get bot_home_push_success => 'App enviado para a nuvem com sucesso';

  @override
  String get bot_home_version_history => 'HistÃƒÂ³rico de VersÃƒÂµes';

  @override
  String get bot_config_versions_title => 'HistÃƒÂ³rico de VersÃƒÂµes';

  @override
  String get bot_config_versions_empty =>
      'Nenhuma versÃƒÂ£o anterior encontrada';

  @override
  String get bot_config_versions_restore => 'Restaurar';

  @override
  String get bot_config_versions_restore_confirm =>
      'Restaurar esta versÃƒÂ£o? Sua configuraÃƒÂ§ÃƒÂ£o atual serÃƒÂ¡ salva primeiro.';

  @override
  String get bot_config_versions_restored =>
      'ConfiguraÃƒÂ§ÃƒÂ£o restaurada com sucesso!';

  @override
  String get bot_config_versions_error => 'Falha ao carregar versÃƒÂµes';

  @override
  String get bot_config_versions_restore_error =>
      'Falha ao restaurar versÃƒÂ£o';

  @override
  String get bot_home_pull_dialog_changes => 'AlteraÃƒÂ§ÃƒÂµes a aplicar:';

  @override
  String get bot_home_pull_dialog_local => 'Local (Dispositivo)';

  @override
  String get bot_home_pull_dialog_local_only => 'apenas local (mantido)';

  @override
  String get bot_home_pull_dialog_local_preserved =>
      'Comando(s) local(is) ausente(s) da nuvem serÃƒÂ£o preservado(s).';

  @override
  String get bot_home_pull_dialog_new_commands => 'novo(s) comando(s)';

  @override
  String get bot_home_pull_dialog_remote => 'Remoto (Nuvem)';

  @override
  String get bot_home_pull_dialog_unchanged => 'inalterado(s)';

  @override
  String get bot_home_pull_dialog_up_to_date =>
      'JÃƒÂ¡ estÃƒÂ¡ atualizado Ã¢â‚¬â€ nenhuma alteraÃƒÂ§ÃƒÂ£o necessÃƒÂ¡ria.';

  @override
  String get bot_home_pull_dialog_updated_commands =>
      'comando(s) atualizado(s)';

  @override
  String get bot_home_push_refused_empty =>
      'Push recusado: configuraÃƒÂ§ÃƒÂ£o local vazia ou corrompida. Verifique seus comandos.';

  @override
  String get bot_home_token_invalid_content =>
      'O token parece ter sido redefinido. Por favor, forneÃƒÂ§a o novo token do Portal de Programadores do Discord. Deseja iniciar o bot de qualquer forma?';

  @override
  String get bot_home_token_invalid_title =>
      'O token parece ter sido redefinido';

  @override
  String get bot_home_view_logs => 'Ver registos do bot';

  @override
  String get bot_home_view_replay => 'Ver replays do depurador';

  @override
  String get bot_home_view_stats => 'Ver estatÃƒÂ­sticas do bot';

  @override
  String get bot_logs_copied => 'Logs copiados';

  @override
  String get bot_logs_disable_debug => 'Desativar logs de debug';

  @override
  String get bot_logs_empty => 'Ainda nÃƒÂ£o hÃƒÂ¡ logs';

  @override
  String get bot_logs_enable_debug => 'Ativar logs de debug';

  @override
  String get bot_logs_filter_count => 'NÃƒÂºmero de logs exibidos';

  @override
  String get bot_logs_go_to_bottom => 'Ir para o fim';

  @override
  String get bot_logs_go_to_latest => 'Ir para o log mais recente';

  @override
  String get bot_logs_newest_first => 'Mostrar mais recentes primeiro';

  @override
  String get bot_logs_oldest_first => 'Mostrar mais antigos primeiro';

  @override
  String bot_logs_ram(String memory) {
    return 'RAM do processo do bot: $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'RAM estimada do bot: $memory';
  }

  @override
  String get bot_logs_raw_mode => 'Logs brutos compactos';

  @override
  String get bot_logs_rich_mode => 'Logs formatados';

  @override
  String get bot_logs_show_all => 'Mostrar tudo';

  @override
  String get bot_logs_show_less => 'Mostrar menos';

  @override
  String get bot_logs_show_more => 'Mostrar mais';

  @override
  String bot_logs_show_n(int count) {
    return 'Mostrar $count logs';
  }

  @override
  String get bot_logs_title => 'Logs do Bot';

  @override
  String get bot_offline_token_desc =>
      'Token invÃƒÂ¡lido ou em falta. Introduza um novo token de bot do Discord para restaurar a ligaÃƒÂ§ÃƒÂ£o.';

  @override
  String get bot_settings_activity_state_label =>
      'Estado da atividade (opcional)';

  @override
  String get bot_settings_activity_url_label =>
      'URL da stream (para streaming)';

  @override
  String get bot_settings_add_status => 'Adicionar atividade';

  @override
  String get bot_settings_app_flags => 'Flags da AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get bot_settings_avatar_clear_selection => 'Limpar seleÃƒÂ§ÃƒÂ£o';

  @override
  String get bot_settings_avatar_important_note =>
      'Importante: As alteraÃƒÂ§ÃƒÂµes de perfil (nome de usuÃƒÂ¡rio e avatar) sÃƒÂ³ serÃƒÂ£o aplicadas no Discord quando vocÃƒÂª clicar em \'Salvar perfil e status\' na parte inferior.';

  @override
  String get bot_settings_avatar_local_path =>
      'Caminho do ficheiro local do avatar';

  @override
  String get bot_settings_avatar_none_selected =>
      'Nenhuma imagem selecionada. Clique em Procurar para escolher uma.';

  @override
  String get bot_settings_avatar_path_hint =>
      '/caminho/absoluto/para/avatar.png';

  @override
  String get bot_settings_avatar_preview_error =>
      'NÃƒÂ£o foi possÃƒÂ­vel prÃƒÂ©-visualizar a imagem';

  @override
  String get bot_settings_avatar_preview_label =>
      'PrÃƒÂ©-visualizaÃƒÂ§ÃƒÂ£o do avatar';

  @override
  String get bot_settings_avatar_selected => 'Imagem selecionada:';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Ficheiro selecionado: $path';
  }

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Formato de avatar nÃƒÂ£o suportado: $ext. Formatos suportados: $formats.';
  }

  @override
  String get bot_settings_browse => 'Procurar';

  @override
  String get bot_settings_cancel_token_edit_btn =>
      'Cancelar ediÃƒÂ§ÃƒÂ£o de token';

  @override
  String get bot_settings_danger_zone => 'Zona de Perigo';

  @override
  String get bot_settings_delete_bot => 'Excluir Bot';

  @override
  String get bot_settings_delete_bot_btn => 'Excluir Permanentemente';

  @override
  String get bot_settings_delete_bot_desc =>
      'Esta aÃƒÂ§ÃƒÂ£o ÃƒÂ© irreversÃƒÂ­vel. Todos os dados locais e configuraÃƒÂ§ÃƒÂµes remotas serÃƒÂ£o removidos permanentemente.';

  @override
  String bot_settings_delete_desc(String id) {
    return 'Tem certeza de que deseja excluir o bot $id? Todos os dados serÃƒÂ£o perdidos.';
  }

  @override
  String get bot_settings_delete_title => 'Confirmar ExclusÃƒÂ£o';

  @override
  String get bot_settings_edit_token_btn => 'Editar token';

  @override
  String get bot_settings_export_import => 'Exportar / Importar';

  @override
  String get bot_settings_export_import_desc =>
      'Exporte ou importe a configuraÃƒÂ§ÃƒÂ£o do seu bot como um ficheiro ZIP.';

  @override
  String get bot_settings_gateway_intents =>
      'ConfiguraÃƒÂ§ÃƒÂ£o de Gateway Intents';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Selecione quais os intents que o seu bot precisa. Configure-os no Portal de Programadores do Discord.';

  @override
  String get bot_settings_intents_saved => 'Intents guardados com sucesso';

  @override
  String get bot_settings_lavalink_choose_server =>
      'Escolher um servidor pÃƒÂºblico...';

  @override
  String get bot_settings_lavalink_host => 'Host';

  @override
  String get bot_settings_lavalink_host_hint =>
      'localhost ou IP do servidor Lavalink';

  @override
  String get bot_settings_lavalink_password => 'Palavra-passe';

  @override
  String get bot_settings_lavalink_password_hint => 'youshallnotpass';

  @override
  String get bot_settings_lavalink_port => 'Porta';

  @override
  String get bot_settings_lavalink_port_hint => '2333';

  @override
  String get bot_settings_lavalink_premium_banner_desc =>
      'Desbloqueie o suporte de ÃƒÂ¡udio Lavalink para o seu bot.';

  @override
  String get bot_settings_lavalink_premium_banner_title =>
      'Ã°Å¸â€â€™ DisponÃƒÂ­vel com Bot Creator PREMIUM';

  @override
  String get bot_settings_lavalink_public_servers => 'Servidores pÃƒÂºblicos';

  @override
  String get bot_settings_lavalink_save_btn => 'Guardar';

  @override
  String get bot_settings_lavalink_save_caption =>
      'Guarde esta configuraÃƒÂ§ÃƒÂ£o para que o bot se possa ligar ao servidor Lavalink.';

  @override
  String get bot_settings_lavalink_section_title => 'Servidor Lavalink';

  @override
  String get bot_settings_lavalink_server_picker_title =>
      'Servidores Lavalink pÃƒÂºblicos';

  @override
  String bot_settings_lavalink_server_subtitle(String port, String version) {
    return 'Porta $port Ã¢â‚¬â€ $version';
  }

  @override
  String bot_settings_lavalink_servers_available(int count) {
    return '$count servidores disponÃƒÂ­veis';
  }

  @override
  String get bot_settings_lavalink_ssl => 'Usar SSL/TLS';

  @override
  String get bot_settings_lavalink_ssl_subtitle =>
      'LigaÃƒÂ§ÃƒÂ£o segura wss://';

  @override
  String get bot_settings_lavalink_success => 'LigaÃƒÂ§ÃƒÂ£o bem-sucedida!';

  @override
  String get bot_settings_lavalink_test_btn => 'Testar ligaÃƒÂ§ÃƒÂ£o';

  @override
  String get bot_settings_lavalink_testing => 'A testar...';

  @override
  String get bot_settings_lavalink_view_offers => 'Ver ofertas';

  @override
  String get bot_settings_no_activities => 'Nenhuma atividade configurada';

  @override
  String get bot_settings_presence_dnd => 'NÃƒÂ£o Perturbar';

  @override
  String get bot_settings_presence_idle => 'Ausente';

  @override
  String get bot_settings_presence_invisible => 'InvisÃƒÂ­vel';

  @override
  String get bot_settings_presence_online => 'Online';

  @override
  String get bot_settings_presence_status_label => 'PresenÃƒÂ§a';

  @override
  String get bot_settings_presence_status_title =>
      'Estado de PresenÃƒÂ§a do Bot';

  @override
  String get bot_settings_profile_saved =>
      'Perfil/estados aplicados com sucesso';

  @override
  String get bot_settings_profile_title => 'Perfil do Bot';

  @override
  String get bot_settings_remove_status => 'Remover atividade';

  @override
  String get bot_settings_save_intents_btn => 'Guardar intents';

  @override
  String get bot_settings_save_intents_caption =>
      'Isto apenas atualiza a configuraÃƒÂ§ÃƒÂ£o de gateway intents.';

  @override
  String get bot_settings_save_profile_caption =>
      'Isto aplica o nome de utilizador/avatar instantaneamente e guarda a rotaÃƒÂ§ÃƒÂ£o de estados.';

  @override
  String get bot_settings_save_profile_status_btn => 'Guardar perfil e estados';

  @override
  String get bot_settings_save_success =>
      'DefiniÃƒÂ§ÃƒÂµes guardadas com sucesso';

  @override
  String get bot_settings_save_token_btn => 'Guardar token e intents';

  @override
  String get bot_settings_save_token_caption =>
      'AlteraÃƒÂ§ÃƒÂµes de token estÃƒÂ£o protegidas. Clique primeiro em \"Editar token\", depois guarde.';

  @override
  String get bot_settings_save_token_first =>
      'Por favor, guarde primeiro o token antes de aplicar alteraÃƒÂ§ÃƒÂµes de perfil/estado.';

  @override
  String get bot_settings_save_token_only_btn => 'Guardar token';

  @override
  String bot_settings_status_item_title(int index) {
    return 'Atividade $index';
  }

  @override
  String get bot_settings_status_max_interval => 'Intervalo mÃƒÂ¡x (s)';

  @override
  String get bot_settings_status_min_interval => 'Intervalo mÃƒÂ­n (s)';

  @override
  String get bot_settings_status_rotation_desc =>
      'Adicione uma ou mais atividades. Cada atividade precisa de um tipo, nome e intervalo mÃƒÂ­n/mÃƒÂ¡x (segundos).';

  @override
  String get bot_settings_status_rotation_title =>
      'RotaÃƒÂ§ÃƒÂ£o de Atividades';

  @override
  String get bot_settings_status_text_label => 'Nome da atividade';

  @override
  String get bot_settings_status_type_competing => 'A competir';

  @override
  String get bot_settings_status_type_label => 'Tipo';

  @override
  String get bot_settings_status_type_listening => 'A ouvir';

  @override
  String get bot_settings_status_type_playing => 'A jogar';

  @override
  String get bot_settings_status_type_streaming => 'A transmitir';

  @override
  String get bot_settings_status_type_watching => 'A ver';

  @override
  String get bot_settings_tab_advanced => 'AvanÃƒÂ§ado & ManutenÃƒÂ§ÃƒÂ£o';

  @override
  String get bot_settings_tab_general => 'Geral';

  @override
  String get bot_settings_tab_intents => 'Intents & PrivilÃƒÂ©gios';

  @override
  String get bot_settings_tab_lavalink => 'Lavalink';

  @override
  String get bot_settings_tab_presence => 'PresenÃƒÂ§a & Status';

  @override
  String get bot_settings_title => 'Personalizar Bot / Perfil';

  @override
  String get bot_settings_token_hidden_desc =>
      'A entrada de token estÃƒÂ¡ oculta por padrÃƒÂ£o por seguranÃƒÂ§a.';

  @override
  String get bot_settings_token_hint => 'Introduza o token do seu bot aqui';

  @override
  String get bot_settings_token_mismatch_confirm =>
      'Substituir token de qualquer forma';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Este token pertence ao bot $newId, mas os dados atuais sÃƒÂ£o para o bot $oldId. Comandos e definiÃƒÂ§ÃƒÂµes podem nÃƒÂ£o corresponder. Continuar de qualquer forma?';
  }

  @override
  String get bot_settings_token_mismatch_title => 'Diferente bot detetado';

  @override
  String get bot_settings_token_required =>
      'O token do bot ÃƒÂ© obrigatÃƒÂ³rio.';

  @override
  String get bot_settings_token_saved => 'Token guardado com sucesso';

  @override
  String get bot_settings_token_title => 'Token do Bot';

  @override
  String get bot_settings_update_token => 'Atualizar Token do Bot';

  @override
  String get bot_settings_username_hint =>
      'Deixe vazio para manter o nome atual';

  @override
  String get bot_settings_username_override =>
      'SubstituiÃƒÂ§ÃƒÂ£o de nome de utilizador';

  @override
  String get bot_settings_workflow_docs => 'Centro de DocumentaÃƒÂ§ÃƒÂ£o';

  @override
  String get bot_settings_workflow_docs_desc =>
      'DocumentaÃƒÂ§ÃƒÂ£o centralizada para comandos, fluxos de trabalho, variÃƒÂ¡veis de runtime e comportamento de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get bot_stats_collecting => 'A recolherÃ¢â‚¬Â¦';

  @override
  String get bot_stats_cpu => 'CPU do processo do Bot';

  @override
  String get bot_stats_notes =>
      'Notas: CPU disponÃƒÂ­vel em Android/Linux. Armazenamento = ficheiros de dados do bot na app.';

  @override
  String get bot_stats_ram_estimated => 'RAM apenas do Bot (estimada)';

  @override
  String get bot_stats_ram_process => 'RAM do processo do Bot';

  @override
  String get bot_stats_source_local_hosting => 'Origem: Alojamento Local';

  @override
  String get bot_stats_source_runner_api => 'Origem: Runner API';

  @override
  String get bot_stats_storage => 'Armazenamento do Bot (dados da app)';

  @override
  String get bot_stats_title => 'EstatÃƒÂ­sticas do Bot';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Escreva \$ e comece a escrever o nome de uma funÃƒÂ§ÃƒÂ£o para obter sugestÃƒÂµes rÃƒÂ¡pidas.';

  @override
  String get cmd_bdfd_autocomplete_title => 'Autocompletar prefixo BDFD';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Nenhum problema detetado no script atual.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Erro';

  @override
  String get cmd_bdfd_diagnostics_title => 'DiagnÃƒÂ³sticos BDFD';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Aviso';

  @override
  String get cmd_bdfd_script_empty_error =>
      'O corpo do script BDFD nÃƒÂ£o pode estar vazio.';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nOlÃƒÂ¡ do Bot Creator';

  @override
  String get cmd_bdfd_script_label => 'Corpo do script BDFD';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Este script BDFD ainda contÃƒÂ©m diagnÃƒÂ³sticos:';

  @override
  String get cmd_create_tooltip => 'Criar comando';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Nenhum problema detetado no script Dart atual.';

  @override
  String get cmd_dart_diagnostics_error => 'Erro';

  @override
  String get cmd_dart_diagnostics_title => 'DiagnÃƒÂ³sticos Dart';

  @override
  String get cmd_dart_diagnostics_warning => 'Aviso';

  @override
  String get cmd_dart_script_hint => 'return \"OlÃƒÂ¡ do Dart Direto\";';

  @override
  String get cmd_dart_script_label => 'Corpo do script Dart';

  @override
  String cmd_batch_delete_confirm(int count) {
    return 'Excluir $count comandos?';
  }

  @override
  String cmd_batch_delete_success(Object count) {
    return '$count comandos excluÃƒÂ­dos';
  }

  @override
  String cmd_delete_confirm(Object name) {
    return 'Excluir comando \"$name\"?';
  }

  @override
  String cmd_delete_success(Object name) {
    return 'Comando \"$name\" excluÃƒÂ­do';
  }

  @override
  String get cmd_delete_tooltip => 'Apagar comando';

  @override
  String get cmd_deploy_close_button => 'Fechar';

  @override
  String get cmd_deploy_cloud_sync_subtitle =>
      'SincronizaÃƒÂ§ÃƒÂ£o segura com o seu espaÃƒÂ§o online';

  @override
  String get cmd_deploy_cloud_sync_title => 'Backup na Nuvem';

  @override
  String cmd_deploy_config_subtitle(String name) {
    return 'ConfiguraÃƒÂ§ÃƒÂ£o de /$name';
  }

  @override
  String get cmd_deploy_discord_sync_subtitle =>
      'Publicando comando na API do Discord';

  @override
  String get cmd_deploy_discord_sync_title => 'SincronizaÃƒÂ§ÃƒÂ£o com Discord';

  @override
  String get cmd_deploy_failed_title => 'Falha na implantaÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_deploy_hot_reload_subtitle =>
      'AtualizaÃƒÂ§ÃƒÂ£o instantÃƒÂ¢nea do runner do seu bot';

  @override
  String get cmd_deploy_hot_reload_title => 'Recarregamento RÃƒÂ¡pido';

  @override
  String get cmd_deploy_in_progress_title =>
      'ImplantaÃƒÂ§ÃƒÂ£o em andamento...';

  @override
  String get cmd_deploy_local_save_subtitle =>
      'Salvando comando no dispositivo';

  @override
  String get cmd_deploy_local_save_title => 'Salvamento Local';

  @override
  String get cmd_deploy_reload_bot_subtitle =>
      'Aplicando configuraÃƒÂ§ÃƒÂ£o de hot-reload';

  @override
  String get cmd_deploy_reload_bot_title => 'Recarregando Bot';

  @override
  String get cmd_deploy_retry_button => 'Tentar Novamente';

  @override
  String get cmd_deploy_success_title => 'ImplantaÃƒÂ§ÃƒÂ£o bem-sucedida!';

  @override
  String cmd_deploy_success_toast(String name) {
    return 'Comando \"$name\" implantado e ativo!';
  }

  @override
  String get cmd_editor_mode_advanced => 'Modo avanÃƒÂ§ado';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Editor completo com resposta personalizada, opÃƒÂ§ÃƒÂµes e construtor de aÃƒÂ§ÃƒÂµes.';

  @override
  String get cmd_editor_mode_locked =>
      'O modo avanÃƒÂ§ado estÃƒÂ¡ bloqueado para este comando.';

  @override
  String get cmd_editor_mode_simple => 'Modo simplificado';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Construa um comando rapidamente com opÃƒÂ§ÃƒÂµes guiadas e aÃƒÂ§ÃƒÂµes prÃƒÂ©-configuradas.';

  @override
  String get cmd_editor_mode_switch_adv => 'Mudar para modo avanÃƒÂ§ado';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Mudar';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Esta mudanÃƒÂ§a ÃƒÂ© permanente para este comando. NÃƒÂ£o poderÃƒÂ¡ voltar ao modo simplificado.';

  @override
  String get cmd_editor_mode_switch_adv_title => 'Mudar para modo avanÃƒÂ§ado?';

  @override
  String get cmd_editor_mode_title => 'Modo de ediÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_error_fill_fields => 'Por favor, preencha todos os campos';

  @override
  String get cmd_execution_mode_bdfd => 'Modo Script BDFD';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Escreva o corpo do comando como um script estilo BDFD enquanto mantÃƒÂ©m a definiÃƒÂ§ÃƒÂ£o do comando visual.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'O script ÃƒÂ© compilado para aÃƒÂ§ÃƒÂµes internas. DiagnÃƒÂ³sticos sÃƒÂ£o mostrados durante a ediÃƒÂ§ÃƒÂ£o; scripts invÃƒÂ¡lidos falham quando o comando ÃƒÂ© executado.';

  @override
  String get cmd_execution_mode_dart => 'Modo Dart Direto';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Escreva o corpo do comando diretamente em Dart com diagnÃƒÂ³sticos em tempo de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get cmd_execution_mode_dart_note =>
      'O cÃƒÂ³digo Dart ÃƒÂ© compilado em execuÃƒÂ§ÃƒÂ£o atravÃƒÂ©s do motor sandbox. Mantenha os scripts determinÃƒÂ­sticos e retorne um valor quando necessÃƒÂ¡rio.';

  @override
  String get cmd_execution_mode_javascript => 'JavaScript';

  @override
  String get cmd_execution_mode_javascript_desc =>
      'Escreva cÃƒÂ³digo JS personalizado para este comando.';

  @override
  String get cmd_execution_mode_javascript_note =>
      'Todas as funÃƒÂ§ÃƒÂµes BDFD estÃƒÂ£o disponÃƒÂ­veis como funÃƒÂ§ÃƒÂµes JS assÃƒÂ­ncronas. Use ctx.authorId, ctx.channelId, vars[\'key\'] para acessar contexto e variÃƒÂ¡veis.';

  @override
  String get cmd_execution_mode_desc =>
      'Os metadados do comando ficam no construtor visual. Escolha como o corpo do comando deve ser executado.';

  @override
  String get cmd_execution_mode_title => 'Modo de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_execution_mode_workflow => 'Modo Workflow';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Use a resposta visual existente e o construtor de aÃƒÂ§ÃƒÂµes.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'O modo Workflow ÃƒÂ© o caminho de produÃƒÂ§ÃƒÂ£o atual e continua totalmente suportado.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrar';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Gere um esqueleto de migraÃƒÂ§ÃƒÂ£o Dart a partir do seu script BDFD atual.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Este comando nÃƒÂ£o pÃƒÂ´de ser totalmente carregado (offline ou token invÃƒÂ¡lido). Ligue um token vÃƒÂ¡lido para editar.';

  @override
  String get cmd_show_variables => 'Abrir documentaÃƒÂ§ÃƒÂ£o de variÃƒÂ¡veis';

  @override
  String get cmd_simple_action_add_role => 'Adicionar cargo';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Dar o /cargo selecionado ao /utilizador selecionado.';

  @override
  String get cmd_simple_action_ban => 'Banir utilizador';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      '0 a 7 dias de mensagens recentes a apagar';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Dias de mensagens a apagar ao banir';

  @override
  String get cmd_simple_action_ban_desc =>
      'Banir o /utilizador selecionado do servidor.';

  @override
  String get cmd_simple_action_create_invite => 'Criar convite';

  @override
  String get cmd_simple_action_create_invite_desc =>
      'Criar um convite para o canal atual ou um /canal opcional.';

  @override
  String get cmd_simple_action_create_poll => 'Criar sondagem';

  @override
  String get cmd_simple_action_create_poll_desc =>
      'Criar uma sondagem com uma /pergunta dinÃƒÂ¢mica e escolhas de resposta fixas.';

  @override
  String get cmd_simple_action_delete => 'Apagar mensagens';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'Usada quando /contagem nÃƒÂ£o ÃƒÂ© fornecida';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Contagem padrÃƒÂ£o de eliminaÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_simple_action_delete_desc =>
      'Apagar mensagens no canal atual (opcional /contagem).';

  @override
  String get cmd_simple_action_kick => 'Expulsar utilizador';

  @override
  String get cmd_simple_action_kick_desc =>
      'Expulsar o /utilizador selecionado do servidor.';

  @override
  String get cmd_simple_action_mute => 'Silenciar utilizador';

  @override
  String get cmd_simple_action_mute_desc =>
      'Silenciar temporariamente o /utilizador selecionado.';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Exemplos: 10m, 2h, 1d, ou segundos brutos';

  @override
  String get cmd_simple_action_mute_duration_label =>
      'DuraÃƒÂ§ÃƒÂ£o do silenciamento';

  @override
  String get cmd_simple_action_pin => 'Fixar mensagem';

  @override
  String get cmd_simple_action_pin_desc =>
      'Fixar uma mensagem no canal atual usando /id_mensagem.';

  @override
  String get cmd_simple_action_reason_hint =>
      'RazÃƒÂ£o opcional partilhada pelas aÃƒÂ§ÃƒÂµes de moderaÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_simple_action_reason_label => 'RazÃƒÂ£o do log de auditoria';

  @override
  String get cmd_simple_action_remove_role => 'Remover cargo';

  @override
  String get cmd_simple_action_remove_role_desc =>
      'Remover o /cargo selecionado do /utilizador selecionado.';

  @override
  String get cmd_simple_action_send_message => 'Enviar mensagem';

  @override
  String get cmd_simple_action_send_message_desc =>
      'Enviar uma mensagem adicional no canal atual.';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Mensagem enviada pela aÃƒÂ§ÃƒÂ£o Enviar Mensagem';

  @override
  String get cmd_simple_action_send_message_label => 'Mensagem da aÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_simple_action_unban => 'Desbanir utilizador';

  @override
  String get cmd_simple_action_unban_desc =>
      'Desbanir um utilizador com um ID de /utilizador fornecido.';

  @override
  String get cmd_simple_action_unmute => 'Dessilenciar utilizador';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Remover o castigo do /utilizador selecionado.';

  @override
  String get cmd_simple_action_unpin => 'Desafixar mensagem';

  @override
  String get cmd_simple_action_unpin_desc =>
      'Desafixar uma mensagem no canal atual usando /id_mensagem.';

  @override
  String get cmd_simple_actions_desc =>
      'Selecione o que este comando deve fazer. As opÃƒÂ§ÃƒÂµes sÃƒÂ£o geradas automaticamente.';

  @override
  String get cmd_simple_actions_title => 'AÃƒÂ§ÃƒÂµes simplificadas';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Banir utilizador e Desbanir utilizador nÃƒÂ£o podem ser ativados juntos no modo simplificado.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Silenciar utilizador e Dessilenciar utilizador nÃƒÂ£o podem ser ativados juntos no modo simplificado.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Fixar mensagem e Desafixar mensagem nÃƒÂ£o podem ser ativados juntos no modo simplificado.';

  @override
  String get cmd_simple_execution_desc =>
      'Ajuste fino das aÃƒÂ§ÃƒÂµes geradas sem sair do modo simplificado.';

  @override
  String get cmd_simple_execution_title => 'DefiniÃƒÂ§ÃƒÂµes de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_simple_generated_none =>
      'Nenhuma opÃƒÂ§ÃƒÂ£o gerada ainda. Selecione pelo menos uma aÃƒÂ§ÃƒÂ£o.';

  @override
  String get cmd_simple_generated_options => 'OpÃƒÂ§ÃƒÂµes de comando geradas';

  @override
  String get cmd_simple_group_messages_desc =>
      'AÃƒÂ§ÃƒÂµes de mensagens e canais que funcionam no contexto atual.';

  @override
  String get cmd_simple_group_messages_title => 'Mensagens';

  @override
  String get cmd_simple_group_moderation_desc =>
      'AÃƒÂ§ÃƒÂµes de membros e moderaÃƒÂ§ÃƒÂ£o com opÃƒÂ§ÃƒÂµes guiadas.';

  @override
  String get cmd_simple_group_moderation_title => 'ModeraÃƒÂ§ÃƒÂ£o';

  @override
  String get cmd_simple_group_utility_desc =>
      'Extras ÃƒÂºteis como convites e sondagens.';

  @override
  String get cmd_simple_group_utility_title => 'Utilidade';

  @override
  String get cmd_simple_invite_max_age_hint =>
      '0 para nÃƒÂ£o expirar, atÃƒÂ© 604800';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'A expiraÃƒÂ§ÃƒÂ£o do convite deve ser um nÃƒÂºmero entre 0 e 604800 segundos.';

  @override
  String get cmd_simple_invite_max_age_label =>
      'ExpiraÃƒÂ§ÃƒÂ£o do convite (segundos)';

  @override
  String get cmd_simple_invite_max_uses_hint => '0 para usos ilimitados';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'O mÃƒÂ¡ximo de usos do convite deve ser um nÃƒÂºmero entre 0 e 1000000.';

  @override
  String get cmd_simple_invite_max_uses_label => 'MÃƒÂ¡ximo de usos';

  @override
  String get cmd_simple_invite_settings_desc =>
      'PadrÃƒÂµes usados pela aÃƒÂ§ÃƒÂ£o Criar Convite gerada.';

  @override
  String get cmd_simple_invite_settings_title => 'DefiniÃƒÂ§ÃƒÂµes de convite';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Os membros sÃƒÂ£o removidos se saÃƒÂ­rem antes de obter um cargo.';

  @override
  String get cmd_simple_invite_temporary_label =>
      'AssociaÃƒÂ§ÃƒÂ£o temporÃƒÂ¡ria';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Criar sempre um novo convite em vez de reutilizar um existente.';

  @override
  String get cmd_simple_invite_unique_label => 'ForÃƒÂ§ar convite ÃƒÂºnico';

  @override
  String get cmd_simple_option_channel => '/canal (Canal)';

  @override
  String get cmd_simple_option_channel_desc =>
      'SubstituiÃƒÂ§ÃƒÂ£o opcional de canal para criaÃƒÂ§ÃƒÂ£o de convite';

  @override
  String get cmd_simple_option_count => '/contagem (Inteiro)';

  @override
  String get cmd_simple_option_count_desc => 'NÃƒÂºmero de mensagens a apagar';

  @override
  String get cmd_simple_option_message_id => '/id_mensagem (Texto)';

  @override
  String get cmd_simple_option_message_id_desc => 'ID da mensagem alvo';

  @override
  String get cmd_simple_option_question => '/pergunta (Texto)';

  @override
  String get cmd_simple_option_question_desc => 'Pergunta da sondagem';

  @override
  String get cmd_simple_option_role => '/cargo (Cargo)';

  @override
  String get cmd_simple_option_role_desc => 'Cargo alvo';

  @override
  String get cmd_simple_option_user => '/utilizador (Utilizador)';

  @override
  String get cmd_simple_option_user_desc => 'Utilizador alvo';

  @override
  String get cmd_simple_option_user_id => '/id_utilizador (Texto)';

  @override
  String get cmd_simple_option_user_id_desc => 'ID do utilizador a desbanir';

  @override
  String get cmd_simple_poll_answers_hint =>
      'Uma resposta por linha, ou use vÃƒÂ­rgulas. MÃƒÂ­nimo 2, mÃƒÂ¡ximo 10.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'As respostas da sondagem devem conter entre 2 e 10 escolhas nÃƒÂ£o vazias.';

  @override
  String get cmd_simple_poll_answers_label => 'Respostas da sondagem';

  @override
  String get cmd_simple_poll_duration_hint => 'De 1 a 168 horas';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'A duraÃƒÂ§ÃƒÂ£o da sondagem deve ser um nÃƒÂºmero entre 1 e 168 horas.';

  @override
  String get cmd_simple_poll_duration_label =>
      'DuraÃƒÂ§ÃƒÂ£o da sondagem (horas)';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Os utilizadores podem selecionar mais do que uma escolha.';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Permitir mÃƒÂºltiplas respostas';

  @override
  String get cmd_simple_poll_settings_desc =>
      'PadrÃƒÂµes usados pela aÃƒÂ§ÃƒÂ£o Criar Sondagem gerada.';

  @override
  String get cmd_simple_poll_settings_title => 'DefiniÃƒÂ§ÃƒÂµes de sondagem';

  @override
  String get cmd_simple_response_desc =>
      'Mensagem enviada de volta ao utilizador apÃƒÂ³s as aÃƒÂ§ÃƒÂµes serem executadas.';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Embeds opcionais enviados com a resposta final.';

  @override
  String get cmd_simple_response_embeds_title => 'Embeds da resposta';

  @override
  String get cmd_simple_response_hint => 'ConcluÃƒÂ­do Ã¢Å“â€¦';

  @override
  String get cmd_simple_response_title => 'Resposta final';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'EfÃƒÂ©mero';

  @override
  String get cmd_simple_response_visibility_label => 'Visibilidade da resposta';

  @override
  String get cmd_simple_response_visibility_public => 'PÃƒÂºblico';

  @override
  String get cmd_simple_send_message_required =>
      'Por favor, preencha a mensagem da aÃƒÂ§ÃƒÂ£o antes de guardar.';

  @override
  String get cmd_variables_title => 'VariÃƒÂ¡veis de Comando';

  @override
  String get command_awaited_error => 'Erro';

  @override
  String get command_awaited_filter_hint =>
      'Exemplo: <numeric> ou <yes/no/cancel>';

  @override
  String get command_awaited_filter_label => 'Filtro (opcional)';

  @override
  String get command_awaited_name_hint => 'Exemplo: falar';

  @override
  String get command_awaited_name_label =>
      'Nome do retorno de chamada aguardado';

  @override
  String get command_awaited_preset_active =>
      'PredefiniÃƒÂ§ÃƒÂ£o de retorno de chamada aguardado ativa';

  @override
  String get command_awaited_preset_button =>
      'Usar PredefiniÃƒÂ§ÃƒÂ£o de Retorno de Chamada Aguardado';

  @override
  String get command_awaited_preset_desc =>
      'O nome do comando ÃƒÂ© gerado para vocÃƒÂª e salvo como um retorno de chamada legado interno.';

  @override
  String get command_awaited_success => 'Sucesso';

  @override
  String get command_context_bot_dm => 'DM do Bot';

  @override
  String get command_context_group_dm => 'DM de Grupo / Outro';

  @override
  String get command_context_guild => 'Servidor';

  @override
  String get command_description_length =>
      'A descriÃƒÂ§ÃƒÂ£o do comando deve ter no mÃƒÂ¡ximo 100 caracteres';

  @override
  String get command_description_required =>
      'Por favor, insira uma descriÃƒÂ§ÃƒÂ£o para o comando';

  @override
  String get command_edit_raw_name => 'Editar Nome Bruto';

  @override
  String get command_error_missing_bot_id =>
      'ID do bot ausente para salvamento de comando local.';

  @override
  String get command_execution_error =>
      'Ocorreu um erro ao executar este comando.';

  @override
  String get command_export_tooltip => 'Exportar payload do comando';

  @override
  String get command_import_tooltip => 'Importar payload do comando';

  @override
  String get command_info_desc => 'Metadados bÃƒÂ¡sicos e disponibilidade';

  @override
  String get command_info_title => 'InformaÃƒÂ§ÃƒÂµes do Comando';

  @override
  String get command_integration_guild => 'InstalaÃƒÂ§ÃƒÂ£o em Servidor';

  @override
  String get command_integration_label => 'Onde este comando pode ser usado';

  @override
  String get command_integration_user => 'InstalaÃƒÂ§ÃƒÂ£o em UsuÃƒÂ¡rio';

  @override
  String get command_legacy_mode_subtitle =>
      'Usa opÃƒÂ§ÃƒÂµes posicionais (exemplo: !config #canal).';

  @override
  String get command_legacy_mode_title => 'Ativar modo legado neste comando';

  @override
  String get command_legacy_prefix_desc =>
      'Lida com comandos de messageCreate usando <prefixo><comando>.';

  @override
  String get command_legacy_prefix_title => 'Modo de Prefixo Legado';

  @override
  String get command_legacy_preset_desc =>
      'Gere um gatilho de retorno de chamada aguardado interno e mude este comando para a configuraÃƒÂ§ÃƒÂ£o legada local obrigatÃƒÂ³ria.';

  @override
  String get command_legacy_preset_title => 'PredefiniÃƒÂ§ÃƒÂ£o legada';

  @override
  String get command_legacy_response_label => 'Modo de resposta legado';

  @override
  String get command_modal_disabled_legacy =>
      'Modais estÃƒÂ£o desativados no modo legado.';

  @override
  String get command_name_generated =>
      'Gerado pela predefiniÃƒÂ§ÃƒÂ£o de retorno de chamada aguardado.';

  @override
  String get command_name_label => 'Nome';

  @override
  String get command_not_found => 'Comando nÃƒÂ£o encontrado';

  @override
  String get command_options_legacy_params =>
      'ParÃƒÂ¢metros posicionais legados (ordenados: obrigatÃƒÂ³rios, depois opcionais)';

  @override
  String get command_options_slash_params =>
      'ParÃƒÂ¢metros do comando de barra';

  @override
  String get command_options_title => 'OpÃƒÂ§ÃƒÂµes do Comando';

  @override
  String get command_payload_hint => 'Payload do comando';

  @override
  String get command_permissions_admin_warning =>
      'Administrador selecionado: isso ignora outras verificaÃƒÂ§ÃƒÂµes de permissÃƒÂ£o.';

  @override
  String get command_permissions_bitfield =>
      'Bitfield de permissÃƒÂ£o calculado';

  @override
  String get command_permissions_bitfield_helper =>
      'Calculado automaticamente a partir das permissÃƒÂµes selecionadas.';

  @override
  String command_permissions_count(int count) {
    return '$count permissÃƒÂ£o(ÃƒÂµes) selecionada(s)';
  }

  @override
  String get command_permissions_label =>
      'PermissÃƒÂµes padrÃƒÂ£o de membros (opcional)';

  @override
  String get command_permissions_none =>
      'Nenhuma seleÃƒÂ§ÃƒÂ£o (todos podem usar o comando)';

  @override
  String get command_permissions_tip =>
      'Dica: deixe todos desmarcados para tornar o comando disponÃƒÂ­vel para todos por padrÃƒÂ£o.';

  @override
  String get command_permissions_title => 'Selecionar permissÃƒÂµes';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Aviso: bits de permissÃƒÂ£o desconhecidos detectados nos dados salvos e preservados: $bits';
  }

  @override
  String get command_prefix_helper =>
      'Suporta modelos e variÃƒÂ¡veis de escopo (bc_ opcional). Exemplo: ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint =>
      'Exemplo: ? ou ((guild.prefix | !))';

  @override
  String get command_prefix_override_label =>
      'SubstituiÃƒÂ§ÃƒÂ£o de prefixo (opcional)';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_scope_label => 'Escopo do comando (Contextos)';

  @override
  String get command_subcommand_workflow_desc =>
      'Escolha qual subcomando vocÃƒÂª estÃƒÂ¡ configurando.';

  @override
  String get command_subcommand_workflow_title => 'Workflow de Subcomando';

  @override
  String command_sync_failed_local(String error) {
    return 'Salvo localmente. Falha na sincronizaÃƒÂ§ÃƒÂ£o com o Discord: $error';
  }

  @override
  String get command_target_subcommand => 'Subcomando alvo';

  @override
  String get command_type_label => 'Tipo de Comando';

  @override
  String get command_type_legacy => 'Comando Legado';

  @override
  String get command_type_locked =>
      'O tipo de comando nÃƒÂ£o pode ser alterado apÃƒÂ³s a criaÃƒÂ§ÃƒÂ£o.';

  @override
  String get command_type_message => 'Comando de Mensagem';

  @override
  String get command_type_slash => 'Comando de Barra';

  @override
  String get command_type_user => 'Comando de UsuÃƒÂ¡rio';

  @override
  String get command_unsaved_confirm =>
      'VocÃƒÂª tem alteraÃƒÂ§ÃƒÂµes nÃƒÂ£o salvas. DescartÃƒÂ¡-las?';

  @override
  String get command_unsaved_keep => 'Continuar editando';

  @override
  String get command_unsaved_title => 'AlteraÃƒÂ§ÃƒÂµes nÃƒÂ£o salvas';

  @override
  String get commands_all_folders => 'Todas as pastas';

  @override
  String get commands_create_button => 'Criar comando';

  @override
  String get commands_create_folder => 'Criar pasta';

  @override
  String commands_create_from_query(String query) {
    return 'Criar comando \"$query\"';
  }

  @override
  String get commands_delete_folder => 'Apagar pasta';

  @override
  String get commands_delete_folder_desc =>
      'Os comandos dentro desta pasta nÃƒÂ£o serÃƒÂ£o apagados, apenas removidos da pasta.';

  @override
  String get commands_empty => 'Nenhum comando encontrado';

  @override
  String commands_error(String error) {
    return 'Erro: $error';
  }

  @override
  String get commands_filter_legacy_local => 'Legado local';

  @override
  String get commands_filter_template => 'Modelo';

  @override
  String get commands_filter_type_label => 'Tipo';

  @override
  String get commands_folder_hint => 'Nome da pasta opcional';

  @override
  String get commands_folder_label => 'Pasta';

  @override
  String get commands_move_to_folder => 'Mover para pasta';

  @override
  String get commands_new_folder_hint => 'Nome da nova pasta';

  @override
  String get commands_no_folder => 'Sem pasta';

  @override
  String get commands_no_match_filters =>
      'Nenhum comando corresponde aos filtros atuais.';

  @override
  String get commands_remove_from_folder => 'Remover da pasta';

  @override
  String get commands_rename_folder => 'Renomear pasta';

  @override
  String get commands_reorder_title => 'Organizar comandos';

  @override
  String get commands_search_hint => 'Pesquisar comandos...';

  @override
  String get commands_tab => 'Comandos';

  @override
  String get commands_tab_short => 'Cmd';

  @override
  String get commands_title => 'Comandos';

  @override
  String get common_add_argument => 'Adicionar Argumento';

  @override
  String get common_add_option => 'Adicionar OpÃƒÂ§ÃƒÂ£o';

  @override
  String get common_add_section => 'Adicionar SeÃƒÂ§ÃƒÂ£o';

  @override
  String get common_all => 'Todos';

  @override
  String get common_apply => 'Aplicar';

  @override
  String get common_back => 'Voltar';

  @override
  String get common_bot => 'Bot';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_clear => 'Limpar';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_custom_id => 'ID Personalizado';

  @override
  String get common_custom_id_required => 'ID Personalizado *';

  @override
  String get common_default => 'PadrÃƒÂ£o';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_description => 'DescriÃƒÂ§ÃƒÂ£o';

  @override
  String get common_disabled => 'Desativado';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_enabled => 'Ativado';

  @override
  String get common_import => 'Importar';

  @override
  String get common_key => 'Chave';

  @override
  String get common_label => 'RÃƒÂ³tulo';

  @override
  String get common_manage_workflows => 'Gerenciar Fluxos';

  @override
  String get common_move_down => 'Mover para baixo';

  @override
  String get common_move_up => 'Mover para cima';

  @override
  String get common_name => 'Nome';

  @override
  String get common_next => 'PrÃƒÂ³ximo';

  @override
  String get common_none => 'Nenhum';

  @override
  String get common_ok => 'OK';

  @override
  String get common_operator => 'Operador';

  @override
  String get common_pick => 'Escolher';

  @override
  String get common_placeholder => 'EspaÃƒÂ§o reservado';

  @override
  String get common_refresh => 'Atualizar';

  @override
  String get common_refresh_workflows => 'Atualizar fluxos';

  @override
  String get common_remove => 'Remover';

  @override
  String get common_required => 'ObrigatÃƒÂ³rio';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_static_options => 'OpÃƒÂ§ÃƒÂµes EstÃƒÂ¡ticas';

  @override
  String get common_style => 'Estilo';

  @override
  String get common_type => 'Tipo';

  @override
  String get common_url => 'URL';

  @override
  String get common_value => 'Valor';

  @override
  String get common_workflow => 'Fluxo de trabalho';

  @override
  String get component_accent_color => 'Cor de Destaque (Hex, ex: FF0000)';

  @override
  String get component_action_row => 'Linha de AÃƒÂ§ÃƒÂ£o';

  @override
  String get component_add_action_row => 'Adicionar Linha de AÃƒÂ§ÃƒÂ£o';

  @override
  String get component_add_button => 'Adicionar BotÃƒÂ£o';

  @override
  String get component_add_button_or_select =>
      'Adicionar BotÃƒÂ£o / Menu de SeleÃƒÂ§ÃƒÂ£o';

  @override
  String get component_add_checkbox_option =>
      'Adicionar OpÃƒÂ§ÃƒÂ£o de Checkbox';

  @override
  String get component_add_child => 'Adicionar Componente Filho';

  @override
  String get component_add_media_item => 'Adicionar Item de MÃƒÂ­dia';

  @override
  String get component_add_radio_option => 'Adicionar OpÃƒÂ§ÃƒÂ£o de RÃƒÂ¡dio';

  @override
  String get component_add_root => 'Adicionar Componente Raiz';

  @override
  String get component_add_text_display => 'Adicionar ExibiÃƒÂ§ÃƒÂ£o de Texto';

  @override
  String get component_add_tooltip => 'Adicionar Componente';

  @override
  String get component_block_label_style => 'Estilo';

  @override
  String get component_block_workflow => 'Fluxo de Trabalho';

  @override
  String get component_button_default_label => 'Botão';

  @override
  String get component_checkbox_options => 'OpÃƒÂ§ÃƒÂµes de Checkbox';

  @override
  String get component_checked_by_default => 'Marcado por padrÃƒÂ£o';

  @override
  String get component_choose_color => 'Escolher Cor';

  @override
  String get component_component_to_wrap => 'Componente para envolver:';

  @override
  String get component_configure_click_actions => 'Configurar Ações';

  @override
  String get component_configure_select_actions =>
      'Configurar Ações de Seleção';

  @override
  String get component_custom_id => 'ID Personalizado';

  @override
  String get component_custom_id_required => 'ID Personalizado *';

  @override
  String get component_default_choice_label => 'Escolha';

  @override
  String get component_default_option_label => 'OpÃƒÂ§ÃƒÂ£o';

  @override
  String get component_disabled_hint =>
      'Digite true/false ou uma variável como ((user.bc_isVip))';

  @override
  String get component_empty_option => 'Vazio';

  @override
  String get component_file_url => 'URL do Arquivo';

  @override
  String get component_label => 'RÃƒÂ³tulo';

  @override
  String get component_label_title => 'TÃƒÂ­tulo do RÃƒÂ³tulo';

  @override
  String get component_markdown_content => 'ConteÃƒÂºdo Markdown';

  @override
  String get component_max_selections => 'SeleÃƒÂ§ÃƒÂµes mÃƒÂ¡ximas';

  @override
  String get component_media_url => 'URL de Imagem / VÃƒÂ­deo';

  @override
  String get component_media_urls => 'URLs de MÃƒÂ­dia';

  @override
  String get component_min_selections => 'SeleÃƒÂ§ÃƒÂµes mÃƒÂ­nimas';

  @override
  String get component_new_checkbox => 'Novo Checkbox';

  @override
  String get component_new_option => 'Nova OpÃƒÂ§ÃƒÂ£o';

  @override
  String get component_new_radio => 'Novo RÃƒÂ¡dio';

  @override
  String get component_not_implemented => 'Editor ainda nÃƒÂ£o implementado';

  @override
  String get component_on_click_workflow => 'Ao clicar, o workflow';

  @override
  String get component_on_select_workflow => 'Ao selecionar, o workflow';

  @override
  String get component_options => 'OpÃƒÂ§ÃƒÂµes';

  @override
  String get component_pick_accent_color => 'Escolher Cor de Destaque';

  @override
  String get component_placeholder => 'EspaÃƒÂ§o reservado';

  @override
  String get component_radio_options => 'OpÃƒÂ§ÃƒÂµes de RÃƒÂ¡dio';

  @override
  String get component_remove_confirm =>
      'Este componente serÃƒÂ¡ removido do layout. Continuar?';

  @override
  String get component_remove_row_title => 'Remover linha de aÃƒÂ§ÃƒÂ£o';

  @override
  String get component_remove_title => 'Remover componente';

  @override
  String get component_section_accessory => 'NÃƒÂ³ AcessÃƒÂ³rio (Opcional)';

  @override
  String get component_section_text_displays => 'ExibiÃƒÂ§ÃƒÂµes de Texto';

  @override
  String get component_selection_range => 'Intervalo de seleÃƒÂ§ÃƒÂ£o';

  @override
  String get component_spacing_large => 'EspaÃƒÂ§amento Grande';

  @override
  String get component_spacing_small => 'EspaÃƒÂ§amento Pequeno';

  @override
  String get component_style => 'Estilo';

  @override
  String get component_thumbnail_url => 'URL da Miniatura';

  @override
  String get component_unknown_component => 'Componente desconhecido';

  @override
  String get component_url => 'URL';

  @override
  String get component_validation_required => 'ObrigatÃƒÂ³rio';

  @override
  String get component_value_hint => 'Dica de valor do componente';

  @override
  String get component_visible_divider => 'Linha DivisÃƒÂ³ria VisÃƒÂ­vel';

  @override
  String get component_workflow_args_hint =>
      'Exemplo: ticketId = ((opts.ticket))';

  @override
  String get component_workflow_args_title => 'Argumentos da Chamada de Fluxo';

  @override
  String get component_workflow_click_hint =>
      'Nome do fluxo salvo para executar ao clicar';

  @override
  String get component_workflow_optional => 'Chamar Fluxo (opcional)';

  @override
  String get component_workflow_select_hint =>
      'Nome do fluxo salvo para executar na seleÃƒÂ§ÃƒÂ£o';

  @override
  String get confirm => 'Confirmar';

  @override
  String get copy => 'Copiar';

  @override
  String get create => 'Criar';

  @override
  String get dart_editor_empty =>
      'Script vazio Ã¢â‚¬â€ comece a escrever para ver os diagnÃƒÂ³sticos Dart.';

  @override
  String get dart_editor_tap_hint => 'Toque para abrir o editor Dart';

  @override
  String get dart_editor_title => 'Editor Dart';

  @override
  String get dashboard_analysis_period => 'PerÃƒÂ­odo de anÃƒÂ¡lise';

  @override
  String dashboard_error(String error) {
    return 'NÃƒÂ£o foi possÃƒÂ­vel carregar as estatÃƒÂ­sticas: $error';
  }

  @override
  String get dashboard_error_rate => 'Taxa de erro';

  @override
  String get dashboard_execution_health_title => 'SaÃƒÂºde da execuÃƒÂ§ÃƒÂ£o';

  @override
  String dashboard_executions(int count) {
    return '$count execuÃƒÂ§ÃƒÂµes';
  }

  @override
  String get dashboard_failed_commands => 'Falhas';

  @override
  String get dashboard_loading => 'Carregando estatÃƒÂ­sticas...';

  @override
  String get dashboard_no_data =>
      'Ainda nÃƒÂ£o hÃƒÂ¡ dados de uso do comando. Execute seu bot para comeÃƒÂ§ar a rastrear.';

  @override
  String get dashboard_p50_latency => 'LatÃƒÂªncia p50';

  @override
  String get dashboard_p95_latency => 'LatÃƒÂªncia p95';

  @override
  String get dashboard_period_24h => 'ÃƒÅ¡ltimas 24h';

  @override
  String get dashboard_period_30d => 'ÃƒÅ¡ltimos 30 dias';

  @override
  String get dashboard_period_7d => 'ÃƒÅ¡ltimos 7 dias';

  @override
  String get dashboard_premium_analytics_desc =>
      'Desbloqueie taxa de erro, percentis de latÃƒÂªncia e insights de idioma.';

  @override
  String get dashboard_premium_analytics_title => 'AnÃƒÂ¡lises Premium';

  @override
  String get dashboard_refresh_sources_tooltip =>
      'Atualizar servidores de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get dashboard_requires_runner =>
      'Conecte-se a um runner para ver as estatÃƒÂ­sticas de uso do comando.';

  @override
  String dashboard_selected_period_total(int count) {
    return '$count no perÃƒÂ­odo selecionado';
  }

  @override
  String get dashboard_single_runner_notice =>
      'As estatÃƒÂ­sticas mostradas sÃƒÂ£o apenas do runner configurado no momento. Se vocÃƒÂª executar bots em vÃƒÂ¡rios runners, esta visualizaÃƒÂ§ÃƒÂ£o pode estar incompleta.';

  @override
  String get dashboard_timeline => 'Uso ao longo do tempo';

  @override
  String get dashboard_title => 'Painel';

  @override
  String get dashboard_top_commands => 'Principais comandos';

  @override
  String get dashboard_top_locales => 'Principais idiomas';

  @override
  String get dashboard_total => 'Total de comandos';

  @override
  String get debug_replay_clear => 'Limpar replays';

  @override
  String get debug_replay_clear_confirm =>
      'Todos os replays gravados serÃƒÂ£o apagados. Continuar?';

  @override
  String get debug_replay_clear_title => 'Limpar replays';

  @override
  String get debug_replay_duration_label => 'DURAÃƒâ€¡ÃƒÆ’O';

  @override
  String get debug_replay_empty_capturing =>
      'A capturarÃ¢â‚¬Â¦ Execute um comando para gravar um replay.';

  @override
  String get debug_replay_empty_idle =>
      'Captura desligada. Ative-a e execute um comando para gravar um replay.';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Profundidade do loop $depth, iteraÃƒÂ§ÃƒÂ£o $iteration';
  }

  @override
  String get debug_replay_overview => 'VisÃƒÂ£o geral';

  @override
  String get debug_replay_pause => 'Pausa';

  @override
  String get debug_replay_play => 'Reproduzir';

  @override
  String get debug_replay_premium_desc =>
      'Grave e reproduza as execuÃƒÂ§ÃƒÂµes dos seus comandos passo a passo. Veja exatamente o que cada aÃƒÂ§ÃƒÂ£o fez, quanto tempo levou e onde ocorreram erros.';

  @override
  String get debug_replay_premium_title => 'Replay do Depurador Visual';

  @override
  String get debug_replay_result_empty => '(sem resultado)';

  @override
  String get debug_replay_result_label => 'RESULTADO';

  @override
  String get debug_replay_start_capture => 'Ativar captura';

  @override
  String debug_replay_start_offset(int ms) {
    return '+$ms ms desde o inÃƒÂ­cio';
  }

  @override
  String get debug_replay_step_back => 'Passo anterior';

  @override
  String get debug_replay_step_first => 'Primeiro passo';

  @override
  String get debug_replay_step_forward => 'PrÃƒÂ³ximo passo';

  @override
  String get debug_replay_step_last => 'ÃƒÅ¡ltimo passo';

  @override
  String get debug_replay_stop_capture => 'Desativar captura';

  @override
  String get debug_replay_title => 'Replay do Depurador';

  @override
  String get debug_replay_variables_empty => '(sem variÃƒÂ¡veis)';

  @override
  String get debug_replay_variables_label => 'VARIÃƒÂVEIS';

  @override
  String get delete => 'Eliminar';

  @override
  String get doc_action_http_request_checklist_l1 =>
      'Defina timeout e tentativas explÃƒÂ­citas em sua camada de serviÃƒÂ§o quando possÃƒÂ­vel.';

  @override
  String get doc_action_http_request_checklist_l2 =>
      'Armazene chaves de API em globais ou backend seguro, nunca codifique tokens rigidamente.';

  @override
  String get doc_action_http_request_checklist_l3 =>
      'Valide o cÃƒÂ³digo de status e o corpo da resposta antes das prÃƒÂ³ximas aÃƒÂ§ÃƒÂµes.';

  @override
  String get doc_action_http_request_section_checklist =>
      'Checklist de Confiabilidade';

  @override
  String get doc_action_http_request_subtitle =>
      'Executa uma chamada HTTP externa dentro de um fluxo de trabalho.';

  @override
  String get doc_action_http_request_summary =>
      'Use isso para webhooks, APIs internas, serviÃƒÂ§os de moderaÃƒÂ§ÃƒÂ£o, endpoints de IA e integraÃƒÂ§ÃƒÂµes.';

  @override
  String get doc_action_http_request_title => 'AÃƒÂ§ÃƒÂ£o: httpRequest';

  @override
  String get doc_action_if_block_execution_l1 =>
      'A condiÃƒÂ§ÃƒÂ£o ÃƒÂ© avaliada uma vez.';

  @override
  String get doc_action_if_block_execution_l2 =>
      'O primeiro ramo correspondente ÃƒÂ© executado: THEN, depois os blocos ELSE IF em ordem, depois ELSE.';

  @override
  String get doc_action_if_block_execution_l3 =>
      'AÃƒÂ§ÃƒÂµes aninhadas podem incluir runWorkflow, chamadas de API e respostas de interaÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_action_if_block_section_execution =>
      'Modelo de ExecuÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_action_if_block_subtitle =>
      'Ramifique a execuÃƒÂ§ÃƒÂ£o entre listas de aÃƒÂ§ÃƒÂµes aninhadas THEN, ELSE IF e ELSE.';

  @override
  String get doc_action_if_block_summary =>
      'Use isso para manter um ÃƒÂºnico fluxo de trabalho enquanto lida com vÃƒÂ¡rios resultados baseados no estado de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_action_if_block_title => 'AÃƒÂ§ÃƒÂ£o: ifBlock';

  @override
  String get doc_action_run_workflow_practices_l1 =>
      'Mantenha o fluxo de nÃƒÂ­vel superior simples e delegue para fluxos de domÃƒÂ­nio.';

  @override
  String get doc_action_run_workflow_practices_l2 =>
      'Passe argumentos explÃƒÂ­citos em vez de confiar em globais implÃƒÂ­citos.';

  @override
  String get doc_action_run_workflow_practices_l3 =>
      'Use pontos de entrada para modelar sub-rotinas (create, close, assign, escalate).';

  @override
  String get doc_action_run_workflow_section_practices =>
      'Melhores PrÃƒÂ¡ticas';

  @override
  String get doc_action_run_workflow_subtitle =>
      'Chama outro fluxo de trabalho com ponto de entrada e argumentos.';

  @override
  String get doc_action_run_workflow_summary =>
      'Primitiva de composiÃƒÂ§ÃƒÂ£o central para dividir a lÃƒÂ³gica de negÃƒÂ³cios em unidades reutilizÃƒÂ¡veis.';

  @override
  String get doc_action_run_workflow_title => 'AÃƒÂ§ÃƒÂ£o: runWorkflow';

  @override
  String get doc_action_stop_unless_example =>
      'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = Ã¢Å“â€¦';

  @override
  String get doc_action_stop_unless_format_l1 =>
      'VocÃƒÂª pode usar chaves brutas: message.content[0]';

  @override
  String get doc_action_stop_unless_format_l2 =>
      'VocÃƒÂª pode usar variÃƒÂ¡veis envolvidas: ((message.content[0]))';

  @override
  String get doc_action_stop_unless_format_l3 =>
      'Ambos sÃƒÂ£o resolvidos pelo tempo de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_action_stop_unless_operators_l1 =>
      'igual, diferente, contÃƒÂ©m, nÃƒÂ£oContÃƒÂ©m, comeÃƒÂ§aCom, terminaCom';

  @override
  String get doc_action_stop_unless_operators_l2 =>
      'maiorQue, menorQue, maiorOuIgual, menorOuIgual';

  @override
  String get doc_action_stop_unless_operators_l3 =>
      'estÃƒÂ¡Vazio, nÃƒÂ£oEstÃƒÂ¡Vazio, corresponde';

  @override
  String get doc_action_stop_unless_section_format =>
      'Formato da VariÃƒÂ¡vel de CondiÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_action_stop_unless_section_operators =>
      'Operadores Suportados';

  @override
  String get doc_action_stop_unless_subtitle =>
      'ClÃƒÂ¡usula guarda que interrompe o fluxo quando a condiÃƒÂ§ÃƒÂ£o falha.';

  @override
  String get doc_action_stop_unless_summary =>
      'Use-o no topo dos fluxos de trabalho para evitar aÃƒÂ§ÃƒÂµes desnecessÃƒÂ¡rias quando o contexto nÃƒÂ£o corresponder.';

  @override
  String get doc_action_stop_unless_title => 'AÃƒÂ§ÃƒÂ£o: stopUnless';

  @override
  String get doc_available_variables => 'VariÃƒÂ¡veis DisponÃƒÂ­veis';

  @override
  String get doc_center_clear_search => 'Limpar pesquisa';

  @override
  String get doc_center_empty =>
      'Nenhuma entrada de documentaÃƒÂ§ÃƒÂ£o corresponde ÃƒÂ  sua pesquisa.';

  @override
  String get doc_center_search_hint =>
      'Procurar comandos, workflows, variÃƒÂ¡veis, aÃƒÂ§ÃƒÂµes, intents ou exemplos...';

  @override
  String get doc_center_title => 'Centro de DocumentaÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_common_section_best_use_cases => 'Melhores Casos de Uso';

  @override
  String get doc_common_section_important_notes => 'Notas Importantes';

  @override
  String get doc_event_audit_log_create_best_use_l1 =>
      'Alertar a equipe sobre aÃƒÂ§ÃƒÂµes sensÃƒÂ­veis (exclusÃƒÂ£o de cargo, criaÃƒÂ§ÃƒÂ£o de webhook, banimento, etc.).';

  @override
  String get doc_event_audit_log_create_best_use_l2 =>
      'Direcionar tipos de aÃƒÂ§ÃƒÂ£o especÃƒÂ­ficos para fluxos de trabalho dedicados.';

  @override
  String get doc_event_audit_log_create_subtitle =>
      'Acionado quando uma nova entrada de log de auditoria ÃƒÂ© criada.';

  @override
  String get doc_event_audit_log_create_summary =>
      'Evento de alto valor para monitoramento de seguranÃƒÂ§a administrativa.';

  @override
  String get doc_event_audit_log_create_title => 'Evento: guildAuditLogCreate';

  @override
  String get doc_event_message_create_best_use_l1 =>
      'Detetar comandos escritos sem comandos de barra.';

  @override
  String get doc_event_message_create_best_use_l2 =>
      'Aplicar filtros anti-spam antes de responder.';

  @override
  String get doc_event_message_create_best_use_l3 =>
      'Encaminhar para workflows reutilizÃƒÂ¡veis com base na primeira palavra ou menÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_event_message_create_example =>
      'Guarda: ((message.isBot)) equals false\nGuarda: ((message.content[0])) equals !ticket\nDepois: runWorkflow -> ticket_manager entrada=create';

  @override
  String get doc_event_message_create_intent_1 => 'Mensagens de Servidor';

  @override
  String get doc_event_message_create_intent_2 => 'ConteÃƒÂºdo de Mensagem';

  @override
  String get doc_event_message_create_notes_l1 =>
      'Se o intent Message Content estiver desligado, condiÃƒÂ§ÃƒÂµes dependentes do conteÃƒÂºdo podem falhar.';

  @override
  String get doc_event_message_create_notes_l2 =>
      'message.content[index] ÃƒÂ© baseado em palavras e limitado pela extraÃƒÂ§ÃƒÂ£o em tempo de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_event_message_create_notes_l3 =>
      'author.isBot pode ajudar a evitar loops de bots.';

  @override
  String get doc_event_message_create_subtitle =>
      'Ativado para cada nova mensagem criada.';

  @override
  String get doc_event_message_create_summary =>
      'Use este evento para moderaÃƒÂ§ÃƒÂ£o, pipelines de palavras-chave, respostas automÃƒÂ¡ticas, anÃƒÂ¡lise de estilo de comando e estatÃƒÂ­sticas.';

  @override
  String get doc_event_message_create_title => 'Evento: messageCreate';

  @override
  String get doc_event_poll_vote_add_best_use_l1 =>
      'Mapeie cada ID de resposta para um ramo de aÃƒÂ§ÃƒÂ£o diferente.';

  @override
  String get doc_event_poll_vote_add_best_use_l2 =>
      'Rastreie a participaÃƒÂ§ÃƒÂ£o na enquete por canal ou grupo de usuÃƒÂ¡rios.';

  @override
  String get doc_event_poll_vote_add_intent => 'Mensagens de Servidor';

  @override
  String get doc_event_poll_vote_add_notes_l1 =>
      'poll.answer.id ÃƒÂ© a chave mais estÃƒÂ¡vel para roteamento.';

  @override
  String get doc_event_poll_vote_add_notes_l2 =>
      'poll.question ÃƒÂ© opcional e pode estar vazio dependendo do payload.';

  @override
  String get doc_event_poll_vote_add_subtitle =>
      'Acionado quando um usuÃƒÂ¡rio vota em uma resposta de enquete.';

  @override
  String get doc_event_poll_vote_add_summary =>
      'ÃƒÅ¡til para rastreamento de pontuaÃƒÂ§ÃƒÂ£o, atribuiÃƒÂ§ÃƒÂ£o de cargos por opÃƒÂ§ÃƒÂ£o de enquete e processamento de pesquisas.';

  @override
  String get doc_event_poll_vote_add_title => 'Evento: messagePollVoteAdd';

  @override
  String get doc_event_reaction_add_best_use_l1 =>
      'Fluxos de aprovaÃƒÂ§ÃƒÂ£o/rejeiÃƒÂ§ÃƒÂ£o com emoji unicode.';

  @override
  String get doc_event_reaction_add_best_use_l2 =>
      'Enquetes de vÃƒÂ¡rias etapas usando IDs de emojis personalizados.';

  @override
  String get doc_event_reaction_add_best_use_l3 =>
      'Sinais de moderaÃƒÂ§ÃƒÂ£o rÃƒÂ¡pida de canais de equipe.';

  @override
  String get doc_event_reaction_add_example =>
      'Guarda: ((reaction.emoji.name)) equals Ã¢Å“â€¦\nAÃƒÂ§ÃƒÂ£o: addRole -> user=((userId)) role=((global.approvedRoleId))';

  @override
  String get doc_event_reaction_add_intent =>
      'ReaÃƒÂ§ÃƒÂµes de Mensagem de Servidor';

  @override
  String get doc_event_reaction_add_notes_l1 =>
      'reaction.emoji.id pode estar vazio para emojis unicode.';

  @override
  String get doc_event_reaction_add_notes_l2 =>
      'Use reaction.emoji.name para correspondÃƒÂªncia genÃƒÂ©rica.';

  @override
  String get doc_event_reaction_add_notes_l3 =>
      'Use reaction.emoji.id para correspondÃƒÂªncia estrita de emojis personalizados.';

  @override
  String get doc_event_reaction_add_subtitle =>
      'Acionado quando um usuÃƒÂ¡rio adiciona uma reaÃƒÂ§ÃƒÂ£o a uma mensagem.';

  @override
  String get doc_event_reaction_add_summary =>
      'Ideal para UX tipo botÃƒÂ£o sem componentes, sistemas de votaÃƒÂ§ÃƒÂ£o, menus de cargos e aprovaÃƒÂ§ÃƒÂµes leves.';

  @override
  String get doc_event_reaction_add_title => 'Evento: messageReactionAdd';

  @override
  String get doc_event_user_update_notes_l1 =>
      'Sem contexto de canal para este evento na maioria dos casos.';

  @override
  String get doc_event_user_update_notes_l2 =>
      'Prefira logs + alertas de moderaÃƒÂ§ÃƒÂ£o em vez de respostas diretas ao usuÃƒÂ¡rio.';

  @override
  String get doc_event_user_update_subtitle =>
      'Acionado quando os dados do perfil do usuÃƒÂ¡rio mudam.';

  @override
  String get doc_event_user_update_summary =>
      'ÃƒÅ¡til para auditoria de mudanÃƒÂ§a de perfil e gatilhos baseados em nome de usuÃƒÂ¡rio/avatar.';

  @override
  String get doc_event_user_update_title => 'Evento: userUpdate';

  @override
  String get doc_event_voice_state_update_automations_l1 =>
      'Detectar violaÃƒÂ§ÃƒÂµes de polÃƒÂ­tica de silenciamento/ensurdecimento prÃƒÂ³prio.';

  @override
  String get doc_event_voice_state_update_automations_l2 =>
      'Acionar mensagem de boas-vindas ao entrar na voz para canais de suporte.';

  @override
  String get doc_event_voice_state_update_automations_l3 =>
      'Registrar padrÃƒÂµes de saÃƒÂ­da/entrada usando mudanÃƒÂ§as de canal.';

  @override
  String get doc_event_voice_state_update_intent => 'Servidores';

  @override
  String get doc_event_voice_state_update_section_title =>
      'AutomaÃƒÂ§ÃƒÂµes TÃƒÂ­picas';

  @override
  String get doc_event_voice_state_update_subtitle =>
      'Acionado quando o estado de voz muda para um usuÃƒÂ¡rio.';

  @override
  String get doc_event_voice_state_update_summary =>
      'Use isso para automoderaÃƒÂ§ÃƒÂ£o em canais de voz, verificaÃƒÂ§ÃƒÂµes de presenÃƒÂ§a e automaÃƒÂ§ÃƒÂ£o de voz.';

  @override
  String get doc_event_voice_state_update_title => 'Evento: voiceStateUpdate';

  @override
  String get doc_example => 'Exemplo';

  @override
  String doc_interaction_commands_example(String name, String id) {
    return 'Workflow de autocompletar:\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'$name\' value=\'$id\'';
  }

  @override
  String get doc_interaction_commands_section_builtin_title =>
      'VariÃƒÂ¡veis de Comando Integradas';

  @override
  String get doc_interaction_commands_section_execution_l1 =>
      'Comandos de barra, utilizador e mensagem entram no runner como interaÃƒÂ§ÃƒÂµes de comando de aplicaÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_interaction_commands_section_execution_l2 =>
      'O runner faz a correspondÃƒÂªncia dos comandos pelo ID do comando do Discord e valida o tipo armazenado vs o tipo recebido.';

  @override
  String get doc_interaction_commands_section_execution_l3 =>
      'Uma incompatibilidade de tipo ÃƒÂ© registada como aviso, mas nÃƒÂ£o interrompe a execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_interaction_commands_section_execution_title =>
      'Modelo de ExecuÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_interaction_commands_section_guidance_l1 =>
      'Escreva lÃƒÂ³gica condicional contra commandType ou interaction.command.type.';

  @override
  String get doc_interaction_commands_section_guidance_l2 =>
      'Prefira a sintaxe de fallback ao partilhar um modelo entre comandos de barra e outros, e use autocomplete.query dentro de workflows de autocompletar dedicados.';

  @override
  String get doc_interaction_commands_section_guidance_l3 =>
      'Mantenha os modelos portÃƒÂ¡teis evitando nomes apenas de eventos dentro de workflows de comandos; o autocompletar dinÃƒÂ¢mico requer um workflow geral terminando com respondWithAutocomplete.';

  @override
  String get doc_interaction_commands_section_guidance_title =>
      'OrientaÃƒÂ§ÃƒÂµes de CriaÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_interaction_commands_section_per_type_l1 =>
      'chatInput: opts.* para parÃƒÂ¢metros e subcomandos.';

  @override
  String get doc_interaction_commands_section_per_type_l2 =>
      'user: target.user.* e target.member.* quando disponÃƒÂ­veis.';

  @override
  String get doc_interaction_commands_section_per_type_l3 =>
      'message: target.message.* incluindo conteÃƒÂºdo e ID do autor quando resolvido.';

  @override
  String get doc_interaction_commands_section_per_type_title =>
      'VariÃƒÂ¡veis por Tipo';

  @override
  String get doc_interaction_commands_subtitle =>
      'Comportamento de execuÃƒÂ§ÃƒÂ£o de comandos de barra, utilizador e mensagem.';

  @override
  String get doc_interaction_commands_summary =>
      'Os comandos da aplicaÃƒÂ§ÃƒÂ£o sÃƒÂ£o executados atravÃƒÂ©s de um caminho de interaÃƒÂ§ÃƒÂ£o partilhado, com variÃƒÂ¡veis de execuÃƒÂ§ÃƒÂ£o dependentes do tipo de comando do Discord.';

  @override
  String get doc_interaction_commands_title => 'Comandos de InteraÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_kind_action => 'AÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_kind_all => 'Tudo';

  @override
  String get doc_kind_event => 'Evento';

  @override
  String get doc_kind_runtime => 'ExecuÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_kind_template => 'Modelo';

  @override
  String get doc_required_intents => 'Intents ObrigatÃƒÂ³rios';

  @override
  String get doc_runtime_action_outputs_example =>
      'Status: ((action.http.status|http.status|desconhecido))\nCorpo: ((action.http.body|http.body))\nApagados: ((cleanup.count|0))\nTotal: ((page.total|0))';

  @override
  String get doc_runtime_action_outputs_section_caveats_l1 =>
      'Nem todas as aÃƒÂ§ÃƒÂµes expÃƒÂµem todos os sufixos; a disponibilidade depende do executor.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l2 =>
      'Para portabilidade, prefira expressÃƒÂµes de fallback ao ler campos de saÃƒÂ­da opcionais.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l3 =>
      'Se uma chave estiver ausente, a resoluÃƒÂ§ÃƒÂ£o do modelo retorna uma string vazia.';

  @override
  String get doc_runtime_action_outputs_section_caveats_title =>
      'AdvertÃƒÂªncias';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l1 =>
      'AÃƒÂ§ÃƒÂµes HTTP: status, body, jsonPath.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l2 =>
      'AÃƒÂ§ÃƒÂµes de mensagem/lista: count, mode, deleteItself, deleteResponse.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l3 =>
      'AÃƒÂ§ÃƒÂµes de array: items, length, removed, total.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l4 =>
      'Outros executores podem expor campos result ou messageId.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_title =>
      'Campos de SaÃƒÂ­da Comuns';

  @override
  String get doc_runtime_action_outputs_section_patterns_l1 =>
      'A saÃƒÂ­da primÃƒÂ¡ria ÃƒÂ© geralmente armazenada como <chaveResultado>.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l2 =>
      'Muitos executores tambÃƒÂ©m expÃƒÂµem campos action.<chaveResultado>.* para clareza e organizaÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l3 =>
      'Alguns campos sÃƒÂ£o espelhados com e sem o prefixo action..';

  @override
  String get doc_runtime_action_outputs_section_patterns_title =>
      'PadrÃƒÂµes de SaÃƒÂ­da';

  @override
  String get doc_runtime_action_outputs_subtitle =>
      'Como as chaves de resultado da aÃƒÂ§ÃƒÂ£o sÃƒÂ£o expostas como variÃƒÂ¡veis.';

  @override
  String get doc_runtime_action_outputs_summary =>
      'A maioria das aÃƒÂ§ÃƒÂµes escreve uma chave de resultado primÃƒÂ¡ria e tambÃƒÂ©m pode expor campos prefixados sob action.<chaveResultado>.* dependendo do executor.';

  @override
  String get doc_runtime_action_outputs_title =>
      'SaÃƒÂ­das de AÃƒÂ§ÃƒÂ£o em Tempo de ExecuÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_runtime_execution_flow_section_parity_l1 =>
      'As variÃƒÂ¡veis devem ser idÃƒÂªnticas entre o runtime da app local e o runtime do runner.';

  @override
  String get doc_runtime_execution_flow_section_parity_l2 =>
      'Use os mesmos nomes de variÃƒÂ¡veis em condiÃƒÂ§ÃƒÂµes para manter a portabilidade.';

  @override
  String get doc_runtime_execution_flow_section_parity_title =>
      'Regra de Paridade';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l1 =>
      '1) Receber evento do gateway.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l2 =>
      '2) Construir mapa de variÃƒÂ¡veis de contexto.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l3 =>
      '3) Corresponder workflows pelo nome do evento.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l4 =>
      '4) Fundir variÃƒÂ¡veis globais.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l5 =>
      '5) Executar aÃƒÂ§ÃƒÂµes sequencialmente com condiÃƒÂ§ÃƒÂµes.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_title => 'Pipeline';

  @override
  String get doc_runtime_execution_flow_subtitle =>
      'Como os workflows de eventos sÃƒÂ£o selecionados e executados.';

  @override
  String get doc_runtime_execution_flow_summary =>
      'Quando um evento chega, o runtime faz a correspondÃƒÂªncia dos workflows configurados por eventTrigger.event e executa as aÃƒÂ§ÃƒÂµes com as variÃƒÂ¡veis de contexto.';

  @override
  String get doc_runtime_execution_flow_title =>
      'Fluxo de ExecuÃƒÂ§ÃƒÂ£o em Tempo de Real';

  @override
  String get doc_template_advanced_variables_example =>
      'Tipo: ((interaction.kind))\nContagem selecionada: ((interaction.values.count|0))\nDono do tÃƒÂ³pico: ((channel.thread.ownerId|desconhecido))\nTipo de payload do servidor: ((guild.kind|n/a))';

  @override
  String get doc_template_advanced_variables_section_aliases_l1 =>
      'Aliases de utilizador estruturados (user.id, user.username, user.tag, user.avatar, user.banner) estÃƒÂ£o disponÃƒÂ­veis em muitos contextos de comando.';

  @override
  String get doc_template_advanced_variables_section_aliases_l2 =>
      'member.id pode ser ÃƒÂºtil quando ambos os contextos de utilizador e membro do servidor sÃƒÂ£o necessÃƒÂ¡rios.';

  @override
  String get doc_template_advanced_variables_section_aliases_title =>
      'Aliases de Utilizador e Membro';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l1 =>
      'channel.kind, channel.position, channel.bitrate e channel.userLimit sÃƒÂ£o detalhes de canal dependentes do contexto.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l2 =>
      'Contextos de tÃƒÂ³pico podem expor valores channel.thread.* (arquivado, bloqueado, ownerId, autoArchiveDuration).';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l3 =>
      'guild.kind ajuda a distinguir payloads parciais/completos de servidor em workflows avanÃƒÂ§ados.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_title =>
      'Detalhes de Canal e Servidor';

  @override
  String get doc_template_advanced_variables_section_interaction_l1 =>
      'interaction.kind identifica o modo de interaÃƒÂ§ÃƒÂ£o recebido (button, select, modal, command, autocomplete).';

  @override
  String get doc_template_advanced_variables_section_interaction_l2 =>
      'interaction.values e interaction.values.count sÃƒÂ£o preenchidos para menus de seleÃƒÂ§ÃƒÂ£o.';

  @override
  String get doc_template_advanced_variables_section_interaction_l3 =>
      'interaction.command.name e interaction.command.id sÃƒÂ£o ÃƒÂºteis para diagnÃƒÂ³sticos e verificaÃƒÂ§ÃƒÂµes de roteamento.';

  @override
  String get doc_template_advanced_variables_section_interaction_title =>
      'Metadados de InteraÃƒÂ§ÃƒÂ£o';

  @override
  String get doc_template_advanced_variables_subtitle =>
      'Chaves de execuÃƒÂ§ÃƒÂ£o adicionais disponÃƒÂ­veis em contextos especÃƒÂ­ficos.';

  @override
  String get doc_template_advanced_variables_summary =>
      'Estas chaves sÃƒÂ£o geradas a partir de payloads de interaÃƒÂ§ÃƒÂ£o e detalhes de execuÃƒÂ§ÃƒÂ£o de canal/servidor/utilizador, dependendo do evento ou tipo de comando.';

  @override
  String get doc_template_advanced_variables_title =>
      'VariÃƒÂ¡veis AvanÃƒÂ§adas de Modelo';

  @override
  String get doc_template_functions_example =>
      'Normalizado: ((uppercase(trim(nomeUtilizador))))\nTem cargo admin: ((contains(cargoUtilizador, \"admin\")))\nMaior pontuaÃƒÂ§ÃƒÂ£o: ((first(scores.\$)))\nPontuaÃƒÂ§ÃƒÂ£o total: ((sum(scores.\$)))';

  @override
  String get doc_template_functions_section_array_l1 =>
      'length(fonte), at(fonte, indice), first(fonte), last(fonte).';

  @override
  String get doc_template_functions_section_array_l2 =>
      'slice(fonte, inicio, fim?) e join(fonte, separador).';

  @override
  String get doc_template_functions_section_array_l3 =>
      'sum(fonte): soma itens numÃƒÂ©ricos e ignora valores nÃƒÂ£o numÃƒÂ©ricos.';

  @override
  String get doc_template_functions_section_array_l4 =>
      'formatEach(...) e embedFields(...) formatam arrays de objetos para texto e embeds.';

  @override
  String get doc_template_functions_section_array_title =>
      'Ajudantes de Array e Agregados';

  @override
  String get doc_template_functions_section_notes_l1 =>
      'Os nomes das funÃƒÂ§ÃƒÂµes nÃƒÂ£o distinguem maiÃƒÂºsculas de minÃƒÂºsculas.';

  @override
  String get doc_template_functions_section_notes_l2 =>
      'FunÃƒÂ§ÃƒÂµes desconhecidas ou argumentos invÃƒÂ¡lidos resolvem para uma string vazia.';

  @override
  String get doc_template_functions_section_notes_l3 =>
      'Use sintaxe de fallback com | no nÃƒÂ­vel raiz: ((replace(nome, \"_\", \" \")|Desconhecido)).';

  @override
  String get doc_template_functions_section_notes_l4 =>
      'Arrays e objetos retornados por funÃƒÂ§ÃƒÂµes sÃƒÂ£o serializados como texto JSON.';

  @override
  String get doc_template_functions_section_notes_title => 'Notas Importantes';

  @override
  String get doc_template_functions_section_random_l1 =>
      'coin() e random(): retornam \"true\" ou \"\" para ramificaÃƒÂ§ÃƒÂ£o condicional.';

  @override
  String get doc_template_functions_section_random_l2 =>
      'randomchoice(a, b, ...) e randomint(min, max).';

  @override
  String get doc_template_functions_section_random_title =>
      'Ajudantes AleatÃƒÂ³rios';

  @override
  String get doc_template_functions_section_string_l1 =>
      'lowercase(fonte) / lower(fonte): converte texto para minÃƒÂºsculas.';

  @override
  String get doc_template_functions_section_string_l2 =>
      'uppercase(fonte) / upper(fonte): converte texto para maiÃƒÂºsculas.';

  @override
  String get doc_template_functions_section_string_l3 =>
      'trim(fonte): remove espaÃƒÂ§os iniciais e finais.';

  @override
  String get doc_template_functions_section_string_l4 =>
      'replace(fonte, busca, substituto) e contains(fonte, agulha) para substituiÃƒÂ§ÃƒÂµes e verificaÃƒÂ§ÃƒÂµes.';

  @override
  String get doc_template_functions_section_string_title =>
      'Ajudantes de String';

  @override
  String get doc_template_functions_subtitle =>
      'Transforme e compare dados dentro de expressÃƒÂµes ((...)).';

  @override
  String get doc_template_functions_summary =>
      'Use funÃƒÂ§ÃƒÂµes de modelo para normalizar texto, inspecionar arrays, construir blocos de saÃƒÂ­da e adicionar aleatoriedade leve.';

  @override
  String get doc_template_functions_title => 'FunÃƒÂ§ÃƒÂµes de Modelo';

  @override
  String doc_template_variables_example(String name, String score) {
    return 'OlÃƒÂ¡ ((target.user.username|nomeUtilizador))\nJogadores: ((join(scores.items.\$, \", \")))\nCampos JSON: ((embedFields(scores.items.\$, \"\'$name\'\", \"\'$score\'\", true)))';
  }

  @override
  String get doc_template_variables_section_builtin_title =>
      'VariÃƒÂ¡veis de Comando Integradas';

  @override
  String get doc_template_variables_section_fallbacks_l1 =>
      'Use ((opts.utilizador|nomeUtilizador)) para falhar quando uma opÃƒÂ§ÃƒÂ£o estiver ausente.';

  @override
  String get doc_template_variables_section_fallbacks_l2 =>
      'Use a sintaxe JSONPath nas saÃƒÂ­das de aÃƒÂ§ÃƒÂ£o: ((meuHttp.body.\$.data[0].id)); arrays e objetos permanecem consultÃƒÂ¡veis.';

  @override
  String get doc_template_variables_section_fallbacks_l3 =>
      'FunÃƒÂ§ÃƒÂµes como length(...), join(...), formatEach(...) e embedFields(...) tambÃƒÂ©m sÃƒÂ£o suportadas; variÃƒÂ¡veis desconhecidas resolvem para uma string vazia.';

  @override
  String get doc_template_variables_section_fallbacks_title =>
      'Fallbacks e Caminhos';

  @override
  String get doc_template_variables_section_sources_l1 =>
      'VariÃƒÂ¡veis de comando: commandName, commandId, commandType, target.*, opts.*.';

  @override
  String get doc_template_variables_section_sources_l2 =>
      'VariÃƒÂ¡veis de evento: event.*, message.*, reaction.*, voice.*, role.*, etc.';

  @override
  String get doc_template_variables_section_sources_l3 =>
      'VariÃƒÂ¡veis de workflow: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*';

  @override
  String get doc_template_variables_section_sources_l4 =>
      'VariÃƒÂ¡veis globais: global.<chave>';

  @override
  String get doc_template_variables_section_sources_l5 =>
      'SaÃƒÂ­das de aÃƒÂ§ÃƒÂ£o: action.<chave> quando disponÃƒÂ­vel.';

  @override
  String get doc_template_variables_section_sources_title =>
      'Origens de VariÃƒÂ¡veis';

  @override
  String get doc_template_variables_section_types_l1 =>
      'Comandos de barra usam commandType = chatInput e expÃƒÂµem variÃƒÂ¡veis opts.<opcao>.';

  @override
  String get doc_template_variables_section_types_l2 =>
      'Comandos de utilizador usam commandType = user e expÃƒÂµem variÃƒÂ¡veis target.user.*.';

  @override
  String get doc_template_variables_section_types_l3 =>
      'Comandos de mensagem usam commandType = message e expÃƒÂµem variÃƒÂ¡veis target.message.*.';

  @override
  String get doc_template_variables_section_types_l4 =>
      'Subcomandos ainda expÃƒÂµem os seus argumentos atravÃƒÂ©s de opts.*.';

  @override
  String get doc_template_variables_section_types_title => 'Tipos de Comando';

  @override
  String get doc_template_variables_subtitle =>
      'Como os placeholders dinÃƒÂ¢micos sÃƒÂ£o resolvidos.';

  @override
  String get doc_template_variables_summary =>
      'O runtime resolve placeholders usando o contexto atual de evento/interaÃƒÂ§ÃƒÂ£o, argumentos de workflow e variÃƒÂ¡veis globais.';

  @override
  String get doc_template_variables_title => 'VariÃƒÂ¡veis de Modelo';

  @override
  String get done => 'ConcluÃƒÂ­do';

  @override
  String download_completed(String id) {
    return 'Download concluÃƒÂ­do: $id';
  }

  @override
  String download_failed(String error) {
    return 'Download falhou: $error';
  }

  @override
  String get download_legacy_backup => 'Download concluÃƒÂ­do (backup legado)';

  @override
  String get drive_legacy_snapshot => 'Snapshot legado';

  @override
  String get drive_manual_backup => 'Backup manual';

  @override
  String get edit_shell_all_saved => 'Todas as alteraÃƒÂ§ÃƒÂµes salvas';

  @override
  String get edit_shell_command_body => 'Corpo do comando';

  @override
  String get edit_shell_command_settings => 'ConfiguraÃƒÂ§ÃƒÂµes do comando';

  @override
  String get edit_shell_command_settings_desc =>
      'Metadados, disponibilidade, permissÃƒÂµes e posicionamento em pastas.';

  @override
  String get edit_shell_local_draft => 'Rascunho local';

  @override
  String get edit_shell_local_only => 'Apenas local';

  @override
  String edit_shell_routes_count(int count) {
    return '$count rota(s)';
  }

  @override
  String get edit_shell_save_changes => 'Salvar alteraÃƒÂ§ÃƒÂµes';

  @override
  String get edit_shell_subtitle =>
      'ConfiguraÃƒÂ§ÃƒÂµes e entradas estÃƒÂ£o no topo. AÃƒÂ§ÃƒÂµes e resposta seguem abaixo.';

  @override
  String get edit_shell_trigger_inputs => 'Gatilho e Entradas';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Ajuste as opÃƒÂ§ÃƒÂµes do comando, comportamento do gatilho e modo de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get edit_shell_type_command => 'Comando';

  @override
  String get edit_shell_type_legacy => 'Comando legado';

  @override
  String get edit_shell_type_message => 'Comando de mensagem';

  @override
  String get edit_shell_type_slash => 'Comando de barra';

  @override
  String get edit_shell_type_user => 'Comando de usuÃƒÂ¡rio';

  @override
  String get edit_shell_unsaved => 'AlteraÃƒÂ§ÃƒÂµes nÃƒÂ£o salvas';

  @override
  String get edit_shell_untitled_command => 'Comando sem tÃƒÂ­tulo';

  @override
  String get embed_add_field => 'Adicionar Campo';

  @override
  String get embed_add_section => 'Adicionar SeÃƒÂ§ÃƒÂ£o';

  @override
  String get embed_add_tooltip => 'Adicionar embed';

  @override
  String get embed_color_picker_title => 'Escolher cor do embed';

  @override
  String get embed_delete_confirm => 'Este embed serÃƒÂ¡ removido. Continuar?';

  @override
  String get embed_delete_title => 'Excluir embed';

  @override
  String embed_empty_message(int max) {
    return 'Sem embeds. VocÃƒÂª pode adicionar atÃƒÂ© $max embeds.';
  }

  @override
  String get embed_field_delete_confirm =>
      'Este campo serÃƒÂ¡ removido do embed. Continuar?';

  @override
  String get embed_field_delete_title => 'Excluir campo';

  @override
  String embed_field_number(int index) {
    return 'Campo #$index';
  }

  @override
  String get embed_fields_empty => 'Nenhum campo ainda.';

  @override
  String embed_fields_header(int count) {
    return 'Campos ($count/25)';
  }

  @override
  String get embed_label_author_icon => 'URL do ÃƒÂcone do Autor';

  @override
  String get embed_label_author_name => 'Nome do Autor';

  @override
  String get embed_label_author_url => 'URL do Autor';

  @override
  String get embed_label_color => 'Cor (int ou #hex)';

  @override
  String get embed_label_dynamic_fields => 'Modelo de Campos DinÃƒÂ¢micos';

  @override
  String get embed_label_footer_icon => 'URL do ÃƒÂcone do RodapÃƒÂ©';

  @override
  String get embed_label_footer_text => 'Texto do RodapÃƒÂ©';

  @override
  String get embed_label_image_url => 'URL da Imagem';

  @override
  String get embed_label_inline => 'Em linha';

  @override
  String get embed_label_thumbnail_url => 'URL da Miniatura';

  @override
  String get embed_label_timestamp => 'Data/Hora (ISO8601)';

  @override
  String get embed_label_title => 'TÃƒÂ­tulo';

  @override
  String get embed_label_url => 'URL';

  @override
  String embed_number(int index) {
    return 'Embed #$index';
  }

  @override
  String embed_response_header(int count, int max) {
    return 'Embeds de Resposta ($count/$max)';
  }

  @override
  String get embed_section_author => 'Autor';

  @override
  String get embed_section_color => 'Cor';

  @override
  String get embed_section_dynamic_fields => 'Campos DinÃƒÂ¢micos';

  @override
  String get embed_section_fields => 'Campos';

  @override
  String get embed_section_footer => 'RodapÃƒÂ©';

  @override
  String get embed_section_media => 'MÃƒÂ­dia';

  @override
  String get embed_section_timestamp => 'Data/Hora';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Eliminar :$name: ? Esta aÃƒÂ§ÃƒÂ£o nÃƒÂ£o pode ser desfeita.';
  }

  @override
  String get emojis_delete_confirm_title => 'Eliminar Emoji';

  @override
  String emojis_delete_error(String error) {
    return 'EliminaÃƒÂ§ÃƒÂ£o falhou: $error';
  }

  @override
  String get emojis_delete_tooltip => 'Excluir';

  @override
  String get emojis_empty =>
      'Ainda nÃƒÂ£o existem emojis. Carregue um para comeÃƒÂ§ar.';

  @override
  String get emojis_loading_error => 'Falha ao carregar emojis';

  @override
  String emojis_rename_error(String error) {
    return 'RenomeaÃƒÂ§ÃƒÂ£o falhou: $error';
  }

  @override
  String get emojis_rename_hint => 'Novo nome';

  @override
  String get emojis_rename_title => 'Renomear Emoji';

  @override
  String get emojis_rename_tooltip => 'Renomear';

  @override
  String get emojis_tab => 'Emojis';

  @override
  String get emojis_tab_short => 'Emoji';

  @override
  String get emojis_title => 'Emojis da AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get emojis_upload => 'Carregar Emoji';

  @override
  String emojis_upload_error(String error) {
    return 'Carregamento falhou: $error';
  }

  @override
  String get emojis_upload_name_hint => 'Nome do emoji (letras, nÃƒÂºmeros, _)';

  @override
  String get emojis_upload_pick_image => 'Escolher Imagem';

  @override
  String get error => 'Erro';

  @override
  String get error_delete_messages_failed => 'Falha ao apagar mensagens.';

  @override
  String get error_invalid_channel_type =>
      'O canal nÃƒÂ£o ÃƒÂ© um canal de texto.';

  @override
  String get error_invalid_count => 'A contagem deve ser superior a 0.';

  @override
  String get error_network_timeout =>
      'A aÃƒÂ§ÃƒÂ£o expirou. Por favor, tente novamente.';

  @override
  String error_with_details(String error) {
    return 'Erro: $error';
  }

  @override
  String get export_button => 'Exportar ZIP';

  @override
  String get export_commands => 'Comandos';

  @override
  String export_failed(String error) {
    return 'Falha na exportaÃƒÂ§ÃƒÂ£o: $error';
  }

  @override
  String get export_file_picker_busy =>
      'Seletor de arquivo jÃƒÂ¡ estÃƒÂ¡ aberto';

  @override
  String get export_global_variables => 'VariÃƒÂ¡veis Globais';

  @override
  String get export_import_title => 'Exportar / Importar';

  @override
  String get export_section_desc =>
      'Exporte secÃƒÂ§ÃƒÂµes selecionadas do seu bot como um ficheiro ZIP. O token do bot nunca ÃƒÂ© incluÃƒÂ­do.';

  @override
  String get export_section_title => 'Exportar';

  @override
  String get export_status => 'Status & Atividades';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get globals_add => 'Adicionar VariÃƒÂ¡vel';

  @override
  String get globals_add_global => 'Adicionar VariÃƒÂ¡vel Global';

  @override
  String get globals_add_scoped => 'Adicionar VariÃƒÂ¡vel Scoped';

  @override
  String get globals_copy_value => 'Copiar valor';

  @override
  String globals_delete_confirm(String key) {
    return 'Apagar \"$key\"?';
  }

  @override
  String get globals_delete_title => 'Apagar VariÃƒÂ¡vel';

  @override
  String get globals_dialog_global_desc =>
      'VariÃƒÂ¡veis globais sÃƒÂ£o partilhadas entre todos os comandos e servidores.';

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Uso: \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Uma variÃƒÂ¡vel scoped armazena um valor separado por contexto de $scope.';
  }

  @override
  String get globals_edit => 'Editar VariÃƒÂ¡vel';

  @override
  String get globals_edit_global => 'Editar VariÃƒÂ¡vel Global';

  @override
  String get globals_edit_scoped => 'Editar VariÃƒÂ¡vel Scoped';

  @override
  String get globals_empty => 'Ainda nÃƒÂ£o hÃƒÂ¡ variÃƒÂ¡veis globais';

  @override
  String get globals_empty_subtitle =>
      'Adicione uma variÃƒÂ¡vel para armazenar dados persistentes acessÃƒÂ­veis por todos os comandos.';

  @override
  String get globals_help_global =>
      'Partilhada entre todos os comandos. Aceda via \$getVar[chave].';

  @override
  String get globals_help_scoped =>
      'Armazenada por contexto (servidor, utilizador, canalÃ¢â‚¬Â¦). Cada entrada mantÃƒÂ©m um valor distinto por contexto do Discord.';

  @override
  String get globals_key => 'Chave';

  @override
  String get globals_key_hint => 'ex: prefixo, nivel, mensagem_boas_vindas';

  @override
  String get globals_mode_global => 'Global';

  @override
  String get globals_mode_scoped => 'Escopo';

  @override
  String get globals_no_default => 'Sem valor padrÃƒÂ£o';

  @override
  String get globals_refresh => 'Atualizar';

  @override
  String get globals_retry => 'Tentar novamente';

  @override
  String get globals_scope_channel => 'canal';

  @override
  String get globals_scope_guild => 'servidor';

  @override
  String get globals_scope_guildMember => 'membro_servidor';

  @override
  String get globals_scope_message => 'mensagem';

  @override
  String get globals_scope_user => 'utilizador';

  @override
  String get globals_search => 'Procurar variÃƒÂ¡veisÃ¢â‚¬Â¦';

  @override
  String get globals_source_local => 'Local';

  @override
  String globals_source_runner(String name) {
    return 'Executor: $name';
  }

  @override
  String get globals_tab => 'Globais';

  @override
  String get globals_tab_short => 'Vars';

  @override
  String get globals_title => 'VariÃƒÂ¡veis';

  @override
  String get globals_value => 'Valor';

  @override
  String get globals_value_auto_type_hint =>
      'O valor ÃƒÂ© tipado automaticamente (nÃƒÂºmero, booleano, JSON).';

  @override
  String get guilds_empty_state =>
      'O bot nÃƒÂ£o estÃƒÂ¡ em nenhum servidor.\nConvide-o para um servidor para vÃƒÂª-lo aqui.';

  @override
  String guilds_leave_confirm(String name) {
    return 'Sair de \"$name\"?\nO bot serÃƒÂ¡ removido deste servidor. VocÃƒÂª pode convidÃƒÂ¡-lo novamente mais tarde pelo portal de desenvolvedores do Discord.';
  }

  @override
  String guilds_leave_failed(String error) {
    return 'Falha ao sair: $error';
  }

  @override
  String get guilds_leave_title => 'Sair do Servidor';

  @override
  String get guilds_leave_tooltip => 'Sair';

  @override
  String guilds_left_success(String name) {
    return 'Saiu de \"$name\".';
  }

  @override
  String guilds_members_count_other(int count) {
    return '~$count membros';
  }

  @override
  String get guilds_owner_label => 'Ã°Å¸â€˜â€˜ ProprietÃƒÂ¡rio';

  @override
  String guilds_server_count_other(int count) {
    return '$count servidores';
  }

  @override
  String get guilds_tab => 'Servidores';

  @override
  String get guilds_tab_short => 'Servidores';

  @override
  String get hint_use_variables => 'Use variÃƒÂ¡veis/modelos se necessÃƒÂ¡rio';

  @override
  String get home_add_time => 'Adicionar Tempo';

  @override
  String get home_empty_support_btn => 'Junte-se ao nosso Discord';

  @override
  String get home_empty_support_hint => 'Precisa de ajuda para comeÃƒÂ§ar?';

  @override
  String get home_foreground_service_not_started =>
      'O serviÃƒÂ§o de primeiro plano nÃƒÂ£o iniciou.';

  @override
  String get home_hosting_expired => 'Hospedagem expirada';

  @override
  String home_hosting_time_left(String time) {
    return 'Tempo de Alojamento restante: $time';
  }

  @override
  String get home_log_desktop_stop_requested =>
      'Paragem do bot de desktop solicitada';

  @override
  String get home_log_start_requested => 'Arranque do bot solicitado';

  @override
  String get home_log_stop_requested => 'Paragem do bot solicitada';

  @override
  String get home_logs_tooltip => 'Registos do bot';

  @override
  String get home_manage => 'Gerir';

  @override
  String get home_notification_permission_required =>
      'A permissÃƒÂ£o de notificaÃƒÂ§ÃƒÂ£o ÃƒÂ© necessÃƒÂ¡ria para iniciar o bot.';

  @override
  String home_server_count_one(int count) {
    return '$count servidor';
  }

  @override
  String home_server_count_other(int count) {
    return '$count servidores';
  }

  @override
  String get home_start => 'Iniciar';

  @override
  String get home_start_ads => 'Iniciar (Ver AnÃƒÂºncio)';

  @override
  String get home_start_premium => 'Iniciar (Premium)';

  @override
  String get home_status_offline => 'Offline';

  @override
  String get home_status_online => 'Online';

  @override
  String get home_stop => 'Parar';

  @override
  String get home_sync_failed => 'Falha na sincronizaÃƒÂ§ÃƒÂ£o';

  @override
  String get home_tab => 'InÃƒÂ­cio';

  @override
  String get home_time_added => 'Tempo adicionado com sucesso';

  @override
  String home_token_missing(String botName) {
    return 'Token nÃƒÂ£o encontrado para $botName';
  }

  @override
  String get home_unknown_app => 'Desconhecido';

  @override
  String get image_editor_create => 'Criar';

  @override
  String get image_editor_create_canvas => 'Criar Tela de Imagem';

  @override
  String image_editor_edit_canvas(int count) {
    return 'Editar Tela ($count ops)';
  }

  @override
  String get image_editor_open => 'Abrir Editor';

  @override
  String get import_button => 'Importar';

  @override
  String import_failed(String error) {
    return 'Falha na importaÃƒÂ§ÃƒÂ£o: $error';
  }

  @override
  String get import_nothing => 'Nada importado.';

  @override
  String get import_overwrite => 'Substituir';

  @override
  String import_parse_failed(String error) {
    return 'Falha ao analisar ZIP: $error';
  }

  @override
  String get import_pick_file => 'Selecionar ficheiro ZIP';

  @override
  String get import_section_desc =>
      'Importe um ficheiro ZIP exportado anteriormente. Conflitos podem ser resolvidos por item.';

  @override
  String get import_section_title => 'Importar';

  @override
  String get import_skip => 'Ignorar';

  @override
  String import_summary_commands_imported(int count) {
    return '$count comando(s) importado(s)';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count comando(s) ignorado(s)';
  }

  @override
  String get import_summary_status_imported => 'status importado';

  @override
  String get import_summary_variables_imported => 'variÃƒÂ¡veis importadas';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count workflow(s) importado(s)';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count workflow(s) ignorado(s)';
  }

  @override
  String get js_editor_hint => '// Escreva seu comando JavaScript aqui...';

  @override
  String get js_editor_segmented_label => 'JS';

  @override
  String get js_editor_subtitle =>
      'Escreva JavaScript personalizado para este comando';

  @override
  String get js_editor_title => 'Editor JavaScript';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'Falha ao executar o script BDFD para o comando \"$command\": $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'Lida com comandos de messageCreate usando <prefixo><comando>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Usa opÃƒÂ§ÃƒÂµes posicionais (exemplo: !config #canal).';

  @override
  String get legacy_prefix_mode_title => 'Modo de Prefixo Legado';

  @override
  String get legacy_prefix_override_hint =>
      'Exemplo: ? ou ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label =>
      'SubstituiÃƒÂ§ÃƒÂ£o de prefixo (opcional)';

  @override
  String get legacy_response_banner_body =>
      'Alguns comandos ainda usam o formato de resposta antigo. Abra-os no editor e salve novamente para ativar o novo formato.';

  @override
  String get legacy_response_banner_dismiss => 'Dispensar';

  @override
  String get legacy_response_banner_migrate => 'Migrar tudo';

  @override
  String get legacy_response_banner_migrate_failed => 'Falha na migraÃƒÂ§ÃƒÂ£o';

  @override
  String legacy_response_banner_migrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comandos migrados',
      one: '1 comando migrado',
    );
    return '$_temp0';
  }

  @override
  String get legacy_response_banner_migrated_none =>
      'Nenhum comando para migrar';

  @override
  String get legacy_response_banner_migrating => 'Migrando...';

  @override
  String get legacy_response_banner_short_body =>
      'Abra e salve novamente seus comandos para migrar para o novo formato.';

  @override
  String get legacy_response_banner_short_title =>
      'AtualizaÃƒÂ§ÃƒÂ£o de comandos disponÃƒÂ­vel';

  @override
  String get legacy_response_banner_title =>
      'AtualizaÃƒÂ§ÃƒÂ£o do formato de resposta dos comandos';

  @override
  String get legacy_response_mode_label => 'Modo de resposta legado';

  @override
  String get local_command_awaited_desc =>
      'Presets de callback aguardados permanecem locais porque sÃƒÂ£o callbacks internos de tempo de execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get local_command_desc =>
      'Armazene o comando apenas no Bot Creator. VocÃƒÂª pode registrÃƒÂ¡-lo dinamicamente em Servidores EspecÃƒÂ­ficos usando BDFD \$registerGuildCommands.';

  @override
  String get local_command_title =>
      'Comando Local (NÃƒÂ£o registrar no Discord)';

  @override
  String logs_runner_source(String name) {
    return 'Logs de: $name';
  }

  @override
  String get marketplace_about => 'Sobre';

  @override
  String get marketplace_add => 'Adicionar';

  @override
  String get marketplace_api_unavailable => 'Cliente API indisponÃƒÂ­vel';

  @override
  String get marketplace_apply => 'Aplicar modelo';

  @override
  String marketplace_apply_error(Object error) {
    return 'Falha ao aplicar: $error';
  }

  @override
  String get marketplace_apply_success => 'Modelo aplicado com sucesso!';

  @override
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  ) {
    return '$addedCount comando(s) adicionado(s), $skippedCount ignorado(s) (duplicados).';
  }

  @override
  String get marketplace_applying => 'Aplicando...';

  @override
  String marketplace_by_author(Object author, Object version) {
    return 'por $author Ã‚Â· v$version';
  }

  @override
  String get marketplace_cancel => 'Cancelar';

  @override
  String marketplace_command_preview_actions(Object count) {
    return '$count aÃƒÂ§ÃƒÂµes';
  }

  @override
  String get marketplace_command_preview_no_actions => 'Nenhuma aÃƒÂ§ÃƒÂ£o';

  @override
  String marketplace_command_preview_options(Object count) {
    return '$count opÃƒÂ§ÃƒÂµes';
  }

  @override
  String get marketplace_command_preview_type_message =>
      'Menu de contexto mensagem';

  @override
  String get marketplace_command_preview_type_slash => 'Comando slash';

  @override
  String get marketplace_command_preview_type_user =>
      'Menu de contexto usuÃƒÂ¡rio';

  @override
  String marketplace_commands_label(Object count) {
    return 'Comandos ($count)';
  }

  @override
  String get marketplace_config_hint =>
      'Preencha os valores obrigatÃƒÂ³rios antes de aplicar este modelo.';

  @override
  String get marketplace_config_required => 'ConfiguraÃƒÂ§ÃƒÂ£o necessÃƒÂ¡ria';

  @override
  String marketplace_conflict_apply_choice(Object count) {
    return 'Aplicar ($count template)';
  }

  @override
  String get marketplace_conflict_keep_local => 'Manter Local';

  @override
  String marketplace_conflict_local_info(Object count) {
    return 'Local ($count aÃƒÂ§ÃƒÂµes)';
  }

  @override
  String get marketplace_conflict_subtitle =>
      'Alguns comandos do template jÃƒÂ¡ existem. Escolhe qual versÃƒÂ£o manter:';

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'Template ($count aÃƒÂ§ÃƒÂµes)';
  }

  @override
  String get marketplace_conflict_title => 'Conflitos de comandos';

  @override
  String get marketplace_conflict_use_template => 'Usar Template';

  @override
  String get marketplace_connect_discord => 'Conectar com Discord';

  @override
  String get marketplace_connect_manager =>
      'Conecte-se ao Manager para acessar o Marketplace.';

  @override
  String get marketplace_connect_publish =>
      'Conecte-se ao Manager para publicar um modelo.';

  @override
  String marketplace_count(Object count) {
    return '$count modelo(s)';
  }

  @override
  String get marketplace_delete => 'Excluir';

  @override
  String marketplace_delete_confirm(Object name) {
    return 'Tem certeza que deseja excluir \"$name\"? Isso nÃƒÂ£o pode ser desfeito.';
  }

  @override
  String get marketplace_delete_confirm_title => 'Excluir Template';

  @override
  String get marketplace_delete_success => 'Template excluÃƒÂ­do.';

  @override
  String get marketplace_edit => 'Editar';

  @override
  String get marketplace_edit_hint =>
      'Para editar, republique da lista de comandos do seu bot com o mesmo nome.';

  @override
  String get marketplace_empty =>
      'Nenhum modelo ainda.\nSeja o primeiro a publicar!';

  @override
  String marketplace_load_error(Object error) {
    return 'Falha ao carregar: $error';
  }

  @override
  String get marketplace_login_hint =>
      'VocÃƒÂª precisa conectar sua conta Discord para acessar o Marketplace.';

  @override
  String get marketplace_login_instructions =>
      'Por favor, autentique-se via Discord para continuar usando o Marketplace.';

  @override
  String get marketplace_login_required => 'ConexÃƒÂ£o Discord necessÃƒÂ¡ria';

  @override
  String get marketplace_login_success => 'Discord conectado com sucesso!';

  @override
  String get marketplace_login_title => 'Conectar ao Manager';

  @override
  String marketplace_more(Object count) {
    return '+$count mais';
  }

  @override
  String get marketplace_my_templates => 'Meus Templates';

  @override
  String marketplace_no_results(Object query) {
    return 'Nenhum modelo corresponde a \"$query\"';
  }

  @override
  String get marketplace_no_variables => 'Nenhuma variÃƒÂ¡vel global definida.';

  @override
  String get marketplace_publish_add_variable => 'Adicionar variÃƒÂ¡vel';

  @override
  String get marketplace_publish_add_variable_title => 'Adicionar variÃƒÂ¡vel';

  @override
  String get marketplace_publish_back => 'Voltar';

  @override
  String get marketplace_publish_button => 'Publicar';

  @override
  String get marketplace_publish_category_hint => 'ex: ai, moderation, fun';

  @override
  String get marketplace_publish_category_label => 'Categoria';

  @override
  String marketplace_publish_commands(Object count) {
    return 'Comandos ($count)';
  }

  @override
  String get marketplace_publish_desc_hint =>
      'Um resumo de uma linha exibido no marketplace';

  @override
  String get marketplace_publish_desc_label => 'DescriÃƒÂ§ÃƒÂ£o curta';

  @override
  String get marketplace_publish_desc_long_hint =>
      'InstruÃƒÂ§ÃƒÂµes detalhadas de uso, markdown suportado...';

  @override
  String get marketplace_publish_desc_long_label =>
      'DocumentaÃƒÂ§ÃƒÂ£o completa (opcional)';

  @override
  String get marketplace_publish_deselect_all => 'Desmarcar tudo';

  @override
  String marketplace_publish_error(Object error) {
    return 'Falha ao publicar: $error';
  }

  @override
  String get marketplace_publish_metadata => 'Detalhes do modelo';

  @override
  String get marketplace_publish_metadata_hint =>
      'Descreva seu modelo para que outros possam encontrÃƒÂ¡-lo e usÃƒÂ¡-lo.';

  @override
  String get marketplace_publish_name_hint => 'ex: Bot de ModeraÃƒÂ§ÃƒÂ£o IA';

  @override
  String get marketplace_publish_name_label => 'Nome do modelo';

  @override
  String get marketplace_publish_next => 'PrÃƒÂ³ximo';

  @override
  String get marketplace_publish_no_content =>
      'Nenhum comando ou workflow para publicar.\nCrie alguns primeiro!';

  @override
  String get marketplace_publish_required_fields =>
      'Por favor, preencha todos os campos obrigatÃƒÂ³rios (Nome, DescriÃƒÂ§ÃƒÂ£o curta, VersÃƒÂ£o) antes de publicar.';

  @override
  String get marketplace_publish_select => 'Selecionar conteÃƒÂºdo';

  @override
  String get marketplace_publish_select_all => 'Selecionar tudo';

  @override
  String get marketplace_publish_select_hint =>
      'Escolha comandos, workflows ou ambos.';

  @override
  String get marketplace_publish_success => 'Modelo publicado com sucesso!';

  @override
  String get marketplace_publish_summary => 'Resumo do modelo';

  @override
  String get marketplace_publish_tags_hint => 'ex: openai, chatbot, moderation';

  @override
  String get marketplace_publish_tags_label =>
      'Tags (separadas por vÃƒÂ­rgula)';

  @override
  String get marketplace_publish_title => 'Publicar modelo';

  @override
  String get marketplace_publish_user_must_define =>
      'UsuÃƒÂ¡rio deve definir este valor';

  @override
  String get marketplace_publish_user_must_define_hint =>
      'O usuÃƒÂ¡rio serÃƒÂ¡ solicitado a preenchÃƒÂª-lo antes de aplicar';

  @override
  String get marketplace_publish_variable_desc_hint =>
      'Para que serve esta variÃƒÂ¡vel';

  @override
  String get marketplace_publish_variable_desc_label => 'DescriÃƒÂ§ÃƒÂ£o';

  @override
  String get marketplace_publish_variable_name_hint => 'ex: TOKEN_OPENAI';

  @override
  String get marketplace_publish_variable_name_label => 'Nome da variÃƒÂ¡vel';

  @override
  String get marketplace_publish_variables => 'VariÃƒÂ¡veis globais';

  @override
  String get marketplace_publish_variables_hint =>
      'Inclua variÃƒÂ¡veis e marque quais o usuÃƒÂ¡rio deve preencher.';

  @override
  String get marketplace_publish_version_label => 'VersÃƒÂ£o';

  @override
  String marketplace_publish_workflows(Object count) {
    return 'Fluxos de Trabalho ($count)';
  }

  @override
  String get marketplace_publishing => 'Publicando...';

  @override
  String get marketplace_rate_success => 'AvaliaÃƒÂ§ÃƒÂ£o enviada!';

  @override
  String get marketplace_rate_title => 'Avaliar este template';

  @override
  String get marketplace_retry => 'Tentar novamente';

  @override
  String get marketplace_search_hint => 'Buscar modelos...';

  @override
  String get marketplace_title => 'Mercado';

  @override
  String marketplace_variable_required(Object name) {
    return '$name ÃƒÂ© obrigatÃƒÂ³rio';
  }

  @override
  String get marketplace_variables_label => 'VariÃƒÂ¡veis prÃƒÂ©-configuradas';

  @override
  String marketplace_workflows_label(Object count) {
    return 'Fluxos de Trabalho ($count)';
  }

  @override
  String get modal_add_text_input => 'Adicionar Entrada de Texto';

  @override
  String get modal_builder_title => 'Construtor de Modal';

  @override
  String get modal_custom_id_hint => 'Usado para identificar este modal';

  @override
  String get modal_custom_id_label => 'ID Personalizado';

  @override
  String get modal_default_value => 'Valor padrÃƒÂ£o';

  @override
  String modal_field_default_label(int index) {
    return 'Campo $index';
  }

  @override
  String modal_input_index(int index) {
    return 'Entrada $index';
  }

  @override
  String modal_inputs_count(int count) {
    return '$count/5 entradas';
  }

  @override
  String get modal_remove_field_confirm =>
      'Este campo serÃƒÂ¡ removido do modal. Continuar?';

  @override
  String get modal_remove_field_title => 'Remover campo do modal';

  @override
  String get modal_style => 'Estilo:';

  @override
  String get modal_title_label => 'TÃƒÂ­tulo do Modal';

  @override
  String get modal_workflow_submit =>
      'Fluxo de trabalho para executar no envio (opcional)';

  @override
  String get more_options_title => 'Mais OpÃƒÂ§ÃƒÂµes';

  @override
  String get more_tab => 'Mais';

  @override
  String get nav_webhooks => 'Webhooks';

  @override
  String get nav_webhooks_compact => 'Hooks';

  @override
  String get no_more_options => 'Nenhuma outra opÃƒÂ§ÃƒÂ£o disponÃƒÂ­vel';

  @override
  String notion_create_workflow_from_query(String query) {
    return 'Criar workflow \"$query\"';
  }

  @override
  String get notion_filter_add => 'Adicionar Filtro';

  @override
  String get notion_filter_type => 'Tipo';

  @override
  String get ok => 'OK';

  @override
  String get onboarding_command_button => 'Continuar';

  @override
  String get onboarding_command_desc => 'Crie o seu primeiro comando';

  @override
  String get onboarding_command_example =>
      'Exemplo:\n/hello Ã¢â€ â€™ O bot responde \"OlÃƒÂ¡! Ã°Å¸â€˜â€¹\"';

  @override
  String get onboarding_command_learn => 'Learn how commands work';

  @override
  String get onboarding_command_text =>
      'Os comandos sÃƒÂ£o o coraÃƒÂ§ÃƒÂ£o do seu bot. Eles permitem que os utilizadores interajam com o seu bot via Discord.';

  @override
  String get onboarding_command_title => 'Passo 2: Adicionar um Comando';

  @override
  String get onboarding_create_button => 'Continuar';

  @override
  String get onboarding_create_desc => 'Obtenha o seu token do Discord';

  @override
  String get onboarding_create_open_portal =>
      'Abrir Portal de Desenvolvedor do Discord';

  @override
  String get onboarding_create_steps =>
      '1. VÃƒÂ¡ ao Portal de Programadores do Discord\n2. Crie uma nova aplicaÃƒÂ§ÃƒÂ£o\n3. Copie o token do bot\n4. Cole-o abaixo';

  @override
  String get onboarding_create_tip =>
      'Ã°Å¸â€™Â¡ Dica: Nunca partilhe o seu token! Ele dÃƒÂ¡ acesso total ao seu bot.';

  @override
  String get onboarding_create_title => 'Passo 1: Criar um Bot';

  @override
  String get onboarding_create_tutorial => 'Tutorial: Como obter um token';

  @override
  String get onboarding_remind_later => 'Lembrar mais tarde';

  @override
  String get onboarding_skip_confirm => 'Skip onboarding';

  @override
  String get onboarding_skip_dialog_desc =>
      'You can resume where you left off next time, or skip the tour entirely.';

  @override
  String get onboarding_skip_dialog_title => 'Leave the onboarding?';

  @override
  String get onboarding_start_button => 'Continuar';

  @override
  String get onboarding_start_desc => 'Lance o seu bot!';

  @override
  String get onboarding_start_hint =>
      'Depois de criar seu bot, vocÃƒÂª encontrarÃƒÂ¡ o botÃƒÂ£o Iniciar no cartÃƒÂ£o dele no aplicativo.';

  @override
  String get onboarding_start_text =>
      'Clique no botÃƒÂ£o \"Iniciar\" no cartÃƒÂ£o do seu bot. Depois teste o seu comando no Discord!';

  @override
  String get onboarding_start_tip =>
      'Ã¢Å“Â¨ FantÃƒÂ¡stico! Criou o seu primeiro bot do Discord. Agora pode adicionar mais comandos e personalizÃƒÂ¡-lo!';

  @override
  String get onboarding_start_title => 'Passo 3: Iniciar o Bot';

  @override
  String onboarding_step_indicator(int current, int total) {
    return 'Etapa $current de $total';
  }

  @override
  String get onboarding_success_button => 'Iniciar!';

  @override
  String get onboarding_success_desc =>
      'O seu bot do Discord estÃƒÂ¡ pronto a funcionar!';

  @override
  String get onboarding_success_tip1 => 'Adicionar mais comandos';

  @override
  String get onboarding_success_tip2 => 'Criar fluxos de trabalho';

  @override
  String get onboarding_success_tip3 =>
      'Fazer cÃƒÂ³pia de seguranÃƒÂ§a dos dados';

  @override
  String get onboarding_success_title => 'ParabÃƒÂ©ns! Ã°Å¸Å½â€°';

  @override
  String get onboarding_success_whatsnext => 'O que se segue?';

  @override
  String get onboarding_welcome_desc =>
      'Crie o seu primeiro bot do Discord em 3 passos simples. Vamos guiÃƒÂ¡-lo em cada etapa.';

  @override
  String get onboarding_welcome_skip => 'Saltar';

  @override
  String get onboarding_welcome_start => 'ComeÃƒÂ§ar';

  @override
  String get onboarding_welcome_title => 'Bem-vindo ao Bot Creator';

  @override
  String get option_add_choice => 'Adicionar Escolha';

  @override
  String get option_add_localizations => 'Adicionar LocalizaÃƒÂ§ÃƒÂµes';

  @override
  String get option_choice_delete_confirm =>
      'Esta escolha serÃƒÂ¡ removida. Continuar?';

  @override
  String get option_choice_delete_title => 'Excluir escolha';

  @override
  String get option_choice_name => 'Nome da Escolha';

  @override
  String option_choice_number(int index) {
    return 'Escolha $index';
  }

  @override
  String get option_choice_value => 'Valor da Escolha';

  @override
  String option_default_name(int index) {
    return 'OpÃƒÂ§ÃƒÂ£o $index';
  }

  @override
  String get option_delete_argument_confirm =>
      'Este argumento serÃƒÂ¡ removido. Continuar?';

  @override
  String get option_delete_argument_title => 'Excluir argumento';

  @override
  String get option_delete_choice_confirm =>
      'Esta escolha serÃƒÂ¡ removida. Continuar?';

  @override
  String get option_delete_choice_title => 'Excluir opÃƒÂ§ÃƒÂ£o';

  @override
  String get option_delete_confirm =>
      'Esta opÃƒÂ§ÃƒÂ£o serÃƒÂ¡ removida. Continuar?';

  @override
  String get option_delete_localization_confirm =>
      'Esta entrada de localizaÃƒÂ§ÃƒÂ£o serÃƒÂ¡ removida. Continuar?';

  @override
  String get option_delete_localization_title => 'Excluir localizaÃƒÂ§ÃƒÂ£o';

  @override
  String get option_delete_title => 'Excluir opÃƒÂ§ÃƒÂ£o';

  @override
  String get option_desc_required =>
      'Por favor, insira uma descriÃƒÂ§ÃƒÂ£o para a opÃƒÂ§ÃƒÂ£o';

  @override
  String option_label_number(int index) {
    return 'RÃƒÂ³tulo $index';
  }

  @override
  String get option_localized_description => 'DescriÃƒÂ§ÃƒÂ£o Localizada';

  @override
  String get option_localized_name => 'Nome Localizado';

  @override
  String get option_max_value => 'Valor MÃƒÂ¡ximo';

  @override
  String get option_min_value => 'Valor MÃƒÂ­nimo';

  @override
  String get option_name_duplicate =>
      'Este nome jÃƒÂ¡ estÃƒÂ¡ sendo usado neste nÃƒÂ­vel';

  @override
  String get option_name_invalid_chars =>
      'O nome da opÃƒÂ§ÃƒÂ£o sÃƒÂ³ pode conter letras, nÃƒÂºmeros e sublinhados';

  @override
  String get option_name_invalid_start =>
      'O nome da opÃƒÂ§ÃƒÂ£o comeÃƒÂ§a com um caractere nÃƒÂ£o suportado';

  @override
  String get option_name_max_length =>
      'O nome da opÃƒÂ§ÃƒÂ£o deve ter no mÃƒÂ¡ximo 32 caracteres';

  @override
  String get option_name_required =>
      'Por favor, insira um nome para a opÃƒÂ§ÃƒÂ£o';

  @override
  String get option_select_language => 'Selecionar Idioma';

  @override
  String option_static_label_n(int index) {
    return 'RÃƒÂ³tulo $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Valor $index';
  }

  @override
  String get option_subcommand_options => 'OpÃƒÂ§ÃƒÂµes do Subcomando';

  @override
  String get option_subcommands => 'Subcomandos';

  @override
  String get option_type_attachment => 'Anexo';

  @override
  String get option_type_boolean => 'Booleano';

  @override
  String get option_type_channel => 'Canal';

  @override
  String get option_type_integer => 'Inteiro';

  @override
  String get option_type_mentionable => 'MencionÃƒÂ¡vel';

  @override
  String get option_type_number => 'NÃƒÂºmero';

  @override
  String get option_type_role => 'Cargo';

  @override
  String get option_type_string => 'Texto';

  @override
  String get option_type_subcommand => 'Subcomando';

  @override
  String get option_type_subcommand_group => 'Grupo de Subcomandos';

  @override
  String get option_type_unknown => 'Desconhecido';

  @override
  String get option_type_user => 'UsuÃƒÂ¡rio';

  @override
  String option_value_number(int index) {
    return 'Valor $index';
  }

  @override
  String get premium_active_desc =>
      'Obrigado pelo seu apoio! Todos os anÃƒÂºncios estÃƒÂ£o desativados.';

  @override
  String get premium_active_title => 'Premium ativo';

  @override
  String get premium_card_button => 'Ver planos';

  @override
  String get premium_card_desc =>
      'Assine para remover todos os anÃƒÂºncios e iniciar seus bots instantaneamente, sem nenhum pop-up.';

  @override
  String get premium_card_title => 'Remover AnÃƒÂºncios';

  @override
  String get quick_access_title => 'Acesso RÃƒÂ¡pido';

  @override
  String get recovery_delete_bot => 'Excluir bot localmente';

  @override
  String get recovery_label => 'RecuperaÃƒÂ§ÃƒÂ£o';

  @override
  String get recovery_retry_discord =>
      'Tentar novamente conexÃƒÂ£o com Discord';

  @override
  String get recovery_title => 'Modo de recuperaÃƒÂ§ÃƒÂ£o';

  @override
  String reply_active_route(String label) {
    return 'Rota ativa: $label';
  }

  @override
  String get reply_buttons_desc =>
      'Adicione botÃƒÂµes interativos ou menus suspensos a esta mensagem';

  @override
  String get reply_buttons_optional =>
      'BotÃƒÂµes e Menus de SeleÃƒÂ§ÃƒÂ£o (opcional)';

  @override
  String get reply_choose_type => 'Escolha o tipo de resposta a enviar';

  @override
  String get reply_command_reply_title => 'Resposta do Comando';

  @override
  String get reply_configure_workflow => 'Configurar Fluxo de Resposta';

  @override
  String get reply_editor_title => 'Detalhes da Resposta';

  @override
  String get reply_mode_layout => 'Modo Layout';

  @override
  String get reply_mode_layout_desc =>
      'Sistema de layout rico do Discord Ã¢â‚¬â€ contÃƒÂªineres, mÃƒÂ­dia, texto e formulÃƒÂ¡rios';

  @override
  String get reply_mode_modal => 'FormulÃƒÂ¡rio Modal';

  @override
  String get reply_mode_modal_desc =>
      'DiÃƒÂ¡logo pop-up com campos de entrada de texto';

  @override
  String get reply_mode_standard => 'Mensagem PadrÃƒÂ£o';

  @override
  String get reply_mode_standard_desc =>
      'Texto, embeds e botÃƒÂµes / menus de seleÃƒÂ§ÃƒÂ£o opcionais';

  @override
  String get reply_response_text_helper =>
      'Usado como texto de resposta do comando de barra. Suporta a sintaxe ((variÃƒÂ¡vel)).';

  @override
  String get reply_response_text_label => 'Texto da Resposta';

  @override
  String get reply_response_workflow => 'Workflow de Resposta';

  @override
  String response_embeds_count(int count) {
    return '$count embed(s)';
  }

  @override
  String get response_interactive_components => 'componentes interativos';

  @override
  String get response_mode_layout => 'Modo de layout';

  @override
  String get response_mode_modal => 'FormulÃƒÂ¡rio modal';

  @override
  String get response_mode_standard => 'Mensagem padrÃƒÂ£o';

  @override
  String get response_visibility_ephemeral => 'efÃƒÂªmero';

  @override
  String get response_visibility_public => 'pÃƒÂºblico';

  @override
  String get response_workflow_auto_defer =>
      'Adiar automaticamente se houver aÃƒÂ§ÃƒÂµes';

  @override
  String get response_workflow_auto_defer_desc =>
      'ReconheÃƒÂ§a rapidamente, execute aÃƒÂ§ÃƒÂµes e edite a resposta final.';

  @override
  String get response_workflow_condition_desc =>
      'Se a variÃƒÂ¡vel existir e nÃƒÂ£o estiver vazia => use o texto ENTÃƒÆ’O, caso contrÃƒÂ¡rio use o texto SENÃƒÆ’O.';

  @override
  String get response_workflow_conditional_title =>
      'Resposta condicional (MVP)';

  @override
  String get response_workflow_deferred_reply => 'Resposta adiada';

  @override
  String get response_workflow_else_text => 'Texto de resposta ELSE (opcional)';

  @override
  String get response_workflow_enable_condition => 'Ativar condiÃƒÂ§ÃƒÂ£o';

  @override
  String get response_workflow_ephemeral_only_user =>
      'EfÃƒÂªmero (apenas o usuÃƒÂ¡rio do comando)';

  @override
  String get response_workflow_error_policy => 'PolÃƒÂ­tica de erro';

  @override
  String get response_workflow_error_policy_desc =>
      'Quando uma aÃƒÂ§ÃƒÂ£o falha, edite a mensagem adiada com um erro.';

  @override
  String get response_workflow_mode_component => 'Componente';

  @override
  String get response_workflow_mode_modal => 'Modal';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_public => 'PÃƒÂºblico';

  @override
  String get response_workflow_revert_tooltip =>
      'Reverter todas as alteraÃƒÂ§ÃƒÂµes';

  @override
  String get response_workflow_then_text => 'Texto de resposta THEN (opcional)';

  @override
  String get response_workflow_title => 'Fluxo de Resposta';

  @override
  String get response_workflow_variable_key =>
      'Chave da variÃƒÂ¡vel (ex: opts.userId)';

  @override
  String get response_workflow_visibility => 'Visibilidade';

  @override
  String get restore_completed => 'Restauro concluÃƒÂ­do';

  @override
  String get restore_runtime_db_recommended =>
      'Restauro concluÃƒÂ­do (SQLite restaurado, recomenda-se reiniciar)';

  @override
  String get review_actions_title => 'AÃƒÂ§ÃƒÂµes';

  @override
  String review_description_line(String desc) {
    return 'DescriÃƒÂ§ÃƒÂ£o: $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Pasta: $folder';
  }

  @override
  String get review_info_title => 'InformaÃƒÂ§ÃƒÂµes';

  @override
  String get review_legacy_mode => 'Modo legado ativado';

  @override
  String get review_local_only => 'Comando apenas local';

  @override
  String review_name_line(String name) {
    return 'Nome: $name';
  }

  @override
  String get review_name_untitled => '(sem tÃƒÂ­tulo)';

  @override
  String review_options_count(int count) {
    return '$count opÃƒÂ§ÃƒÂ£o(ÃƒÂµes)';
  }

  @override
  String get review_reply_title => 'Resposta';

  @override
  String review_subcommand_routes(int count) {
    return '$count rota(s) de subcomando';
  }

  @override
  String get review_trigger_inputs_title => 'Gatilho e Entradas';

  @override
  String review_type_line(String type) {
    return 'Tipo: $type';
  }

  @override
  String get rewarded_start_complete_ad =>
      'Por favor, assista ao anÃƒÂºncio completo para iniciar sua sessÃƒÂ£o de hospedagem.';

  @override
  String get rewarded_start_continue => 'Continuar';

  @override
  String get rewarded_start_message =>
      'Ãƒâ€° necessÃƒÂ¡rio um anÃƒÂºncio para iniciar esta sessÃƒÂ£o de alojamento. Isto ajuda a financiar o projeto. Utilizadores Premium podem saltar isto.';

  @override
  String get rewarded_start_no_ad_available =>
      'Nenhum anÃƒÂºncio disponÃƒÂ­vel no momento. Por favor, tente novamente mais tarde.';

  @override
  String get rewarded_start_skip => 'Saltar';

  @override
  String get rewarded_start_thanks => 'Obrigado pelo seu apoio!';

  @override
  String get rewarded_start_title => 'AnÃƒÂºncio NecessÃƒÂ¡rio';

  @override
  String get rewarded_start_watch => 'Ver anÃƒÂºncio';

  @override
  String get runner_select_source => 'Selecionar runner';

  @override
  String get runner_source_all => 'Todos os runners';

  @override
  String runner_source_label(String name) {
    return 'Executor: $name';
  }

  @override
  String get runner_source_local => 'Local';

  @override
  String get runner_source_manager => 'Servidores Bot Creator';

  @override
  String get runner_source_manager_unavailable =>
      'Inicie sessÃƒÂ£o no Bot Creator nas ConfiguraÃƒÂ§ÃƒÂµes para carregar estatÃƒÂ­sticas dos servidores do Bot Creator.';

  @override
  String get save => 'Guardar';

  @override
  String get scheduler_add_title => 'Adicionar agendamento';

  @override
  String get scheduler_add_trigger => 'Adicionar gatilho';

  @override
  String scheduler_delete_confirm(String label) {
    return 'Excluir agendamento \"$label\"?';
  }

  @override
  String get scheduler_delete_title => 'Excluir agendamento';

  @override
  String get scheduler_edit_title => 'Editar agendamento';

  @override
  String get scheduler_empty => 'Nenhum gatilho agendado ainda.';

  @override
  String get scheduler_every_minutes => 'A cada (minutos)';

  @override
  String get scheduler_invalid_minutes => 'Os minutos devem ser maiores que 0.';

  @override
  String get scheduler_label_field => 'RÃƒÂ³tulo';

  @override
  String get scheduler_label_hint => 'RÃƒÂ³tulo de exibiÃƒÂ§ÃƒÂ£o opcional';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Limite do agendador atingido ($limit).';
  }

  @override
  String get scheduler_no_workflows =>
      'Crie pelo menos um fluxo de trabalho antes de adicionar um agendamento.';

  @override
  String get scheduler_page_title => 'Agendador';

  @override
  String scheduler_save_failed(String error) {
    return 'Falha ao salvar o agendamento: $error';
  }

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'Workflow: $workflow Ã¢â‚¬Â¢ A cada $minutes min';
  }

  @override
  String get scheduler_tab => 'Agendador';

  @override
  String get scheduler_tab_short => 'Agend';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'Gatilhos: $count$limit';
  }

  @override
  String get scoped_default_value => 'Valor padrÃƒÂ£o';

  @override
  String get scoped_default_value_hint => 'Opcional';

  @override
  String scoped_delete_confirm(String key) {
    return 'Apagar \"$key\" e todos os seus dados de execuÃƒÂ§ÃƒÂ£o armazenados?';
  }

  @override
  String get scoped_delete_title => 'Apagar VariÃƒÂ¡vel Scoped';

  @override
  String get scoped_empty => 'Nenhuma variÃƒÂ¡vel scoped definida';

  @override
  String get scoped_empty_subtitle =>
      'VariÃƒÂ¡veis scoped armazenam um valor por contexto do Discord (utilizador, servidorÃ¢â‚¬Â¦). SÃƒÂ£o preenchidas pelo bot em execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get scoped_explore_runtime => 'Explorar dados de execuÃƒÂ§ÃƒÂ£o';

  @override
  String scoped_ref(String ref) {
    return 'ReferÃƒÂªncia: $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legado: $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'Copiar tudo';

  @override
  String get scoped_runtime_empty =>
      'Sem dados de execuÃƒÂ§ÃƒÂ£o.\nEsta chave serÃƒÂ¡ preenchida pelo bot durante a execuÃƒÂ§ÃƒÂ£o.';

  @override
  String get scoped_runtime_search => 'Procurar por ID ou nomeÃ¢â‚¬Â¦';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Escopo: $scope Ã‚Â· $count contexto(s) encontrado(s)';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Dados de execuÃƒÂ§ÃƒÂ£o Ã¢â‚¬â€ \"$key\"';
  }

  @override
  String get scoped_scope => 'Escopo';

  @override
  String get scoped_scope_help =>
      'O nÃƒÂ­vel da entidade em que a variÃƒÂ¡vel ÃƒÂ© armazenada.';

  @override
  String get scoped_title => 'VariÃƒÂ¡veis Scoped';

  @override
  String get scratch_add_block => 'Adicionar bloco';

  @override
  String get scratch_bdfd_script => 'Script BDFD';

  @override
  String get scratch_block_entry_point => 'Gatilho do Comando';

  @override
  String get scratch_block_metadata => 'Metadados';

  @override
  String get scratch_block_required => 'ObrigatÃƒÂ³rio';

  @override
  String get scratch_blocks_tab => 'Blocos';

  @override
  String get scratch_custom_id_filter_desc =>
      'Este fluxo de trabalho sÃƒÂ³ serÃƒÂ¡ executado se o Custom ID do botÃƒÂ£o clicado ou modal enviado corresponder exatamente a este ID.';

  @override
  String get scratch_custom_id_filter_hint => 'ex: meu_id_do_botao';

  @override
  String get scratch_custom_id_filter_label => 'Filtro de Custom ID (opcional)';

  @override
  String get scratch_dart_script => 'Script Dart';

  @override
  String get scratch_entry_event_trigger => 'Gatilho de evento';

  @override
  String get scratch_entry_function => 'FunÃƒÂ§ÃƒÂ£o';

  @override
  String get scratch_entry_interaction => 'Comando de Barra (/)';

  @override
  String get scratch_entry_message => 'Mensagem de Texto';

  @override
  String get scratch_entry_point_hint => 'Dica de ponto de entrada scratch';

  @override
  String get scratch_entry_point_label => 'Nome do ponto de entrada';

  @override
  String get scratch_entry_point_listen =>
      'Quando ÃƒÂ© que este comando ÃƒÂ© executado?';

  @override
  String get scratch_event_category => 'Categoria do evento';

  @override
  String get scratch_event_name => 'Nome do evento';

  @override
  String get scratch_event_variables => 'VariÃƒÂ¡veis do evento';

  @override
  String get scratch_execution_mode =>
      'Como ÃƒÂ© que o comando ÃƒÂ© construÃƒÂ­do?';

  @override
  String get scratch_legacy_config => 'ConfiguraÃƒÂ§ÃƒÂ£o legada';

  @override
  String get scratch_meta_advanced => 'DefiniÃƒÂ§ÃƒÂµes avanÃƒÂ§adas';

  @override
  String get scratch_meta_desc_hint => 'DescriÃƒÂ§ÃƒÂ£o do comando';

  @override
  String get scratch_meta_name_hint => 'Nome do comando';

  @override
  String get scratch_meta_type_label => 'Tipo de comando';

  @override
  String get scratch_meta_type_message => 'Comando de mensagem';

  @override
  String get scratch_meta_type_message_desc =>
      'Ativado a partir do menu de contexto da mensagem.';

  @override
  String get scratch_meta_type_prefix => 'Comando de prefixo';

  @override
  String get scratch_meta_type_prefix_desc =>
      'Ativado por um prefixo de texto (ex: !ajuda).';

  @override
  String get scratch_meta_type_slash => 'Comando de barra';

  @override
  String get scratch_meta_type_slash_desc =>
      'Ativado ao escrever / no Discord.';

  @override
  String get scratch_meta_type_user => 'Comando de utilizador';

  @override
  String get scratch_meta_type_user_desc =>
      'Ativado a partir do menu de contexto do utilizador.';

  @override
  String get scratch_mode_bdfd => 'CÃƒÂ³digo BDFD';

  @override
  String get scratch_mode_blocks => 'Visual (Blocos)';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_response_block => 'Resposta';

  @override
  String get scratch_response_components => 'Componentes';

  @override
  String get scratch_response_edit => 'Editar resposta';

  @override
  String get scratch_trigger_tab => 'Gatilho';

  @override
  String get scratch_wizard_actions_empty_desc =>
      'Adicione blocos de aÃƒÂ§ÃƒÂµes abaixo para configurar o que o seu bot faz.';

  @override
  String get scratch_wizard_actions_empty_title =>
      'Nenhuma aÃƒÂ§ÃƒÂ£o definida ainda.';

  @override
  String get scratch_wizard_config_button_instruction =>
      'Configure o ID do botÃƒÂ£o ou modal que irÃƒÂ¡ disparar este fluxo de trabalho.';

  @override
  String get scratch_wizard_folder_hint => 'ex: admin';

  @override
  String get scratch_wizard_folder_label => 'Pasta (opcional)';

  @override
  String get scratch_wizard_save_details => 'Detalhes de salvamento';

  @override
  String get scratch_wizard_step_actions => 'Passo 3: AÃƒÂ§ÃƒÂµes';

  @override
  String get scratch_wizard_step_config => 'Passo 2: ConfiguraÃƒÂ§ÃƒÂ£o';

  @override
  String get scratch_wizard_step_save => 'Passo 4: Salvar & Resumo';

  @override
  String get scratch_wizard_step_trigger => 'Passo 1: Tipo de Gatilho';

  @override
  String scratch_wizard_summary_actions_count(int count) {
    return '$count aÃƒÂ§ÃƒÂ£o(ÃƒÂµes) configurada(s)';
  }

  @override
  String get scratch_wizard_summary_title => 'Resumo do Fluxo de Trabalho';

  @override
  String scratch_wizard_summary_trigger_button(String id) {
    return 'Clique no BotÃƒÂ£o / Modal (Custom ID: \'$id\')';
  }

  @override
  String scratch_wizard_summary_trigger_event(String event) {
    return 'Evento: $event';
  }

  @override
  String get scratch_wizard_summary_trigger_function =>
      'FunÃƒÂ§ÃƒÂ£o Geral / Fluxo de Trabalho';

  @override
  String get scratch_wizard_trigger_button_desc =>
      'Dispara quando um usuÃƒÂ¡rio clica em um botÃƒÂ£o, usa um menu de seleÃƒÂ§ÃƒÂ£o ou envia um formulÃƒÂ¡rio modal.';

  @override
  String get scratch_wizard_trigger_button_title =>
      'BotÃƒÂ£o ou Componente de Mensagem';

  @override
  String get scratch_wizard_trigger_event_desc =>
      'Dispara em uma aÃƒÂ§ÃƒÂ£o do Discord (ex: novo membro entra, mensagem excluÃƒÂ­da, cargo atualizado).';

  @override
  String get scratch_wizard_trigger_event_title => 'Evento do Discord';

  @override
  String get scratch_wizard_trigger_function_desc =>
      'Executa o fluxo de trabalho como uma funÃƒÂ§ÃƒÂ£o reutilizÃƒÂ¡vel que pode ser chamada por outros gatilhos.';

  @override
  String get scratch_wizard_trigger_function_title =>
      'FunÃƒÂ§ÃƒÂ£o / Gatilho Manual';

  @override
  String get scratch_wizard_trigger_instruction =>
      'Escolha o que ativa este fluxo de trabalho:';

  @override
  String get scratch_wizard_workflow_name_hint => 'ex: resposta_do_botao';

  @override
  String get scratch_wizard_workflow_name_label =>
      'Nome do Fluxo de Trabalho *';

  @override
  String get scratch_workflow_add_argument => 'Adicionar argumento';

  @override
  String get scratch_workflow_arguments => 'Argumentos (VariÃƒÂ¡veis)';

  @override
  String get scratch_workflow_metadata => 'DefiniÃƒÂ§ÃƒÂµes do Workflow';

  @override
  String get scratch_workflow_name => 'Nome do Workflow';

  @override
  String get scratch_workflow_type => 'Tipo de Workflow';

  @override
  String get scratch_workflow_type_event => 'Baseado em eventos';

  @override
  String get scratch_workflow_type_general => 'Geral';

  @override
  String get serialization_export_base64_title =>
      'Exportar comando como Base64';

  @override
  String get serialization_export_json_subtitle =>
      'Copiar JSON legÃƒÂ­vel para a ÃƒÂ¡rea de transferÃƒÂªncia';

  @override
  String get serialization_export_json_title => 'Exportar comando como JSON';

  @override
  String get serialization_import_desc =>
      'Cole um payload de comando (JSON ou Base64).';

  @override
  String get serialization_import_title => 'Importar comando';

  @override
  String get serialization_imported => 'Comando importado para o editor.';

  @override
  String get serialization_invalid_format =>
      'Formato de payload de comando invÃƒÂ¡lido.';

  @override
  String get serialization_invalid_structure =>
      'Estrutura de payload de comando invÃƒÂ¡lida.';

  @override
  String get settings_account_connect_label =>
      'Entrar no Bot Creator com Discord';

  @override
  String get settings_account_connected_hint =>
      'Conta conectada. Seus bots e dados estÃƒÂ£o agora sincronizados com o Bot Creator.';

  @override
  String get settings_account_disconnect_label => 'Sair';

  @override
  String get settings_account_disconnected_hint =>
      'Sua conta do Bot Creator ÃƒÂ© criada automaticamente quando vocÃƒÂª adiciona um bot. Em seguida, faÃƒÂ§a login com o Discord para recuperar seus bots neste dispositivo.';

  @override
  String get settings_account_status_connected => 'Conta conectada';

  @override
  String get settings_account_status_disconnected => 'NÃƒÂ£o logado';

  @override
  String get settings_ads_privacy_loading =>
      'A verificar definiÃƒÂ§ÃƒÂµes de privacidade de anÃƒÂºncios...';

  @override
  String get settings_ads_privacy_manage =>
      'Gerir escolhas de privacidade de anÃƒÂºncios';

  @override
  String get settings_ads_privacy_not_required =>
      'OpÃƒÂ§ÃƒÂµes de privacidade de anÃƒÂºncios nÃƒÂ£o sÃƒÂ£o necessÃƒÂ¡rias agora';

  @override
  String get settings_ads_privacy_open_error =>
      'NÃƒÂ£o foi possÃƒÂ­vel abrir as opÃƒÂ§ÃƒÂµes de privacidade de anÃƒÂºncios';

  @override
  String get settings_ads_privacy_opened =>
      'OpÃƒÂ§ÃƒÂµes de privacidade de anÃƒÂºncios abertas';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_appearance_title => 'Aspeto e idioma';

  @override
  String get settings_auto_backup_check_loading =>
      'A verificar cÃƒÂ³pia automÃƒÂ¡ticaÃ¢â‚¬Â¦';

  @override
  String get settings_auto_backup_every_12h => 'A cada 12h';

  @override
  String get settings_auto_backup_every_24h => 'A cada 24h';

  @override
  String get settings_auto_backup_every_6h => 'A cada 6h';

  @override
  String get settings_auto_backup_every_72h => 'A cada 72h';

  @override
  String get settings_auto_backup_interval =>
      'Intervalo de cÃƒÂ³pia de seguranÃƒÂ§a automÃƒÂ¡tica';

  @override
  String get settings_backup_now => 'Fazer cÃƒÂ³pia de seguranÃƒÂ§a agora';

  @override
  String get settings_backup_restore_desc =>
      'Gerir a sincronizaÃƒÂ§ÃƒÂ£o de dados com o Google Drive';

  @override
  String get settings_backup_restore_title =>
      'CÃƒÂ³pia de SeguranÃƒÂ§a e Restauro';

  @override
  String get settings_builtin_help => 'Comando !help legado integrado';

  @override
  String get settings_builtin_help_subtitle =>
      'Recurso obrigatÃƒÂ³rio com alternÃƒÂ¢ncia explÃƒÂ­cita. Desative-o se desejar apenas um comportamento de ajuda personalizado.';

  @override
  String get settings_clear_logs => 'Limpar registos';

  @override
  String get settings_cloud_hosting_enabled =>
      'Bots mÃƒÂ³veis agora usam os servidores do Bot Creator.';

  @override
  String get settings_compatibility_desc =>
      'Uma visÃƒÂ£o rÃƒÂ¡pida da cobertura de funcionalidades para utilizadores que vÃƒÂªm do BDFD.';

  @override
  String get settings_compatibility_functions_category_components =>
      'Componentes / InteraÃƒÂ§ÃƒÂµes';

  @override
  String get settings_compatibility_functions_category_control =>
      'Fluxo de controlo';

  @override
  String get settings_compatibility_functions_category_embeds => 'Embeds';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Guardas e permissÃƒÂµes';

  @override
  String get settings_compatibility_functions_category_http => 'Ajudantes HTTP';

  @override
  String get settings_compatibility_functions_category_json => 'Ajudantes JSON';

  @override
  String get settings_compatibility_functions_category_logging => 'Registo';

  @override
  String get settings_compatibility_functions_category_messages => 'Mensagens';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'Placeholders de runtime';

  @override
  String get settings_compatibility_functions_category_threads => 'TÃƒÂ³picos';

  @override
  String get settings_compatibility_functions_category_variables =>
      'VariÃƒÂ¡veis de ÃƒÂ¢mbito';

  @override
  String settings_compatibility_functions_count(int count) {
    return 'FunÃƒÂ§ÃƒÂµes compatÃƒÂ­veis: $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'Total de referÃƒÂªncia BDFD: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'Suportadas pelo Bot Creator: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Apenas Bot Creator: $count';
  }

  @override
  String settings_compatibility_functions_count_both(int count) {
    return 'Suportadas em ambos: $count';
  }

  @override
  String settings_compatibility_functions_count_missing(int count) {
    return 'Em falta no Bot Creator: $count';
  }

  @override
  String get settings_compatibility_functions_empty =>
      'Nenhuma funÃƒÂ§ÃƒÂ£o nesta secÃƒÂ§ÃƒÂ£o.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'Entradas apenas BDFD sÃƒÂ£o funÃƒÂ§ÃƒÂµes listadas no catÃƒÂ¡logo BDFD fornecido mas nÃƒÂ£o implementadas atualmente no Bot Creator.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Vista de diferenÃƒÂ§as entre a implementaÃƒÂ§ÃƒÂ£o do Bot Creator e as funÃƒÂ§ÃƒÂµes de referÃƒÂªncia BDFD.';

  @override
  String get settings_compatibility_functions_note =>
      'Esta pÃƒÂ¡gina ÃƒÂ© gerada a partir do ÃƒÂ¢mbito de implementaÃƒÂ§ÃƒÂ£o atual e crescerÃƒÂ¡ ao longo do tempo.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Procurar uma funÃƒÂ§ÃƒÂ£o (exemplo: \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Suportado apenas no Bot Creator';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Ajudantes de loop sÃƒÂ£o atualmente especÃƒÂ­ficos do Bot Creator.';

  @override
  String get settings_compatibility_functions_section_both =>
      'Suportado no Bot Creator e BDFD';

  @override
  String get settings_compatibility_functions_section_missing =>
      'DisponÃƒÂ­vel no BDFD mas em falta no Bot Creator';

  @override
  String get settings_compatibility_functions_subtitle =>
      'FunÃƒÂ§ÃƒÂµes atualmente implementadas e utilizÃƒÂ¡veis no modo BDFD do Bot Creator.';

  @override
  String get settings_compatibility_functions_title =>
      'FunÃƒÂ§ÃƒÂµes BDFD CompatÃƒÂ­veis';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Cobertura total do catÃƒÂ¡logo de funÃƒÂ§ÃƒÂµes BDFD.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'Paridade de funÃƒÂ§ÃƒÂµes BDScript';

  @override
  String get settings_compatibility_item_events_desc =>
      'A maioria dos eventos comuns ÃƒÂ© suportada, alguns sÃƒÂ£o limitados pelo runtime.';

  @override
  String get settings_compatibility_item_events_title => 'Cobertura de eventos';

  @override
  String get settings_compatibility_item_runner_desc =>
      'O runner remoto estÃƒÂ¡ disponÃƒÂ­vel, o suporte multi-runner estÃƒÂ¡ em curso.';

  @override
  String get settings_compatibility_item_runner_title =>
      'Arquitetura do Runner';

  @override
  String get settings_compatibility_item_variables_desc =>
      'VariÃƒÂ¡veis dinÃƒÂ¢micas e ajudantes de template sÃƒÂ£o suportados.';

  @override
  String get settings_compatibility_item_variables_title =>
      'VariÃƒÂ¡veis de runtime e templates';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Fluxos de trabalho visuais de comando e resposta estÃƒÂ£o disponÃƒÂ­veis.';

  @override
  String get settings_compatibility_item_workflows_title =>
      'Construtor de fluxos';

  @override
  String get settings_compatibility_note =>
      'Este snapshot ÃƒÂ© intencionalmente de alto nÃƒÂ­vel e evoluirÃƒÂ¡ com as versÃƒÂµes.';

  @override
  String get settings_compatibility_open_functions =>
      'Ver funÃƒÂ§ÃƒÂµes compatÃƒÂ­veis';

  @override
  String get settings_compatibility_status_missing => 'Em falta';

  @override
  String get settings_compatibility_status_partial => 'Parcial';

  @override
  String get settings_compatibility_status_supported => 'Suportado';

  @override
  String get settings_compatibility_title => 'Snapshot de compatibilidade BDFD';

  @override
  String get settings_data_operations_title => 'OperaÃƒÂ§ÃƒÂµes de Dados';

  @override
  String get settings_debug_desc =>
      'Repor preferÃƒÂªncias locais ou repetir a introduÃƒÂ§ÃƒÂ£o para testes.';

  @override
  String get settings_debug_premium_bypass => 'Bypass Premium';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Desbloquear todas as funcionalidades Premium sem subscriÃƒÂ§ÃƒÂ£o (apenas depuraÃƒÂ§ÃƒÂ£o).';

  @override
  String get settings_debug_title => 'Ferramentas de depuraÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_diagnostics_copied =>
      'DiagnÃƒÂ³sticos copiados para a ÃƒÂ¡rea de transferÃƒÂªncia';

  @override
  String get settings_diagnostics_copy_all => 'Copiar todos os registos';

  @override
  String get settings_diagnostics_dialog_title => 'DiagnÃƒÂ³stico de Arranque';

  @override
  String get settings_diagnostics_empty =>
      'Ainda nÃƒÂ£o existem registos da aplicaÃƒÂ§ÃƒÂ£o.';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Mostra apenas registos de diagnÃƒÂ³stico da app (registos do bot sÃƒÂ£o excluÃƒÂ­dos).';

  @override
  String get settings_diagnostics_page_title => 'Registos da AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_diagnostics_refresh => 'Atualizar registos';

  @override
  String get settings_diagnostics_section_title => 'DiagnÃƒÂ³sticos';

  @override
  String get settings_discord_rpc_authenticating =>
      'A autenticar com o DiscordÃ¢â‚¬Â¦';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'CÃƒÂ³digo de autorizaÃƒÂ§ÃƒÂ£o em cache; tente novamente para terminar a troca de token';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'CÃƒÂ³digo de autorizaÃƒÂ§ÃƒÂ£o recebido';

  @override
  String get settings_discord_rpc_authorize => 'Autorizar';

  @override
  String get settings_discord_rpc_authorizing =>
      'A aguardar autorizaÃƒÂ§ÃƒÂ£o do DiscordÃ¢â‚¬Â¦';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label =>
      'URL do broker OAuth (avanÃƒÂ§ado, opcional)';

  @override
  String get settings_discord_rpc_broker_required =>
      'O ID de cliente ÃƒÂ© suficiente para o fluxo de cliente pÃƒÂºblico; URL do broker e client secret sÃƒÂ£o fallbacks opcionais';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Este ID ÃƒÂ© fixo no Bot Creator e nÃƒÂ£o pode ser alterado nas definiÃƒÂ§ÃƒÂµes.';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'ID de cliente da aplicaÃƒÂ§ÃƒÂ£o Discord necessÃƒÂ¡rio';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Fallback avanÃƒÂ§ado opcional para um fluxo de cliente confidencial processado localmente.';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Segredo do cliente';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Client secret da aplicaÃƒÂ§ÃƒÂ£o Discord (opcional)';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Concluir autorizaÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_discord_rpc_connect => 'Atualizar presenÃƒÂ§a';

  @override
  String get settings_discord_rpc_connected =>
      'PresenÃƒÂ§a enviada para o Discord';

  @override
  String get settings_discord_rpc_connecting => 'A ligar ao DiscordÃ¢â‚¬Â¦';

  @override
  String get settings_discord_rpc_desc =>
      'Publique a atividade de desktop do Bot Creator no cliente local do Discord. O Bot Creator utiliza sempre a aplicaÃƒÂ§ÃƒÂ£o Discord integrada e envia SET_ACTIVITY diretamente via IPC local quando ativado.';

  @override
  String get settings_discord_rpc_disabled => 'Desativado';

  @override
  String get settings_discord_rpc_disconnect => 'Fechar IPC';

  @override
  String get settings_discord_rpc_disconnected => 'IPC fechado';

  @override
  String get settings_discord_rpc_enable => 'Ativar Discord Rich Presence';

  @override
  String get settings_discord_rpc_enable_first =>
      'Ative primeiro o Discord Rich Presence';

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'Endpoint IPC: $endpoint';
  }

  @override
  String get settings_discord_rpc_error => 'Erro de Discord RPC';

  @override
  String get settings_discord_rpc_exchanging_code =>
      'A concluir troca OAuthÃ¢â‚¬Â¦';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'IPC local do Discord ligado; nenhum pedido HTTP OAuth enviado ainda, autenticaÃƒÂ§ÃƒÂ£o ainda necessÃƒÂ¡ria';

  @override
  String get settings_discord_rpc_ipc_open => 'IPC local jÃƒÂ¡ aberto';

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'ÃƒÅ¡ltimo erro: $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization =>
      'AutorizaÃƒÂ§ÃƒÂ£o necessÃƒÂ¡ria';

  @override
  String get settings_discord_rpc_not_configured =>
      'ID de cliente necessÃƒÂ¡rio';

  @override
  String get settings_discord_rpc_open_ipc => 'Abrir IPC local';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence estÃƒÂ¡ disponÃƒÂ­vel apenas em desktop';

  @override
  String get settings_discord_rpc_save => 'Guardar definiÃƒÂ§ÃƒÂµes';

  @override
  String get settings_discord_rpc_saved =>
      'DefiniÃƒÂ§ÃƒÂµes de Discord Rich Presence guardadas';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'O transporte Discord ainda nÃƒÂ£o ÃƒÂ© suportado nesta plataforma';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Utilizador autorizado: $user';
  }

  @override
  String get settings_drive_connect => 'Ligar ao Google Drive';

  @override
  String get settings_drive_connect_loading => 'A ligar ao Google DriveÃ¢â‚¬Â¦';

  @override
  String get settings_drive_connected => 'Ligado ao Google Drive';

  @override
  String get settings_drive_desc =>
      'Ligue a sua conta Google Drive para sincronizar os seus dados';

  @override
  String get settings_drive_disconnect => 'Desligar';

  @override
  String get settings_drive_disconnect_loading => 'A desligarÃ¢â‚¬Â¦';

  @override
  String get settings_drive_disconnected => 'Desligado do Google Drive';

  @override
  String get settings_drive_status_connected => 'Ligado';

  @override
  String get settings_drive_title => 'LigaÃƒÂ§ÃƒÂ£o ao Google Drive';

  @override
  String get settings_enable_auto_backup =>
      'Ativar cÃƒÂ³pia de seguranÃƒÂ§a automÃƒÂ¡tica';

  @override
  String get settings_enable_auto_backup_desc =>
      'Crie snapshots versionados automaticamente quando devidos.';

  @override
  String get settings_execution_mode_desc =>
      'Nesta plataforma, o Bot Creator nunca hospeda seus bots. VocÃƒÂª pode usar seu runner auto-hospedado ou executar os bots localmente.';

  @override
  String get settings_execution_mode_local_active =>
      'Os bots agora iniciam localmente. As configuraÃƒÂ§ÃƒÂµes do runner permanecem armazenadas e podem ser reativadas a qualquer momento.';

  @override
  String get settings_execution_mode_no_runner =>
      'Nenhum runner configurado ainda. O app permanece local atÃƒÂ© que vocÃƒÂª adicione um.';

  @override
  String get settings_execution_mode_runner_priority =>
      'O runner auto-hospedado ÃƒÂ© preferido. Se nenhum runner estiver configurado, o app volta para o local.';

  @override
  String get settings_execution_mode_title => 'Modo de execuÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_execution_mode_use_runner =>
      'Usar um executor hospedado por conta prÃƒÂ³pria';

  @override
  String get settings_export => 'Exportar';

  @override
  String get settings_export_app_data => 'Exportar Dados da App';

  @override
  String get settings_export_loading => 'A exportarÃ¢â‚¬Â¦';

  @override
  String get settings_import => 'Importar';

  @override
  String get settings_import_app_data => 'Importar Dados da App';

  @override
  String get settings_import_loading => 'A importarÃ¢â‚¬Â¦';

  @override
  String get settings_language_desc => 'Escolha o idioma utilizado pela app.';

  @override
  String get settings_language_system => 'AutomÃƒÂ¡tico (dispositivo)';

  @override
  String get settings_language_title => 'Idioma';

  @override
  String get settings_language_updated => 'Idioma atualizado';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'ÃƒÅ¡ltima cÃƒÂ³pia automÃƒÂ¡tica: $date';
  }

  @override
  String get settings_last_auto_backup_never =>
      'ÃƒÅ¡ltima cÃƒÂ³pia automÃƒÂ¡tica: nunca';

  @override
  String get settings_legacy_prefix => 'Prefixo de comando legado';

  @override
  String get settings_legacy_prefix_helper =>
      'Suporta templates e variÃƒÂ¡veis de escopo (bc_ opcional). Exemplo: ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? ou ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc =>
      'Reveja como os seus dados sÃƒÂ£o tratados e armazenados.';

  @override
  String get settings_legal_title => 'Avisos Legais';

  @override
  String get settings_local_hosting_enabled =>
      'Bots mÃƒÂ³veis agora usam seu dispositivo para hospedagem.';

  @override
  String get settings_logs_cleared => 'Registo de diagnÃƒÂ³sticos limpo';

  @override
  String get settings_main_api_auth_failed =>
      'A sessÃƒÂ£o do Servidor do Bot Creator ÃƒÂ© invÃƒÂ¡lida ou expirou';

  @override
  String get settings_main_api_check => 'Verificar Servidor do Bot Creator';

  @override
  String get settings_main_api_clear => 'Limpar';

  @override
  String get settings_main_api_cleared =>
      'DefiniÃƒÂ§ÃƒÂµes do Servidor do Bot Creator limpas';

  @override
  String get settings_main_api_connect_discord => 'Ligar conta Discord';

  @override
  String get settings_main_api_connected =>
      'Servidor do Bot Creator acessÃƒÂ­vel Ã¢Å“â€œ';

  @override
  String get settings_main_api_connected_discord => 'Conta Discord ligada';

  @override
  String settings_main_api_connected_user(String user) {
    return 'Ligado como $user';
  }

  @override
  String get settings_main_api_desc =>
      'Ligue o Bot Creator ao seu Servidor do Bot Creator e inicie sessÃƒÂ£o com o Discord. O secret do cliente Discord deve permanecer no backend.';

  @override
  String get settings_main_api_desktop_only =>
      'O inÃƒÂ­cio de sessÃƒÂ£o no Discord via Servidor do Bot Creator estÃƒÂ¡ disponÃƒÂ­vel apenas no desktop.';

  @override
  String get settings_main_api_disconnect => 'Desligar conta';

  @override
  String get settings_main_api_not_configured =>
      'URL do Servidor do Bot Creator necessÃƒÂ¡rio';

  @override
  String get settings_main_api_save => 'Guardar Servidor do Bot Creator';

  @override
  String get settings_main_api_saved =>
      'DefiniÃƒÂ§ÃƒÂµes do Servidor do Bot Creator guardadas';

  @override
  String get settings_main_api_session_connected => 'SessÃƒÂ£o Discord ativa';

  @override
  String get settings_main_api_session_disconnected =>
      'SessÃƒÂ£o Discord desligada';

  @override
  String get settings_main_api_session_expired => 'SessÃƒÂ£o Discord expirou';

  @override
  String get settings_main_api_title => 'Servidor do Bot Creator';

  @override
  String get settings_main_api_unreachable =>
      'Servidor do Bot Creator inacessÃƒÂ­vel';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_url_required =>
      'URL do Servidor do Bot Creator necessÃƒÂ¡rio';

  @override
  String get settings_main_api_user_unknown => 'Utilizador Discord';

  @override
  String get settings_manual_snapshot_label => 'Snapshot manual';

  @override
  String get settings_member_badge => 'MEMBRO';

  @override
  String get settings_notifications_desc =>
      'Escolha quais tipos de notificaÃƒÂ§ÃƒÂµes push deseja receber.';

  @override
  String get settings_notifications_title => 'NotificaÃƒÂ§ÃƒÂµes';

  @override
  String get settings_notifications_topic_billing => 'Faturamento';

  @override
  String get settings_notifications_topic_billing_desc =>
      'Lembretes de renovaÃƒÂ§ÃƒÂ£o de assinatura e confirmaÃƒÂ§ÃƒÂµes de pagamento.';

  @override
  String get settings_notifications_topic_botAlerts => 'Alertas de bot';

  @override
  String get settings_notifications_topic_botAlerts_desc =>
      'Avisos quando seus bots ficam offline ou encontram erros.';

  @override
  String get settings_notifications_topic_broadcast => 'AnÃƒÂºncios';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'AnÃƒÂºncios importantes e novidades do Bot Creator.';

  @override
  String get settings_notifications_topic_updates => 'AtualizaÃƒÂ§ÃƒÂµes';

  @override
  String get settings_notifications_topic_updates_desc =>
      'Novos recursos, atualizaÃƒÂ§ÃƒÂµes do app e destaques do changelog.';

  @override
  String get settings_open_ad_inspector => 'Abrir Inspetor de AnÃƒÂºncios';

  @override
  String get settings_oss_licenses => 'LicenÃƒÂ§as Open Source';

  @override
  String get settings_owner_badge => 'PROPRIETÃƒÂRIO';

  @override
  String get settings_owner_fallback => 'ProprietÃƒÂ¡rio';

  @override
  String get settings_personal_owner_fallback => 'UsuÃƒÂ¡rio Pessoal';

  @override
  String get settings_personal_owner_id_label => 'ID do ProprietÃƒÂ¡rio: ';

  @override
  String get settings_personal_owner_label => 'ProprietÃƒÂ¡rio: ';

  @override
  String get settings_personal_ownership => 'Propriedade Pessoal';

  @override
  String get settings_preferences_reset_done => 'PreferÃƒÂªncias repostas';

  @override
  String get settings_privacy_policy => 'PolÃƒÂ­tica de Privacidade';

  @override
  String get settings_raw_json_tile => 'Ver JSON bruto (RAW JSON)';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_replay_onboarding => 'Repetir introduÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_replay_onboarding_desc =>
      'Repor introduÃƒÂ§ÃƒÂ£o e lanÃƒÂ§ÃƒÂ¡-la novamente agora.';

  @override
  String get settings_reset_preferences => 'Repor preferÃƒÂªncias';

  @override
  String get settings_reset_preferences_desc =>
      'Repor tema, idioma e progresso da introduÃƒÂ§ÃƒÂ£o.';

  @override
  String get settings_restore_snapshot => 'Restaurar este Snapshot';

  @override
  String get settings_run_auto_backup_now =>
      'Executar cÃƒÂ³pia automÃƒÂ¡tica agora';

  @override
  String get settings_run_diagnostics => 'Executar DiagnÃƒÂ³sticos';

  @override
  String settings_runner_active(String url) {
    return 'API do Runner Ativa: $url';
  }

  @override
  String get settings_runner_auth_failed => 'Runner rejeitou o token da API';

  @override
  String get settings_runner_check => 'Verificar ligaÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_runner_clear => 'Limpar';

  @override
  String get settings_runner_cleared => 'DefiniÃƒÂ§ÃƒÂµes do Runner limpas';

  @override
  String get settings_runner_connected => 'Runner acessÃƒÂ­vel Ã¢Å“â€œ';

  @override
  String get settings_runner_connecting => 'A verificar ligaÃƒÂ§ÃƒÂ£oÃ¢â‚¬Â¦';

  @override
  String get settings_runner_desc =>
      'Ligue a app a um Bot Creator Runner. Runners remotos devem permanecer em redes fidedignas e usar um token bearer.';

  @override
  String get settings_runner_disable_temp => 'Desativar Runner temporariamente';

  @override
  String get settings_runner_disable_temp_desc =>
      'Manter definiÃƒÂ§ÃƒÂµes do Runner mas forÃƒÂ§ar modo local atÃƒÂ© ser reativado.';

  @override
  String get settings_runner_disconnected => 'Runner desconectado';

  @override
  String get settings_runner_not_connected => 'NÃƒÂ£o conectado';

  @override
  String get settings_runner_reenabled => 'Runner reativado';

  @override
  String get settings_runner_save => 'Guardar definiÃƒÂ§ÃƒÂµes';

  @override
  String get settings_runner_saved => 'DefiniÃƒÂ§ÃƒÂµes do Runner guardadas';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner desativado temporariamente (modo local ativo)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner desativado temporariamente';

  @override
  String get settings_runner_title => 'API do Runner';

  @override
  String get settings_runner_token_hint =>
      'Token Bearer (opcional em localhost)';

  @override
  String get settings_runner_token_label => 'Token da API do Runner';

  @override
  String get settings_runner_unreachable => 'Runner inacessÃƒÂ­vel';

  @override
  String get settings_runner_url_clear => 'Limpar';

  @override
  String get settings_runner_url_cleared => 'URL do Runner limpo';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_url_save => 'Guardar URL';

  @override
  String get settings_runner_url_saved => 'URL do Runner guardado';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Apps: $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps neste snapshot';

  @override
  String get settings_snapshot_create_loading => 'A criar snapshotÃ¢â‚¬Â¦';

  @override
  String settings_snapshot_created_at(String date) {
    return 'Criado: $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot criado: $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'A eliminar snapshotÃ¢â‚¬Â¦';

  @override
  String get settings_snapshot_deleted => 'Snapshot eliminado';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Ficheiros: $count Ã¢â‚¬Â¢ Tamanho: $size';
  }

  @override
  String settings_snapshot_id(String id) {
    return 'ID: $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'Etiqueta: $label';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date Ã¢â‚¬Â¢ $count ficheiros Ã¢â‚¬Â¢ $size';
  }

  @override
  String get settings_snapshot_no_metadata =>
      'Nenhum metadado de app disponÃƒÂ­vel.';

  @override
  String get settings_snapshot_preview_title =>
      'PrÃƒÂ©-visualizaÃƒÂ§ÃƒÂ£o do Snapshot';

  @override
  String get settings_snapshot_restore_loading => 'A restaurar snapshotÃ¢â‚¬Â¦';

  @override
  String get settings_snapshots_delete_all => 'Eliminar todos os snapshots';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return 'Eliminar permanentemente $count snapshot(s)? Esta aÃƒÂ§ÃƒÂ£o nÃƒÂ£o pode ser desfeita.';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count snapshot(s) eliminado(s).';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'A eliminar todos os snapshotsÃ¢â‚¬Â¦';

  @override
  String get settings_snapshots_delete_all_title =>
      'Eliminar todos os snapshots';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Eliminar permanentemente \"$label\"? Esta aÃƒÂ§ÃƒÂ£o nÃƒÂ£o pode ser desfeita.';
  }

  @override
  String get settings_snapshots_delete_select_desc =>
      'Selecione o snapshot a remover (mais antigo primeiro).';

  @override
  String get settings_snapshots_delete_select_title => 'Eliminar um snapshot';

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Eliminar um snapshot selecionado';

  @override
  String get settings_snapshots_empty =>
      'Ainda nÃƒÂ£o foram encontrados snapshots.';

  @override
  String get settings_snapshots_refresh => 'Atualizar snapshots';

  @override
  String get settings_snapshots_refresh_loading =>
      'A atualizar snapshotsÃ¢â‚¬Â¦';

  @override
  String get settings_snapshots_title => 'Snapshots';

  @override
  String get settings_solo_pill => 'SOLO';

  @override
  String get settings_startup_mode_cloud_desc =>
      'Recomendado no Android e iOS. Logs, estatÃƒÂ­sticas e inicializaÃƒÂ§ÃƒÂ£o passam pelo Bot Creator.';

  @override
  String get settings_startup_mode_desc =>
      'Escolha se seus bots iniciam nos servidores do Bot Creator ou localmente neste dispositivo.';

  @override
  String get settings_startup_mode_ios_unavailable =>
      'O modo local permanece indisponÃƒÂ­vel no iOS.';

  @override
  String get settings_startup_mode_ios_warning =>
      'No iOS, o modo local nÃƒÂ£o ÃƒÂ© suportado. Os bots sempre usam os servidores do Bot Creator.';

  @override
  String get settings_startup_mode_local_desc =>
      'Os bots agora iniciam localmente neste dispositivo.';

  @override
  String get settings_startup_mode_local_warning =>
      'O modo local ÃƒÂ© uma opÃƒÂ§ÃƒÂ£o avanÃƒÂ§ada destinada a depuraÃƒÂ§ÃƒÂ£o ou necessidades especÃƒÂ­ficas. Para uso normal, mantenha os servidores do Bot Creator ativados.';

  @override
  String get settings_startup_mode_title => 'Bot startup mode';

  @override
  String get settings_startup_mode_use_cloud =>
      'Usar servidores do Bot Creator';

  @override
  String get settings_status_remove_confirm =>
      'Esta entrada de status serÃƒÂ¡ removida. Continuar?';

  @override
  String get settings_tab => 'DefiniÃƒÂ§ÃƒÂµes';

  @override
  String get settings_team_id_label => 'ID da equipe: ';

  @override
  String settings_team_members_label(int count) {
    return 'Membros da Equipe ($count)';
  }

  @override
  String get settings_team_name_label => 'Nome da equipe: ';

  @override
  String get settings_team_owner_label => 'LÃƒÂ­der da Equipe';

  @override
  String get settings_team_ownership => 'Propriedade da Equipe';

  @override
  String get settings_team_pill => 'EQUIPE';

  @override
  String get settings_theme_switch_dark => 'Mudar para modo escuro';

  @override
  String get settings_theme_switch_light => 'Mudar para modo claro';

  @override
  String get settings_version_title => 'VersÃƒÂ£o';

  @override
  String get settings_view_startup_logs => 'Ver registos de arranque';

  @override
  String get startup_copy_diagnostics => 'Copiar diagnÃƒÂ³sticos';

  @override
  String get startup_diagnostics_copied =>
      'DiagnÃƒÂ³sticos copiados para a ÃƒÂ¡rea de transferÃƒÂªncia';

  @override
  String get startup_error_title => 'Erro de InicializaÃƒÂ§ÃƒÂ£o';

  @override
  String get startup_failed_message =>
      'O Bot Creator falhou ao iniciar neste dispositivo.';

  @override
  String get startup_refresh_diagnostics => 'Atualizar diagnÃƒÂ³sticos';

  @override
  String get subscription_active_annual => 'Premium Ã¢â‚¬â€ Anual';

  @override
  String get subscription_active_label => 'Plano ativo:';

  @override
  String get subscription_active_monthly => 'Premium Ã¢â‚¬â€ Mensal';

  @override
  String get subscription_annual_title => 'Anual';

  @override
  String get subscription_benefit_fast_start =>
      'Bots iniciam instantaneamente, sem pop-up';

  @override
  String get subscription_benefit_no_ads =>
      'Sem anÃƒÂºncios em lugar nenhum do app';

  @override
  String get subscription_benefit_support =>
      'Apoie o desenvolvimento independente';

  @override
  String get subscription_error =>
      'A compra nÃƒÂ£o pÃƒÂ´de ser concluÃƒÂ­da. Por favor, tente novamente.';

  @override
  String get subscription_error_product_unavailable =>
      'Este plano estÃƒÂ¡ indisponÃƒÂ­vel no momento. Por favor, tente novamente mais tarde.';

  @override
  String get subscription_error_purchase_start_failed =>
      'A compra nÃƒÂ£o pÃƒÂ´de ser iniciada. Por favor, tente novamente.';

  @override
  String get subscription_error_store_unavailable =>
      'A App Store estÃƒÂ¡ indisponÃƒÂ­vel no momento. Por favor, tente novamente em um momento.';

  @override
  String get subscription_feature_analytics_desc =>
      'Acesse taxa de erro, percentis de latÃƒÂªncia e insights de localidade.';

  @override
  String get subscription_feature_analytics_title => 'AnÃƒÂ¡lises avanÃƒÂ§adas';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Reinicie o bot automaticamente quando um reinÃƒÂ­cio completo for necessÃƒÂ¡rio.';

  @override
  String get subscription_feature_auto_restart_title =>
      'ReinÃƒÂ­cio automÃƒÂ¡tico';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Dimensione bots grandes distribuindo a carga entre shard workers.';

  @override
  String get subscription_feature_auto_sharding_title =>
      'Sharding automÃƒÂ¡tico';

  @override
  String get subscription_feature_coming_soon => 'Em breve';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Grave e reproduza aÃƒÂ§ÃƒÂµes de comando passo a passo para depuraÃƒÂ§ÃƒÂ£o.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Replay visual de depuraÃƒÂ§ÃƒÂ£o';

  @override
  String get subscription_feature_instant_start_desc =>
      'Inicie os bots imediatamente sem interrupÃƒÂ§ÃƒÂ£o de anÃƒÂºncio premiado.';

  @override
  String get subscription_feature_instant_start_title =>
      'InÃƒÂ­cio instantÃƒÂ¢neo';

  @override
  String get subscription_feature_lavalink_desc =>
      'Play music and audio in Discord voice channels using Lavalink.';

  @override
  String get subscription_feature_lavalink_title => 'Lavalink audio support';

  @override
  String get subscription_feature_no_ads_desc =>
      'Remova todas as inserÃƒÂ§ÃƒÂµes de anÃƒÂºncios em toda a experiÃƒÂªncia do aplicativo.';

  @override
  String get subscription_feature_no_ads_title => 'Sem anÃƒÂºncios';

  @override
  String get subscription_feature_scheduler_desc =>
      'Execute fluxos de trabalho automaticamente a cada X minutos (atÃƒÂ© 10 ativos).';

  @override
  String get subscription_feature_scheduler_title => 'Gatilhos de agendamento';

  @override
  String get subscription_feature_webhooks_desc =>
      'Crie endpoints de webhook seguros e direcione chamadas para fluxos de trabalho.';

  @override
  String get subscription_feature_webhooks_title => 'Webhooks de entrada';

  @override
  String get subscription_manage => 'Gerenciar assinatura';

  @override
  String get subscription_monthly_title => 'Mensal';

  @override
  String get subscription_not_available_on_platform =>
      'As assinaturas estÃƒÂ£o disponÃƒÂ­veis no momento apenas para dispositivos mÃƒÂ³veis.';

  @override
  String get subscription_per_month => 'por mÃƒÂªs';

  @override
  String get subscription_per_year => 'por ano';

  @override
  String get subscription_plan_desc =>
      'Remova anÃƒÂºncios e tenha acesso a todos os recursos premium atuais e futuros.';

  @override
  String get subscription_plan_label => 'Premium BÃƒÂ¡sico';

  @override
  String get subscription_privacy => 'PolÃƒÂ­tica de privacidade';

  @override
  String get subscription_restore => 'Restaurar compras';

  @override
  String get subscription_restore_not_found =>
      'Nenhuma assinatura ativa encontrada.';

  @override
  String get subscription_restored => 'Assinatura restaurada com sucesso!';

  @override
  String get subscription_save_badge => 'ECONOMIZE 67%';

  @override
  String get subscription_subtitle =>
      'Escolha um plano para desbloquear todos os recursos premium.';

  @override
  String get subscription_success =>
      'Bem-vindo ao Premium! Todos os anÃƒÂºncios foram removidos.';

  @override
  String get subscription_terms => 'Termos de uso';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_unavailable_platform =>
      'NÃƒÂ£o disponÃƒÂ­vel nesta plataforma.';

  @override
  String get support_card_desc =>
      'Uma dÃƒÂºvida, um bug, uma sugestÃƒÂ£o? Venha conversar com a equipa e a comunidade.';

  @override
  String get support_card_title => 'Suporte & Comunidade';

  @override
  String get support_discord_badge => 'Suporte oficial';

  @override
  String get support_join_discord => 'Juntar-se ao servidor de Discord';

  @override
  String get template_fun_description =>
      'Cara ou coroa, enquetes e bola 8 mÃƒÂ¡gica.';

  @override
  String get template_fun_name => 'Bot de DiversÃƒÂ£o';

  @override
  String template_gallery_already_exists(String name) {
    return 'O comando \"$name\" jÃƒÂ¡ existe e foi ignorado.';
  }

  @override
  String get template_gallery_apply => 'Usar este modelo';

  @override
  String template_gallery_apply_error(String error) {
    return 'Falha ao aplicar o modelo: $error';
  }

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return 'Aplicados $count comando(s) e $wCount fluxo(s) de trabalho do modelo.';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count comando(s)';
  }

  @override
  String get template_gallery_empty => 'Nenhum modelo disponÃƒÂ­vel.';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return 'Nada a remover para $name.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Tem certeza de que deseja remover todos os comandos e fluxos de trabalho deste modelo?';

  @override
  String get template_gallery_remove_title => 'Remover Modelo';

  @override
  String get template_gallery_removed =>
      'Comandos e fluxos de trabalho do modelo removidos.';

  @override
  String get template_gallery_subtitle =>
      'Comece rapidamente o seu bot com um modelo pronto a usar.';

  @override
  String get template_gallery_sync_warning =>
      'Comandos salvos localmente. Inicie seu bot para registrÃƒÂ¡-los no Discord.';

  @override
  String get template_gallery_title => 'Modelos';

  @override
  String template_gallery_workflows_count(int count) {
    return '$count fluxo(s) de trabalho';
  }

  @override
  String get template_moderation_description =>
      'Banir, expulsar, silenciar membros e limpar mensagens.';

  @override
  String get template_moderation_name => 'Bot de ModeraÃƒÂ§ÃƒÂ£o';

  @override
  String get template_utility_description =>
      'Ping, busca de avatar e comandos de fala do bot.';

  @override
  String get template_utility_name => 'Bot UtilitÃƒÂ¡rio';

  @override
  String get template_welcome_description =>
      'Cumprimente novos membros, diga olÃƒÂ¡ e mostre informaÃƒÂ§ÃƒÂµes do servidor.';

  @override
  String get template_welcome_name => 'Bot de Boas-vindas';

  @override
  String unit_day(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
      zero: '0 dias',
    );
    return '$_temp0';
  }

  @override
  String unit_hour(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
      zero: '0 horas',
    );
    return '$_temp0';
  }

  @override
  String unit_minute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
      zero: '0 minutos',
    );
    return '$_temp0';
  }

  @override
  String unit_month(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mÃƒÂªs',
      zero: '0 meses',
    );
    return '$_temp0';
  }

  @override
  String get validation_awaited_callback_format =>
      'O retorno de chamada aguardado deve usar \$awaitedCommand[nome;filtro] ou \$awaitedCommandError[nome].';

  @override
  String validation_awaited_callback_length(int max) {
    return 'O gatilho de retorno de chamada aguardado deve ter no mÃƒÂ¡ximo $max caracteres';
  }

  @override
  String get validation_awaited_callback_local_only =>
      'Retornos de chamada aguardados requerem um Comando Legado apenas local.';

  @override
  String get validation_command_name_invalid_chars =>
      'O nome do comando pode conter apenas letras, nÃƒÂºmeros e sublinhados';

  @override
  String validation_command_name_length(int max) {
    return 'O nome do comando deve ter no mÃƒÂ¡ximo $max caracteres';
  }

  @override
  String get validation_command_name_no_ampersand =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com um e comercial (&)';

  @override
  String get validation_command_name_no_at =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com uma arroba (@)';

  @override
  String get validation_command_name_no_exclamation =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com um ponto de exclamaÃƒÂ§ÃƒÂ£o';

  @override
  String get validation_command_name_no_hash =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com um cerquilha (#)';

  @override
  String get validation_command_name_no_percent =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com um sinal de porcentagem';

  @override
  String get validation_command_name_no_slash =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com uma barra';

  @override
  String get validation_command_name_no_spaces =>
      'O nome do comando nÃƒÂ£o pode conter espaÃƒÂ§os';

  @override
  String get validation_command_name_no_underscore =>
      'O nome do comando nÃƒÂ£o pode comeÃƒÂ§ar com um sublinhado';

  @override
  String get validation_command_name_required =>
      'Por favor, insira um nome para o comando';

  @override
  String get validation_interaction_no_response =>
      'Comandos de interaÃƒÂ§ÃƒÂ£o devem incluir pelo menos uma aÃƒÂ§ÃƒÂ£o de resposta (Responder com mensagem, Componente V2 ou Modal).';

  @override
  String get validation_interaction_no_response_short =>
      'Nenhuma aÃƒÂ§ÃƒÂ£o de resposta';

  @override
  String get validation_invalid_permissions =>
      'Bitfield de permissÃƒÂµes de membro padrÃƒÂ£o invÃƒÂ¡lido. Use um nÃƒÂºmero inteiro positivo ou deixe vazio.';

  @override
  String get validation_legacy_chat_input_only =>
      'O modo legado estÃƒÂ¡ disponÃƒÂ­vel apenas para comandos de entrada de chat.';

  @override
  String get validation_legacy_only_new_or_local =>
      'O modo apenas legado sÃƒÂ³ pode ser usado para novos comandos ou comandos locais existentes.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Comandos apenas legados requerem que o modo legado esteja ativado.';

  @override
  String get validation_modal_not_legacy =>
      'Respostas de modal nÃƒÂ£o sÃƒÂ£o suportadas no modo de comando legado.';

  @override
  String get validation_option_description_required =>
      'Toda opÃƒÂ§ÃƒÂ£o deve ter uma descriÃƒÂ§ÃƒÂ£o.';

  @override
  String get validation_option_group_only_subcommands =>
      'Um SubCommandGroup sÃƒÂ³ pode conter opÃƒÂ§ÃƒÂµes de Subcomando.';

  @override
  String get validation_option_group_top_level_only =>
      'SubCommandGroup sÃƒÂ³ ÃƒÂ© permitido no nÃƒÂ­vel superior.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'Subcomando e Grupo de Subcomandos nÃƒÂ£o podem definir escolhas.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'Subcomando e Grupo de Subcomandos nÃƒÂ£o podem definir valores mÃƒÂ­nimos/mÃƒÂ¡ximos.';

  @override
  String get validation_option_hierarchy_not_required =>
      'Subcomando e Grupo de Subcomandos nÃƒÂ£o podem ser marcados como obrigatÃƒÂ³rios.';

  @override
  String get validation_option_leaf_no_nested =>
      'OpÃƒÂ§ÃƒÂµes regulares nÃƒÂ£o podem conter opÃƒÂ§ÃƒÂµes aninhadas.';

  @override
  String get validation_option_max_entries =>
      'Cada nÃƒÂ­vel de opÃƒÂ§ÃƒÂ£o suporta no mÃƒÂ¡ximo 25 entradas.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Nome de opÃƒÂ§ÃƒÂ£o duplicado \"$name\" no mesmo nÃƒÂ­vel.';
  }

  @override
  String get validation_option_name_required =>
      'Toda opÃƒÂ§ÃƒÂ£o deve ter um nome.';

  @override
  String get validation_option_no_mix_top_level =>
      'OpÃƒÂ§ÃƒÂµes de nÃƒÂ­vel superior nÃƒÂ£o podem misturar subcomandos/grupos com opÃƒÂ§ÃƒÂµes regulares.';

  @override
  String get validation_option_subcommand_depth =>
      'A profundidade de aninhamento do subcomando excede os limites do Discord.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Um Subcomando nÃƒÂ£o pode conter Subcomandos ou Grupos de Subcomandos aninhados.';

  @override
  String get variable_autocomplete_numeric_title =>
      'SugestÃƒÂµes numÃƒÂ©ricas dinÃƒÂ¢micas';

  @override
  String get variable_autocomplete_title =>
      'VariÃƒÂ¡veis disponÃƒÂ­veis Ã¢â‚¬â€ toque para inserir';

  @override
  String get variable_category_author => 'Autor';

  @override
  String get variable_category_bot => 'Bot';

  @override
  String get variable_category_channel => 'Canal';

  @override
  String get variable_category_context => 'Contexto';

  @override
  String get variable_category_functions => 'FunÃƒÂ§ÃƒÂµes';

  @override
  String get variable_category_guild => 'Servidor';

  @override
  String get variable_category_interaction => 'InteraÃƒÂ§ÃƒÂ£o';

  @override
  String get variable_category_member => 'Membro';

  @override
  String get variable_category_message => 'Mensagem';

  @override
  String get variable_category_other => 'Outro';

  @override
  String get variable_category_temp => 'TemporÃƒÂ¡rio';

  @override
  String get variable_category_user => 'UsuÃƒÂ¡rio';

  @override
  String get webhooks_actions => 'AÃƒÂ§ÃƒÂµes';

  @override
  String get webhooks_add_action => 'Adicionar webhook';

  @override
  String get webhooks_add_title => 'Adicionar webhook de entrada';

  @override
  String get webhooks_copied => 'URL completa do webhook copiada.';

  @override
  String get webhooks_copy_path => 'Copiar caminho';

  @override
  String get webhooks_copy_secret => 'Copiar segredo';

  @override
  String get webhooks_copy_url => 'Copiar URL';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhooks: $count$limit';
  }

  @override
  String webhooks_delete_confirm(String label) {
    return 'Excluir \"$label\"? Isso nÃƒÂ£o pode ser desfeito.';
  }

  @override
  String get webhooks_delete_confirm_no_label =>
      'Isso nÃƒÂ£o pode ser desfeito.';

  @override
  String get webhooks_delete_title => 'Excluir webhook de entrada?';

  @override
  String get webhooks_edit_title => 'Editar webhook de entrada';

  @override
  String get webhooks_empty => 'Nenhum webhook de entrada ainda.';

  @override
  String get webhooks_generate => 'Gerar';

  @override
  String get webhooks_invalid_runner_url => 'A URL do Runner ÃƒÂ© invÃƒÂ¡lida.';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Limite de webhooks de entrada atingido ($limit).';
  }

  @override
  String get webhooks_missing_data =>
      'O caminho ou o segredo do webhook estÃƒÂ¡ faltando.';

  @override
  String get webhooks_no_workflows =>
      'Crie pelo menos um fluxo de trabalho antes de adicionar um webhook de entrada.';

  @override
  String get webhooks_page_title => 'Webhooks de Entrada';

  @override
  String get webhooks_path_copied => 'Caminho copiado.';

  @override
  String get webhooks_path_exists =>
      'Este caminho jÃƒÂ¡ existe. Escolha outro.';

  @override
  String get webhooks_path_hint => 'pedidos/novo';

  @override
  String get webhooks_path_label => 'Caminho';

  @override
  String get webhooks_runner_url_required =>
      'Configure uma URL do Runner primeiro para copiar a URL completa do webhook.';

  @override
  String webhooks_save_failed(String error) {
    return 'Falha ao salvar o webhook de entrada: $error';
  }

  @override
  String get webhooks_secret_copied => 'Segredo copiado.';

  @override
  String get webhooks_secret_label => 'Segredo do Webhook';

  @override
  String get webhooks_target_label => 'Alvo do fluxo de trabalho';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'Fluxo: $workflow';
  }

  @override
  String get wizard_advanced_trigger =>
      'ConfiguraÃƒÂ§ÃƒÂµes de gatilho avanÃƒÂ§adas';

  @override
  String get wizard_apply_quick_start =>
      'Aplicar inÃƒÂ­cio rÃƒÂ¡pido ao rascunho';

  @override
  String get wizard_bdfd_mode_enabled => 'Modo de script BDFD ativado';

  @override
  String get wizard_code_advanced => 'CÃƒÂ³digo / AvanÃƒÂ§ado';

  @override
  String get wizard_command_body => 'Corpo do comando';

  @override
  String get wizard_create_command => 'Criar comando';

  @override
  String get wizard_dart_mode_enabled => 'Modo de script Dart ativado';

  @override
  String get wizard_edit_reply => 'Editar detalhes da resposta';

  @override
  String get wizard_legacy_options_subtitle =>
      'OpÃƒÂ§ÃƒÂµes de comando legado e comportamento apenas local';

  @override
  String get wizard_quick_start_applied =>
      'InÃƒÂ­cio rÃƒÂ¡pido aplicado ao rascunho do comando.';

  @override
  String get wizard_quick_start_subtitle =>
      'Use o construtor simples legado como ponto de partida e aplique-o ao rascunho compartilhado.';

  @override
  String get wizard_quick_starts => 'InÃƒÂ­cios rÃƒÂ¡pidos';

  @override
  String get wizard_reply_summary => 'Resumo da resposta';

  @override
  String get wizard_save_command => 'Salvar comando';

  @override
  String get wizard_step_actions => 'AÃƒÂ§ÃƒÂµes';

  @override
  String get wizard_step_infos => 'InformaÃƒÂ§ÃƒÂµes';

  @override
  String get wizard_step_reply => 'Resposta';

  @override
  String get wizard_step_review => 'Revisar';

  @override
  String get wizard_step_trigger_inputs => 'Gatilho e Entradas';

  @override
  String get wizard_visual_mode_enabled => 'Modo de fluxo visual ativado';

  @override
  String get workflow_argument_hint =>
      'Argumento do workflow (acessÃƒÂ­vel via \$arg)';

  @override
  String get workflow_arguments_section => 'Argumentos do Fluxo';

  @override
  String get workflow_auto_defer => 'Auto deferir';

  @override
  String get workflow_auto_defer_actions =>
      'Auto deferir se houver aÃƒÂ§ÃƒÂµes';

  @override
  String get workflow_bdfd_editor_desc =>
      'Escreva o cÃƒÂ³digo BDFD completo para a resposta deste workflow. Os diagnÃƒÂ³sticos sÃƒÂ£o exibidos ao vivo.';

  @override
  String get workflow_bdfd_editor_title => 'Editor de Script BDFD';

  @override
  String get workflow_condition_off => 'CondiÃƒÂ§ÃƒÂ£o desativada';

  @override
  String get workflow_condition_off_upper => 'CONDIÃƒâ€¡ÃƒÆ’O DESATIVADA';

  @override
  String get workflow_condition_on => 'CondiÃƒÂ§ÃƒÂ£o ativada';

  @override
  String get workflow_condition_on_upper => 'CONDIÃƒâ€¡ÃƒÆ’O ATIVADA';

  @override
  String get workflow_dart_editor_desc =>
      'Escreva cÃƒÂ³digo Dart completo para a resposta deste workflow. Os diagnÃƒÂ³sticos sÃƒÂ£o exibidos ao vivo.';

  @override
  String get workflow_dart_editor_title => 'Editor de Script Dart';

  @override
  String workflow_edit_call_args(int count) {
    return 'Editar Argumentos de Chamada ($count)';
  }

  @override
  String get workflow_entry_point => 'Ponto de Entrada';

  @override
  String get workflow_entry_point_helper =>
      'Padroniza para o ponto de entrada do workflow quando vazio';

  @override
  String get workflow_entry_point_optional => 'Ponto de Entrada (opcional)';

  @override
  String get workflow_hint_name => 'ex: handle_form_submit';

  @override
  String get workflow_manual => 'Manual';

  @override
  String get workflow_mode_bdfd => 'Script BDFD';

  @override
  String get workflow_mode_bdfd_note =>
      'Escreva todo o seu workflow como um ÃƒÂºnico script BDFD. O script ÃƒÂ© compilado e validado em tempo real.';

  @override
  String get workflow_mode_dart => 'Dart Direto';

  @override
  String get workflow_mode_dart_note =>
      'Escreva o seu workflow em Dart. Os diagnÃƒÂ³sticos sÃƒÂ£o atualizados durante a ediÃƒÂ§ÃƒÂ£o para detetar erros precocemente.';

  @override
  String get workflow_mode_desc =>
      'Escolha entre um construtor de aÃƒÂ§ÃƒÂµes visual ou um editor de script BDFD completo.';

  @override
  String get workflow_mode_title => 'Modo Workflow';

  @override
  String get workflow_mode_visual => 'Visual';

  @override
  String get workflow_mode_visual_note =>
      'Construa o seu workflow visualmente adicionando aÃƒÂ§ÃƒÂµes individuais com o editor de cartÃƒÂµes.';

  @override
  String get workflow_no_auto_defer => 'NÃƒÂ£o auto deferir';

  @override
  String get workflow_no_workflow_note =>
      'Nota: Se nenhum workflow for selecionado, o envio deste modal nÃƒÂ£o farÃƒÂ¡ nada.';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'Ao enviar, o workflow \"$name\" serÃƒÂ¡ executado (entrada: $entry, args: $args).';
  }

  @override
  String get workflow_root_json_error => 'A raiz deve ser um objeto JSON';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" salvo ($count aÃƒÂ§ÃƒÂ£o(ÃƒÂµes)).';
  }

  @override
  String get workflow_set_call_args => 'Definir Argumentos de Chamada';

  @override
  String get workflow_visibility_ephemeral => 'EfÃƒÂªmero';

  @override
  String get workflow_visibility_public => 'PÃƒÂºblico';

  @override
  String get workflows_add_arg => 'Adicionar argumento';

  @override
  String get workflows_arg_default => 'Valor padrÃƒÂ£o';

  @override
  String get workflows_arg_hint =>
      'Argumentos tornam-se variÃƒÂ¡veis de execuÃƒÂ§ÃƒÂ£o como ((arg.name)) e ((workflow.arg.name)).';

  @override
  String get workflows_arg_name => 'Nome';

  @override
  String get workflows_arg_required_short => 'Req';

  @override
  String get workflows_arguments => 'Argumentos';

  @override
  String get workflows_continue => 'Continuar';

  @override
  String get workflows_copy_done_base64 => 'Workflows copiados como Base64.';

  @override
  String get workflows_copy_done_json => 'Workflows copiados como JSON.';

  @override
  String get workflows_copy_none => 'Nenhum workflow para copiar.';

  @override
  String get workflows_create => 'Criar Workflow';

  @override
  String workflows_delete_confirm(String name) {
    return 'Tem a certeza que deseja apagar \"$name\"? Esta aÃƒÂ§ÃƒÂ£o nÃƒÂ£o pode ser desfeita.';
  }

  @override
  String get workflows_delete_title => 'Apagar workflow';

  @override
  String get workflows_docs_tooltip => 'Abrir centro de documentaÃƒÂ§ÃƒÂ£o';

  @override
  String get workflows_edit => 'Editar Workflow';

  @override
  String get workflows_empty => 'Ainda nÃƒÂ£o hÃƒÂ¡ workflows';

  @override
  String get workflows_entry_point => 'Ponto de Entrada PadrÃƒÂ£o';

  @override
  String get workflows_entry_point_hint =>
      'Usado se quem chama nÃƒÂ£o o substituir';

  @override
  String get workflows_event_available_vars => 'VariÃƒÂ¡veis disponÃƒÂ­veis';

  @override
  String get workflows_event_category => 'Categoria do evento';

  @override
  String get workflows_event_category_channels => 'Canais';

  @override
  String get workflows_event_category_invites => 'Convites';

  @override
  String get workflows_event_category_members => 'Membros';

  @override
  String get workflows_event_category_messages => 'Mensagens';

  @override
  String get workflows_event_channel_update => 'Canal Atualizado';

  @override
  String get workflows_event_channel_update_desc =>
      'Ativado sempre que um canal ÃƒÂ© atualizado.';

  @override
  String get workflows_event_hint =>
      'Escolha o evento do Discord que deve ativar este workflow.';

  @override
  String get workflows_event_invite_create => 'Convite Criado';

  @override
  String get workflows_event_invite_create_desc =>
      'Ativado sempre que um convite ÃƒÂ© criado.';

  @override
  String get workflows_event_member_join => 'Membro Entrou';

  @override
  String get workflows_event_member_join_desc =>
      'Ativado sempre que um membro entra no servidor.';

  @override
  String get workflows_event_member_remove => 'Membro Saiu';

  @override
  String get workflows_event_member_remove_desc =>
      'Ativado sempre que um membro sai ou ÃƒÂ© removido do servidor.';

  @override
  String get workflows_event_message_create => 'Mensagem Criada';

  @override
  String get workflows_event_message_create_desc =>
      'Ativado sempre que uma nova mensagem ÃƒÂ© criada.';

  @override
  String get workflows_event_message_delete => 'Mensagem Apagada';

  @override
  String get workflows_event_message_delete_desc =>
      'Ativado sempre que uma mensagem ÃƒÂ© apagada.';

  @override
  String get workflows_event_message_update => 'Mensagem Atualizada';

  @override
  String get workflows_event_message_update_desc =>
      'Ativado sempre que uma mensagem existente ÃƒÂ© editada.';

  @override
  String workflows_event_preview(String event) {
    return 'Ouvir por: $event';
  }

  @override
  String get workflows_event_section => 'Workflows de Eventos';

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count aÃƒÂ§ÃƒÂ£o(ÃƒÂµes) Ã¢â‚¬Â¢ Ouvir por: $event';
  }

  @override
  String get workflows_export_base64 => 'Copiar como Base64';

  @override
  String get workflows_export_base64_desc =>
      'Conveniente para partilha compacta.';

  @override
  String get workflows_export_json => 'Copiar como JSON';

  @override
  String get workflows_export_json_desc => 'LegÃƒÂ­vel e fÃƒÂ¡cil de editar.';

  @override
  String get workflows_export_tooltip => 'Copiar workflows';

  @override
  String get workflows_folder_hint => 'Nome da pasta opcional';

  @override
  String get workflows_folder_label => 'Pasta';

  @override
  String get workflows_general_section => 'Workflows Gerais';

  @override
  String get workflows_import_action => 'Importar';

  @override
  String get workflows_import_desc =>
      'Cole um payload JSON ou Base64(JSON) exportado do Bot Creator.';

  @override
  String workflows_import_done(int count) {
    return '$count workflow(s) importado(s).';
  }

  @override
  String get workflows_import_empty => 'Sem dados para importar.';

  @override
  String get workflows_import_input_hint => 'Cole o JSON ou Base64 aqui...';

  @override
  String get workflows_import_invalid_format =>
      'Formato invÃƒÂ¡lido. Use JSON ou Base64(JSON).';

  @override
  String get workflows_import_no_valid =>
      'Nenhum workflow vÃƒÂ¡lido encontrado.';

  @override
  String get workflows_import_overwrite =>
      'Substituir quando o nome jÃƒÂ¡ existir';

  @override
  String get workflows_import_title => 'Importar workflows';

  @override
  String get workflows_import_tooltip => 'Importar workflows';

  @override
  String get workflows_listen_for => 'Ouvir por';

  @override
  String get workflows_move_to_folder => 'Mover para pasta';

  @override
  String get workflows_name => 'Nome do Workflow';

  @override
  String get workflows_new_folder_hint => 'Nome da nova pasta';

  @override
  String get workflows_no_match =>
      'Nenhum workflow corresponde aos filtros atuais.';

  @override
  String get workflows_no_matches =>
      'Nenhum workflow corresponde aos filtros atuais.';

  @override
  String get workflows_remove_from_folder => 'Remover da pasta';

  @override
  String get workflows_search_hint => 'Pesquisar workflows...';

  @override
  String workflows_subtitle(int count, String entry, String args) {
    return '$count aÃƒÂ§ÃƒÂ£o(ÃƒÂµes) Ã¢â‚¬Â¢ entrada: $entry Ã¢â‚¬Â¢ args: $args';
  }

  @override
  String get workflows_tab => 'Fluxos';

  @override
  String get workflows_tab_short => 'Fluxo';

  @override
  String get workflows_title => 'Workflows';

  @override
  String get workflows_type_badge_event => 'Evento';

  @override
  String get workflows_type_badge_general => 'Geral';

  @override
  String get workflows_type_event => 'Workflow de evento';

  @override
  String get workflows_type_event_desc =>
      'Reage automaticamente quando o Discord emite um evento.';

  @override
  String get workflows_type_general => 'Workflow geral';

  @override
  String get workflows_type_general_desc =>
      'LÃƒÂ³gica reutilizÃƒÂ¡vel chamada por comandos, botÃƒÂµes, modais ou outros workflows.';

  @override
  String get workflows_type_title => 'Tipo de Workflow';

  @override
  String get settings_sync_title => 'SincronizaÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_sync_force_title =>
      'ForÃƒÂ§ar SincronizaÃƒÂ§ÃƒÂ£o de Comandos';

  @override
  String get settings_sync_force_desc =>
      'Exclui todos os comandos slash do Discord que nÃƒÂ£o estÃƒÂ£o definidos localmente no Bot Creator.';

  @override
  String get settings_sync_force_button => 'Sincronizar com o Discord';

  @override
  String get settings_sync_force_dialog_title =>
      'ForÃƒÂ§ar SincronizaÃƒÂ§ÃƒÂ£o';

  @override
  String get settings_sync_force_dialog_desc =>
      'Isso excluirÃƒÂ¡ todos os comandos slash no Discord que nÃƒÂ£o estÃƒÂ£o definidos localmente no Bot Creator. Tem certeza de que deseja continuar?';

  @override
  String get settings_sync_force_dialog_confirm => 'ForÃƒÂ§ar';

  @override
  String settings_sync_force_success(Object count) {
    return 'SincronizaÃƒÂ§ÃƒÂ£o forÃƒÂ§ada concluÃƒÂ­da com sucesso. $count comando(s) legado(s)/nÃƒÂ£o rastreado(s) excluÃƒÂ­do(s) do Discord.';
  }

  @override
  String settings_sync_force_error(Object error) {
    return 'Falha ao forÃƒÂ§ar sincronizaÃƒÂ§ÃƒÂ£o: $error';
  }

  @override
  String get app_create_select_type_title =>
      'Selecionar Tipo de AplicaÃƒÂ§ÃƒÂ£o';

  @override
  String get app_create_select_type_desc =>
      'Escolha o tipo de aplicaÃƒÂ§ÃƒÂ£o que deseja criar para comeÃƒÂ§ar.';

  @override
  String get app_create_type_discord => 'Bot do Discord';

  @override
  String get app_create_type_discord_desc =>
      'Crie e configure um bot do Discord personalizÃƒÂ¡vel com aÃƒÂ§ÃƒÂµes, eventos e camadas de canvas.';

  @override
  String get app_create_type_hosted => 'AplicaÃƒÂ§ÃƒÂ£o Hospedada (Docker)';

  @override
  String get app_create_type_hosted_desc =>
      'Execute uma aplicaÃƒÂ§ÃƒÂ£o backend, servidor ou script na sua linguagem favorita (NodeJS, Python, Java...). Envie arquivos e instale pacotes em um contÃƒÂªiner seguro.';

  @override
  String get app_create_coming_soon => 'Em breve';

  @override
  String get app_create_sample_title => 'Criar comando de exemplo';

  @override
  String app_create_sample_desc(String botName) {
    return 'Gostaria de adicionar um comando /ping de exemplo ao $botName? Ele responde com \"Pong!\" e ÃƒÂ© um ÃƒÂ³timo ponto de partida para aprender como o Bot Creator funciona.';
  }

  @override
  String get app_create_sample_skip => 'Pular';

  @override
  String get app_create_sample_confirm => 'Adicionar /ping de exemplo';

  @override
  String get app_create_sample_success => 'Comando /ping criado com sucesso!';

  @override
  String get commands_empty_title => 'Crie seu primeiro comando!';

  @override
  String get commands_empty_description =>
      'Um comando permite que seu bot responda quando alguÃƒÂ©m digita /algo no Discord.';

  @override
  String get commands_empty_create_button => 'Criar um comando';

  @override
  String get commands_empty_marketplace_link =>
      'Ou comece com um template do Marketplace';

  @override
  String get command_created_success_title => 'Seu comando estÃƒÂ¡ pronto!';

  @override
  String get command_created_success_subtitle =>
      'O que vocÃƒÂª quer fazer agora?';

  @override
  String get command_created_start_bot => 'Iniciar meu bot';

  @override
  String get command_created_start_bot_hint =>
      'Abra a aba InÃƒÂ­cio do seu bot e toque em Iniciar para colocÃƒÂ¡-lo online.';

  @override
  String get command_created_invite => 'Convidar para um servidor';

  @override
  String get command_created_invite_error =>
      'NÃƒÂ£o foi possÃƒÂ­vel abrir o link de convite.';

  @override
  String get command_created_create_another => 'Criar outro comando';

  @override
  String get command_created_close => 'Fechar';

  @override
  String get beginner_mode_label => 'Modo iniciante';

  @override
  String get beginner_mode_on_hint => 'Mostrando apenas abas essenciais';

  @override
  String get beginner_mode_off_hint => 'Mostrando todos os recursos';

  @override
  String get commands_empty_sample_ping => 'Adicionar comando /ping de exemplo';

  @override
  String get command_created_sample_success =>
      'Comando /ping criado! Ele responde \"Pong!\"';

  @override
  String get onboarding_create_now => 'Criar meu bot agora';

  @override
  String get onboarding_command_now => 'Crie seu primeiro comando';

  @override
  String get container_list_title => 'AplicaÃ§Ãµes Hospedadas';

  @override
  String get container_list_session_missing => 'SessÃ£o indisponÃ­vel';

  @override
  String get container_list_session_hint =>
      'Por favor, conecte-se Ã  sua conta primeiro.';

  @override
  String get container_list_error => 'Falha ao carregar contÃªineres';

  @override
  String get container_list_retry => 'Tentar novamente';

  @override
  String get container_list_empty => 'Nenhuma aplicaÃ§Ã£o hospedada';

  @override
  String get container_list_empty_hint =>
      'Implante sua primeira aplicaÃ§Ã£o para comeÃ§ar.';

  @override
  String get container_list_deploy_btn => 'Implantar AplicaÃ§Ã£o';

  @override
  String get container_list_expired => 'Expirado';

  @override
  String container_list_expiry_minutes(int minutes) {
    return '${minutes}m restantes';
  }

  @override
  String container_list_expiry_hours(int hours, int minutes) {
    return '${hours}h ${minutes}m restantes';
  }

  @override
  String container_list_expiry_days(int days, int hours) {
    return '${days}d ${hours}h restantes';
  }

  @override
  String get container_deploy_title => 'Implantar AplicaÃ§Ã£o';

  @override
  String get container_deploy_image_label => 'Imagem';

  @override
  String get container_deploy_image_hint => 'Nome da imagem Docker com tag';

  @override
  String get container_deploy_image_required => 'Imagem Ã© obrigatÃ³ria';

  @override
  String get container_deploy_cpu_label => 'CPU (millis)';

  @override
  String get container_deploy_cpu_min => 'MÃ­n 128';

  @override
  String get container_deploy_memory_label => 'MemÃ³ria (MB)';

  @override
  String get container_deploy_memory_min => 'MÃ­n 128 MB';

  @override
  String get container_deploy_storage_label => 'Armazenamento (GB)';

  @override
  String get container_deploy_storage_min => 'MÃ­n 1 GB';

  @override
  String get container_deploy_ttl_label => 'TTL (minutos)';

  @override
  String get container_deploy_ttl_min => 'MÃ­n 1 minuto';

  @override
  String get container_deploy_env_label => 'VariÃ¡veis de Ambiente';

  @override
  String get container_deploy_env_key_hint => 'CHAVE';

  @override
  String get container_deploy_env_value_hint => 'valor';

  @override
  String get container_deploy_submit => 'Implantar';

  @override
  String get container_deploy_submitting => 'Implantando...';

  @override
  String get container_deploy_not_auth => 'NÃ£o autenticado';

  @override
  String container_deploy_success(String containerId) {
    return 'Implantando $containerId...';
  }

  @override
  String container_deploy_failed(String error) {
    return 'Falha na implantaÃ§Ã£o: $error';
  }

  @override
  String get container_detail_state => 'Estado';

  @override
  String get container_detail_expires => 'Expira em';

  @override
  String get container_detail_extend_ttl => 'Estender TTL';

  @override
  String get container_detail_stop_title => 'Parar ContÃªiner';

  @override
  String get container_detail_stop_confirm =>
      'Isso encerrarÃ¡ o contÃªiner e seus dados serÃ£o perdidos.';

  @override
  String get container_detail_stop_btn => 'Parar';

  @override
  String get container_detail_stopped_ok => 'ContÃªiner parado';

  @override
  String get container_detail_update_resources => 'Atualizar Recursos';

  @override
  String get container_detail_update_btn => 'Atualizar';

  @override
  String get container_detail_updated_ok => 'Recursos atualizados';

  @override
  String get container_detail_extend_hint => 'Minutos para adicionar';

  @override
  String get container_detail_extend_btn => 'Estender';

  @override
  String get container_detail_extended_ok => 'TTL estendida';

  @override
  String get container_detail_console => 'Console';

  @override
  String get container_detail_deploying =>
      'ContÃªiner estÃ¡ sendo implantado...';

  @override
  String container_detail_status_stopped(String state) {
    return 'Este contÃªiner estÃ¡ $state.';
  }

  @override
  String get container_detail_not_connected => 'NÃ£o conectado';

  @override
  String get container_detail_console_connecting => 'Conectando...';

  @override
  String get container_detail_console_closed => '--- ConexÃ£o fechada ---';

  @override
  String get container_detail_console_hint => 'Digite um comando...';

  @override
  String container_detail_failed(String error) {
    return 'Falha: $error';
  }

  @override
  String get container_state_running => 'Em execuÃ§Ã£o';

  @override
  String get container_state_pending => 'Pendente';

  @override
  String get container_state_stopped => 'Parado';

  @override
  String get container_state_stopping => 'Parando';

  @override
  String get container_state_failed => 'Falhou';

  @override
  String get container_hosted_subtitle =>
      'Implante e gerencie contÃªineres Docker';

  @override
  String get container_premium_badge => 'Premium';

  @override
  String container_detail_title(String id) {
    return 'Contêiner $id';
  }
}
