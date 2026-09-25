// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get app_update_dialog_title => 'Nova versão disponível';

  @override
  String app_update_dialog_message(String version, String installed) {
    return 'A versão $version está disponível na loja (você usa a $installed). Atualize para receber as últimas correções.';
  }

  @override
  String get app_update_later => 'Mais tarde';

  @override
  String get app_update_update_now => 'Atualizar';

  @override
  String get app_update_store_open_failed =>
      'Não foi possível abrir a página da loja.';

  @override
  String get app_update_download_started =>
      'Download em segundo plano — você pode continuar usando o aplicativo.';

  @override
  String get bot_token_import_btn => 'Importar o token da minha conta';

  @override
  String get bot_token_import_missing => 'Este bot não existe na sua conta.';

  @override
  String get bot_token_import_network =>
      'Servidor inacessível: verifique a sua ligação e tente novamente.';

  @override
  String get bot_token_import_no_account =>
      'Nenhuma conta está ligada neste dispositivo: inicie sessão para importar o token.';

  @override
  String get bot_token_import_not_stored =>
      'Nenhum token está guardado na sua conta: introduza-o uma vez aqui.';

  @override
  String get bot_token_import_server_cannot_read =>
      'O servidor não consegue reler o token guardado.';

  @override
  String get bot_token_import_server_unsupported =>
      'Este servidor ainda não disponibiliza a importação do token — atualize ou reimplante-o.';

  @override
  String get bot_token_import_success =>
      'Token importado da sua conta: a ligação foi restabelecida.';

  @override
  String get container_invite_server_unsupported =>
      'Este servidor ainda não disponibiliza o convite do bot — atualize ou reimplante-o.';

  @override
  String get container_invite_missing =>
      'Este contentor já não existe no servidor — recarrega a lista de contentores.';

  @override
  String get settings_app_update_title => 'Atualizações';

  @override
  String settings_app_update_installed_version(String version, String build) {
    return '$version (build $build)';
  }

  @override
  String settings_app_version_value(String version) {
    return 'App: $version';
  }

  @override
  String settings_runner_version_value(String version) {
    return 'Runner: $version';
  }

  @override
  String get settings_app_update_check_button => 'Verificar atualizações';

  @override
  String get settings_app_update_checking => 'Verificando…';

  @override
  String get settings_app_update_up_to_date =>
      'Você está na versão mais recente.';

  @override
  String settings_app_update_available(String version) {
    return 'A versão $version está disponível na loja.';
  }

  @override
  String get settings_app_update_unavailable =>
      'Não foi possível verificar atualizações agora.';

  @override
  String get settings_app_update_unsupported =>
      'As atualizações só podem ser verificadas no aplicativo Android ou iOS.';

  @override
  String get settings_app_update_open_store => 'Abrir página da loja';

  @override
  String get action_add_else_if => 'Adicionar ELSE IF';

  @override
  String get action_add_header => 'Adicionar cabeçalho';

  @override
  String get action_add_new_item => 'Adicionar novo item';

  @override
  String get action_advanced_settings => 'Configurações avançadas';

  @override
  String action_and_more(int count) {
    return '… e mais $count';
  }

  @override
  String get action_bulk_import_hint =>
      'Importação em massa (Cole cabeçalhos como Chave: Valor)';

  @override
  String get action_cannot_format_json =>
      'Não é possível formatar: JSON Inválido';

  @override
  String get action_category_channels => 'Canais';

  @override
  String get action_category_components => 'Componentes';

  @override
  String get action_category_guild_members => 'Servidor & Membros';

  @override
  String get action_category_http_variables => 'HTTP & Variáveis';

  @override
  String get action_category_interactions => 'Interações';

  @override
  String get action_category_logic_flow => 'Lógica & Fluxo';

  @override
  String get action_category_messages => 'Mensagens';

  @override
  String get action_category_moderation => 'Moderação';

  @override
  String get action_category_music => 'Música';

  @override
  String get action_category_reactions => 'Reações';

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
  String get action_condition_value => 'Valor da Condição';

  @override
  String get action_condition_variable => 'Variável de Condição';

  @override
  String get action_description_addReaction =>
      'Adiciona uma reação de emoji a uma mensagem';

  @override
  String get action_description_addRole => 'Atribui um cargo a um membro';

  @override
  String get action_description_addThreadMember =>
      'Adicionar um membro a um tópico';

  @override
  String get action_description_appendArrayElement =>
      'Adicionar um novo elemento em uma matriz JSON global ou de escopo';

  @override
  String get action_description_attachImage =>
      'Anexar um arquivo de imagem à resposta da mensagem (URL, URL de dados ou base64)';

  @override
  String get action_description_banUser =>
      'Bane permanentemente um usuário do servidor';

  @override
  String get action_description_calculate =>
      'Realizar operações matemáticas e armazenar o resultado';

  @override
  String get action_description_canvasCreateBlock =>
      'Criar uma tela de imagem em branco';

  @override
  String get action_description_canvasDrawCircleBlock =>
      'Desenhar um círculo na tela de imagem';

  @override
  String get action_description_canvasDrawLineBlock =>
      'Desenhar uma linha na tela';

  @override
  String get action_description_canvasDrawRectBlock =>
      'Desenhar um retângulo na tela de imagem';

  @override
  String get action_description_canvasDrawTextBlock =>
      'Desenhar texto na tela de imagem com opções de estilo';

  @override
  String get action_description_canvasLoadImageBlock =>
      'Carregar uma imagem de uma URL ou origem na tela';

  @override
  String get action_description_clearAllReactions =>
      'Remove todas as reações de uma mensagem';

  @override
  String get action_description_cooldown =>
      'Aplica um tempo de espera para o usuário ou servidor';

  @override
  String get action_description_createAutoModRule =>
      'Criar uma regra de moderação automática no servidor';

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
      'Criar um tópico em um canal de texto suportado';

  @override
  String get action_description_debugProfile =>
      'Gerar perfil de execução e informações de diagnóstico';

  @override
  String get action_description_deferInteraction =>
      'Adiar a resposta da interação para evitar expiração do Discord';

  @override
  String get action_description_deleteAutoModRule =>
      'Excluir uma regra de moderação automática';

  @override
  String get action_description_deleteChannelPermission =>
      'Excluir uma sobreposição de permissão de canal';

  @override
  String get action_description_deleteEmoji => 'Excluir um emoji de servidor';

  @override
  String get action_description_deleteInvite =>
      'Excluir um convite existente por código';

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
      'Criar ou atualizar sobreposições de permissão de canal';

  @override
  String get action_description_editComponentV2 =>
      'Editar componentes existentes';

  @override
  String get action_description_editInteractionMessage =>
      'Editar a resposta da interação adiada ou original';

  @override
  String get action_description_editMessage => 'Edita uma mensagem existente';

  @override
  String get action_description_editWebhook => 'Editar um Webhook existente';

  @override
  String get action_description_endPoll =>
      'Encerrar uma enquete ativa imediatamente';

  @override
  String get action_description_forLoop =>
      'Repetir por um intervalo de números (loop for)';

  @override
  String get action_description_getGlobalVariable =>
      'Ler uma variável global e injetar nas variáveis de execução';

  @override
  String get action_description_getGuildOnboarding =>
      'Buscar a configuração de integração atual do servidor';

  @override
  String get action_description_getInvite =>
      'Buscar informações do convite por código';

  @override
  String get action_description_getMember => 'Obter informações do membro';

  @override
  String get action_description_getMessage =>
      'Buscar uma mensagem e expor seus campos';

  @override
  String get action_description_getMusicInfo =>
      'Obter informações sobre a música que está tocando';

  @override
  String get action_description_getScopedVariable =>
      'Ler uma variável de escopo e injetar nas variáveis de execução';

  @override
  String get action_description_getWebhook =>
      'Obter informações do Webhook por ID';

  @override
  String get action_description_httpRequest =>
      'Enviar requisição HTTP com URL, método, cabeçalhos e corpo dinâmicos';

  @override
  String get action_description_ifBlock =>
      'Ramificação condicional: executar ações diferentes com base em uma condição';

  @override
  String get action_description_jumpToAction =>
      'Saltar para uma ação específica por chave, ID ou posição';

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
      'Listar todas as regras de moderação automática no servidor';

  @override
  String get action_description_listMembers =>
      'Listar membros em um servidor com opções';

  @override
  String get action_description_listScopedVariableIndex =>
      'Listar valores de escopo indexados ordenados por valor com deslocamento e limite';

  @override
  String get action_description_listWebhooks =>
      'Listar todos os Webhooks em um canal ou servidor';

  @override
  String get action_description_listenAndExecute =>
      'Registrar um fluxo de trabalho para rodar quando um botão for clicado, um menu de seleção for usado ou um modal for enviado';

  @override
  String get action_description_listenForButtonClick =>
      'Registrar um fluxo de trabalho para rodar quando um botão for clicado';

  @override
  String get action_description_listenForModalSubmit =>
      'Registrar um fluxo de trabalho para rodar quando um modal for enviado';

  @override
  String get action_description_listenForSelectMenu =>
      'Registrar um fluxo de trabalho para rodar quando um menu de seleção for usado';

  @override
  String get action_description_log =>
      'Imprimir ou armazenar mensagem de diagnóstico nos registros de ação';

  @override
  String get action_description_moveToVoiceChannel =>
      'Mover um membro para um canal de voz específico';

  @override
  String get action_description_muteUser =>
      'Exclui temporariamente (timeout) um membro';

  @override
  String get action_description_pauseMusic => 'Pausar a música atual';

  @override
  String get action_description_pinMessage => 'Fixar uma mensagem em um canal';

  @override
  String get action_description_playMusic =>
      'Tocar uma música por pesquisa ou URL';

  @override
  String get action_description_queryArray =>
      'Filtrar, ordenar e paginar qualquer matriz JSON de execução';

  @override
  String get action_description_randomChoice =>
      'Escolhe um item aleatório de uma lista e armazena em uma variável';

  @override
  String get action_description_registerGuildCommands =>
      'Registrar comandos de aplicativo em um servidor';

  @override
  String get action_description_removeArrayElement =>
      'Remover um elemento de uma matriz JSON global ou de escopo por índice';

  @override
  String get action_description_removeChannel => 'Excluir um canal';

  @override
  String get action_description_removeGlobalVariable =>
      'Excluir uma variável global';

  @override
  String get action_description_removeReaction =>
      'Remove uma reação de uma mensagem';

  @override
  String get action_description_removeRole => 'Remove um cargo de um membro';

  @override
  String get action_description_removeScopedVariable =>
      'Excluir uma variável de escopo';

  @override
  String get action_description_removeThreadMember =>
      'Remover um membro de um tópico';

  @override
  String get action_description_renameScopedVariable =>
      'Renomear a chave de uma variável de escopo';

  @override
  String get action_description_respondWithAutocomplete =>
      'Responder a uma interação de preenchimento automático do Discord com até 25 escolhas dinâmicas';

  @override
  String get action_description_respondWithComponentV2 =>
      'Responder ao comando com botões/menus de seleção';

  @override
  String get action_description_respondWithMessage =>
      'Responder ao comando com uma mensagem normal';

  @override
  String get action_description_respondWithModal =>
      'Mostrar uma caixa de diálogo modal ao usuário';

  @override
  String get action_description_resumeMusic => 'Retomar uma música pausada';

  @override
  String get action_description_runBdfdScript =>
      'Compilar e executar um script BDFD em linha como ações de fluxo de trabalho';

  @override
  String get action_description_runWorkflow =>
      'Executar um fluxo de trabalho salvo (suporta ponto de entrada + argumentos)';

  @override
  String get action_description_runtimeImageBlock =>
      'Executar um bloco de ações de processamento de tela de imagem';

  @override
  String get action_description_runtimeJsonBlock =>
      'Executar um bloco de ações de processamento JSON';

  @override
  String get action_description_seekMusic =>
      'Ir para uma posição específica na música atual';

  @override
  String get action_description_sendComponentV2 =>
      'Enviar componentes interativos';

  @override
  String get action_description_sendDm =>
      'Envia uma mensagem privada para um usuário específico';

  @override
  String get action_description_sendMessage =>
      'Envia uma mensagem para um canal específico';

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
      'Criar ou atualizar uma variável global para este bot';

  @override
  String get action_description_setMusicLoop =>
      'Ativar ou desativar a repetição da fila';

  @override
  String get action_description_setMusicVolume =>
      'Ajustar o volume do reprodutor (0 a 200)';

  @override
  String get action_description_setNickname =>
      'Altera o apelido de um membro do servidor';

  @override
  String get action_description_setScopedVariable =>
      'Criar ou atualizar uma variável de escopo (servidor/usuário/canal/membro/mensagem)';

  @override
  String get action_description_setTemporaryVariable =>
      'Criar ou atualizar uma variável temporária na execução local';

  @override
  String get action_description_skipActions =>
      'Saltar um número especificado de ações seguintes';

  @override
  String get action_description_skipMusic =>
      'Pular para a próxima música na fila';

  @override
  String get action_description_slowmode =>
      'Define a duração do modo lento para um canal';

  @override
  String get action_description_stop =>
      'Para imediatamente a execução do fluxo atual';

  @override
  String get action_description_stopMusic =>
      'Parar a reprodução e limpar a fila';

  @override
  String get action_description_stopUnless =>
      'Parar o fluxo de trabalho se uma condição não for atendida (guarda/filtro)';

  @override
  String get action_description_unbanUser => 'Revoga o banimento de um usuário';

  @override
  String get action_description_unmuteUser =>
      'Remove a exclusão temporária de um membro';

  @override
  String get action_description_unpinMessage =>
      'Desafixar uma mensagem em um canal';

  @override
  String get action_description_unregisterGuildCommands =>
      'Cancelar registro de comandos de aplicativo em um servidor';

  @override
  String get action_description_updateAutoMod =>
      'Atualizar configurações de moderação automática';

  @override
  String get action_description_updateChannel =>
      'Atualizar as configurações do canal';

  @override
  String get action_description_updateEmoji =>
      'Atualizar o nome do emoji ou acesso a cargos no servidor';

  @override
  String get action_description_updateGuild =>
      'Atualizar as configurações do servidor';

  @override
  String get action_description_updateGuildOnboarding =>
      'Atualizar a configuração de integração do servidor';

  @override
  String get action_description_updateSelfUser =>
      'Atualizar o perfil do próprio bot (nome de usuário/avatar)';

  @override
  String get action_description_wait =>
      'Pausa a execução do fluxo por uma duração específica';

  @override
  String get action_dynamic => 'Dinâmico';

  @override
  String get action_dynamic_bool_hint => 'true/false ou ((variável))';

  @override
  String action_dynamic_id_hint(String type) {
    return '$type dinâmico (suporta ((...)))';
  }

  @override
  String get action_dynamic_multiselect_hint =>
      'Valor dinâmico (suporta ((...)))';

  @override
  String get action_dynamic_numeric => 'Sugestões numéricas dinâmicas';

  @override
  String get action_dynamic_variable => 'Sugestões de variáveis dinâmicas';

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
    return 'ELSE IF $index — ações';
  }

  @override
  String get action_error_continue => 'Continuar';

  @override
  String get action_error_stop => 'Parar';

  @override
  String get action_expression => 'Expressão';

  @override
  String get action_format_json => 'Formatar JSON';

  @override
  String get action_hint_color => '#FFFFFF ou rgb(255,255,255)';

  @override
  String get action_hint_condition_value => 'Valor para comparar';

  @override
  String get action_hint_condition_var =>
      'Use ((nomeVariavel)) ou um valor de tempo de execução';

  @override
  String get action_hint_cooldown_error =>
      'Mensagem de erro personalizada (suporta %time%)';

  @override
  String get action_hint_cooldown_time => 'Tempo (ex: 10s, 1m)';

  @override
  String get action_hint_duration => 'ex: 5m, 1h, 30s';

  @override
  String get action_hint_emoji => 'Emoji (ex. 🪜) ou <:nome:id>';

  @override
  String action_hint_enter_type(String type) {
    return 'Digite $type';
  }

  @override
  String get action_hint_random_choices =>
      'Lista de escolhas (separadas por ;)';

  @override
  String get action_hint_random_var =>
      'Nome da variável para armazenar o resultado';

  @override
  String get action_hint_variable_key => 'Selecionar chave de variável';

  @override
  String get action_hint_workflow => 'Nome do workflow salvo';

  @override
  String get action_http_headers_title => 'Cabeçalhos HTTP (Pares Chave/Valor)';

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
      'Enviar Requisição de Teste e Detectar Rotas';

  @override
  String get action_http_test_title => 'Resultados da Requisição de Teste';

  @override
  String get action_json_editor_hint =>
      'Editor de objeto JSON (suporta objetos/arrays aninhados)';

  @override
  String get action_key_field => 'Chave da Ação';

  @override
  String get action_key_value_pairs => 'Pares Chave / Valor';

  @override
  String get action_literal => 'Literal';

  @override
  String get action_loading_keys => 'Carregando chaves...';

  @override
  String get action_manage_variable_keys => 'Gerenciar Chaves de Variáveis';

  @override
  String get action_name_addReaction => 'Adicionar Reação';

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
  String get action_name_canvasDrawCircleBlock => 'Desenhar Círculo';

  @override
  String get action_name_canvasDrawLineBlock => 'Desenhar Linha';

  @override
  String get action_name_canvasDrawRectBlock => 'Desenhar Retângulo';

  @override
  String get action_name_canvasDrawTextBlock => 'Desenhar Texto';

  @override
  String get action_name_canvasLoadImageBlock => 'Carregar Imagem';

  @override
  String get action_name_clearAllReactions => 'Limpar Todas as Reações';

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
  String get action_name_debugProfile => 'Perfil de Depuração';

  @override
  String get action_name_deferInteraction => 'Adiar Interação';

  @override
  String get action_name_deleteAutoModRule => 'Eliminar Regra AutoMod';

  @override
  String get action_name_deleteChannelPermission =>
      'Eliminar Permissão do Canal';

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
  String get action_name_editChannelPermissions => 'Editar Permissões do Canal';

  @override
  String get action_name_editComponentV2 => 'Editar Componente V2';

  @override
  String get action_name_editInteractionMessage =>
      'Editar Mensagem de Interação';

  @override
  String get action_name_editMessage => 'Editar Mensagem';

  @override
  String get action_name_editWebhook => 'Editar Webhook';

  @override
  String get action_name_endPoll => 'Terminar Sondagem';

  @override
  String get action_name_forLoop => 'Loop For';

  @override
  String get action_name_getGlobalVariable => 'Obter Variável Global';

  @override
  String get action_name_getGuildOnboarding => 'Obter Introdução do Servidor';

  @override
  String get action_name_getInvite => 'Obter Convite';

  @override
  String get action_name_getMember => 'Obter Membro';

  @override
  String get action_name_getMessage => 'Obter Mensagem';

  @override
  String get action_name_getMusicInfo => 'Obter Info da Música';

  @override
  String get action_name_getScopedVariable => 'Obter Variável de Âmbito';

  @override
  String get action_name_getWebhook => 'Obter Webhook';

  @override
  String get action_name_httpRequest => 'Pedido HTTP';

  @override
  String get action_name_ifBlock => 'Bloco IF / ELSE';

  @override
  String get action_name_jumpToAction => 'Saltar para ação';

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
      'Listar Índice de Variáveis de Âmbito';

  @override
  String get action_name_listWebhooks => 'Listar Webhooks';

  @override
  String get action_name_listenAndExecute => 'Ouvir e Executar';

  @override
  String get action_name_listenForButtonClick => 'Ouvir Clique de Botão';

  @override
  String get action_name_listenForModalSubmit => 'Ouvir Submissão de Modal';

  @override
  String get action_name_listenForSelectMenu => 'Ouvir Menu de Seleção';

  @override
  String get action_name_log => 'Registrar Mensagem';

  @override
  String get action_name_moveToVoiceChannel => 'Mover para Canal de Voz';

  @override
  String get action_name_muteUser => 'Silenciar Utilizador';

  @override
  String get action_name_pauseMusic => 'Pausar Música';

  @override
  String get action_name_pinMessage => 'Fixar Mensagem';

  @override
  String get action_name_playMusic => 'Tocar Música';

  @override
  String get action_name_queryArray => 'Consultar Array';

  @override
  String get action_name_randomChoice => 'Escolha Aleatória';

  @override
  String get action_name_registerGuildCommands =>
      'Registrar Comandos de Servidor';

  @override
  String get action_name_removeArrayElement => 'Remover Elemento do Array';

  @override
  String get action_name_removeChannel => 'Remover Canal';

  @override
  String get action_name_removeGlobalVariable => 'Remover Variável Global';

  @override
  String get action_name_removeReaction => 'Remover Reação';

  @override
  String get action_name_removeRole => 'Remover Cargo';

  @override
  String get action_name_removeScopedVariable => 'Remover Variável de Âmbito';

  @override
  String get action_name_removeThreadMember => 'Remover Membro da Thread';

  @override
  String get action_name_renameScopedVariable => 'Renomear Variável de Âmbito';

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
  String get action_name_resumeMusic => 'Retomar Música';

  @override
  String get action_name_runBdfdScript => 'Executar Script BDFD';

  @override
  String get action_name_runWorkflow => 'Executar Fluxo de Trabalho';

  @override
  String get action_name_runtimeImageBlock => 'Executar Operações de Imagem';

  @override
  String get action_name_runtimeJsonBlock => 'Executar Operações JSON';

  @override
  String get action_name_seekMusic => 'Avançar/Retroceder Posição';

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
  String get action_name_setGlobalVariable => 'Definir Variável Global';

  @override
  String get action_name_setMusicLoop => 'Configurar Repetição';

  @override
  String get action_name_setMusicVolume => 'Ajustar Volume';

  @override
  String get action_name_setNickname => 'Definir Apelido';

  @override
  String get action_name_setScopedVariable => 'Definir Variável de Âmbito';

  @override
  String get action_name_setTemporaryVariable => 'Definir Variável Temporária';

  @override
  String get action_name_skipActions => 'Saltar ações';

  @override
  String get action_name_skipMusic => 'Pular Música';

  @override
  String get action_name_slowmode => 'Modo Lento';

  @override
  String get action_name_stop => 'Parar';

  @override
  String get action_name_stopMusic => 'Parar Música';

  @override
  String get action_name_stopUnless =>
      'Parar a menos que a condição seja cumprida';

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
      'Atualizar Introdução do Servidor';

  @override
  String get action_name_updateSelfUser =>
      'Atualizar Próprio Utilizador (Perfil do Bot)';

  @override
  String get action_name_wait => 'Aguardar';

  @override
  String get action_no_actions_yet => 'Nenhuma ação neste ramo ainda.';

  @override
  String get action_no_args_tap_edit =>
      'Sem argumentos - toque em editar para adicionar';

  @override
  String get action_no_else_if_yet =>
      'Nenhum ramo ELSE IF ainda. Adicione um para testar mais condições antes do ELSE.';

  @override
  String get action_no_headers_tap_edit =>
      'Sem cabeçalhos - toque em editar para adicionar';

  @override
  String get action_no_items_tap_edit =>
      'Sem itens - toque em editar para adicionar';

  @override
  String get action_no_properties_tap_edit =>
      'Sem propriedades - toque em editar para configurar';

  @override
  String get action_no_saved_keys =>
      'Nenhuma chave salva encontrada. As chaves são criadas automaticamente no primeiro acesso.';

  @override
  String get action_on_error => 'Em caso de erro';

  @override
  String get action_options_tooltip => 'Opções de ação';

  @override
  String get action_or_type_workflow => 'Ou digite o nome do workflow';

  @override
  String get action_order_tip =>
      'Dica: use as setas para alterar a ordem das ações.';

  @override
  String action_position(int index, int total) {
    return 'Ação $index/$total';
  }

  @override
  String get action_preview_json => 'Visualizar JSON Destacado';

  @override
  String get action_provide_valid_url => 'Por favor, forneça uma URL válida.';

  @override
  String get action_refresh_keys => 'Atualizar chaves';

  @override
  String get action_remove_confirm =>
      'Esta ação será removida do fluxo de trabalho. Continuar?';

  @override
  String get action_remove_else_if => 'Remover ELSE IF';

  @override
  String get action_remove_menu => 'Remover ação';

  @override
  String get action_remove_title => 'Remover ação';

  @override
  String get action_root_must_json => 'A raiz deve ser um objeto JSON';

  @override
  String get action_select_saved_key => 'Selecione uma chave salva';

  @override
  String get action_select_stored_key =>
      'Selecione uma chave armazenada (o prefixo bc_ é opcional)';

  @override
  String get action_static_badge => '(estático)';

  @override
  String get action_status_disabled => 'Desativado';

  @override
  String get action_status_enabled => 'Ativado';

  @override
  String get action_store_results =>
      'Armazenar resultados em variáveis globais';

  @override
  String actions_active_route(String label) {
    return 'Rota ativa: $label';
  }

  @override
  String get actions_add_label => 'Adicionar Ação';

  @override
  String get actions_add_new_title => 'Adicionar Nova Ação';

  @override
  String actions_build_button(int count) {
    return 'Construir Ações ($count)';
  }

  @override
  String get actions_empty_subtitle =>
      'Adicione uma ação e depois abra-a para configurar os detalhes.';

  @override
  String get actions_empty_title => 'Nenhuma ação';

  @override
  String get actions_builder_title => 'Construtor de Ações';

  @override
  String get actions_description =>
      'Construa ações de tempo de execução para este comando';

  @override
  String get actions_global_variables => 'Variáveis Globais';

  @override
  String actions_key_label(String key) {
    return 'Chave: $key';
  }

  @override
  String actions_missing_field_content(String action, String field) {
    return '\"$action\": \"$field\" é obrigatório.';
  }

  @override
  String get actions_missing_field_title => 'Campo Obrigatório Ausente';

  @override
  String get actions_no_matches => 'Nenhuma ação corresponde à sua busca.';

  @override
  String actions_save_count(int count) {
    return 'Salvar $count ações';
  }

  @override
  String get actions_save_tooltip => 'Salvar Ações';

  @override
  String get actions_save_workflow_title => 'Salvar como Fluxo';

  @override
  String get actions_search_hint => 'Buscar ações...';

  @override
  String get actions_search_sequence_hint => 'Pesquisar sequência...';

  @override
  String actions_sequence_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ações',
      one: '1 ação',
      zero: 'Nenhuma ação',
    );
    return '$_temp0';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Passo $index de $total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'Script BDFD | $lines linha(s) | $diagnostics diagnóstico(s)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count ação(ões) configurada(s)';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Script Dart | $lines linha(s) | $diagnostics diagnóstico(s)';
  }

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count ação(ões) na rota ativa | $routes rota(s)';
  }

  @override
  String get actions_title => 'Ações';

  @override
  String get actions_workflow_name_label => 'Nome do fluxo';

  @override
  String get actions_workflows => 'Fluxos de trabalho';

  @override
  String get ads_consent_accept => 'Eu aceito';

  @override
  String get ads_consent_message =>
      'Para cumprir o RGPD, precisamos do seu consentimento antes de mostrar anúncios. Pode continuar a usar a app mesmo que recuse.';

  @override
  String get ads_consent_refuse => 'Eu recuso';

  @override
  String get ads_consent_refused_info =>
      'Consentimento de anúncios recusado. O bot iniciará normalmente.';

  @override
  String get ads_consent_title => 'Consentimento de anúncios';

  @override
  String get app_bot_token => 'Token de Bot';

  @override
  String get app_create_button => 'Criar Aplicação';

  @override
  String get app_create_hero_desc =>
      'Uma configuração guiada para abrir as páginas corretas, copiar o seu token e importar o bot com segurança.';

  @override
  String get app_create_hero_title => 'Ligue o seu bot do Discord';

  @override
  String get app_create_new => 'Criar nova Aplicação';

  @override
  String get app_create_page_title => 'Criar Aplicação';

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
  String get app_no_apps => 'Nenhuma aplicação encontrada';

  @override
  String get app_note =>
      'Nota: Precisa de criar uma nova Aplicação no Portal de Programadores do Discord e obter o token do seu bot.';

  @override
  String get app_open_discord_portal =>
      'Abrir Portal de Programadores do Discord';

  @override
  String get app_open_discord_portal_desc =>
      'Crie a sua aplicação e ative a secção de bot.';

  @override
  String get app_open_link_error =>
      'Não foi possível abrir esta página externa.';

  @override
  String get app_open_token_tutorial => 'Ler o tutorial do token';

  @override
  String get app_open_token_tutorial_desc =>
      'Um guia passo a passo para gerar e copiar o token do seu bot.';

  @override
  String get app_resources_desc =>
      'Estas ações abrem as páginas oficiais de que precisa antes de guardar o seu bot aqui.';

  @override
  String get app_resources_title => 'Configuração guiada';

  @override
  String get app_save => 'Guardar Alterações';

  @override
  String get app_save_bot => 'Adicionar bot';

  @override
  String get app_show_token => 'Mostrar token';

  @override
  String get app_sync_manager_connect => 'Ligar Discord';

  @override
  String get app_sync_manager_desc =>
      'Este bot já está armazenado no Bot Creator Manager. Ligar com o Discord para sincronizar todos os seus bots automaticamente?';

  @override
  String get app_sync_manager_manual => 'Manter local';

  @override
  String get app_sync_manager_title => 'Bot já gerido';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_invalid_content =>
      'O token parece ter sido redefinido. Por favor, forneça o novo token do Portal de Programadores do Discord.';

  @override
  String get app_token_invalid_title => 'Redefinição de token detectada';

  @override
  String get app_token_field_helper =>
      'Cole o token exatamente como fornecido pelo Discord.';

  @override
  String get app_token_section_desc =>
      'Assim que o token for copiado, cole-o abaixo para adicionar o seu bot à app.';

  @override
  String get app_token_section_title => 'Cole o token do seu bot';

  @override
  String get app_token_security_hint =>
      'Mantenha este token privado. Qualquer pessoa com ele pode controlar o seu bot.';

  @override
  String get appearance_preset_graphite => 'Grafite';

  @override
  String get appearance_preset_graphite_desc =>
      'Superfícies cinzentas neutras — o visual padrão original.';

  @override
  String get appearance_preset_violet_bc => 'Violeta Bot Creator';

  @override
  String get appearance_preset_violet_bc_desc =>
      'A assinatura Bot Creator, com superfícies tingidas.';

  @override
  String get appearance_preset_discord => 'Discord';

  @override
  String get appearance_preset_discord_desc =>
      'O blurple do Discord, para um visual familiar.';

  @override
  String get appearance_preset_ocean => 'Oceano';

  @override
  String get appearance_preset_ocean_desc =>
      'Tons ciano, como águas profundas.';

  @override
  String get appearance_preset_forest => 'Floresta';

  @override
  String get appearance_preset_forest_desc =>
      'Verde profundo, calmo e natural.';

  @override
  String get appearance_preset_amber => 'Âmbar';

  @override
  String get appearance_preset_amber_desc =>
      'Laranja quente, para um visual vivo.';

  @override
  String get appearance_preset_rose => 'Rosa';

  @override
  String get appearance_preset_rose_desc => 'Rosa magenta, ousado e moderno.';

  @override
  String get appearance_preset_high_contrast => 'Contraste elevado';

  @override
  String get appearance_preset_high_contrast_desc =>
      'Legibilidade máxima da interface.';

  @override
  String get autocomplete_dynamic => 'Autocompletar Dinâmico';

  @override
  String get autocomplete_dynamic_desc =>
      'Resolva as escolhas de um fluxo em vez de valores estáticos.';

  @override
  String get autocomplete_filter_hint =>
      'As sugestões são filtradas pelo que o usuário digita.';

  @override
  String get autocomplete_loading => 'Carregando fluxos…';

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
    return 'Cópia de segurança concluída: $id';
  }

  @override
  String backup_failed(String error) {
    return 'Cópia de segurança falhou: $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Este script BDFD não pôde ser compilado:\n$summary';
  }

  @override
  String get bdfd_compile_error_simple =>
      'Este script BDFD não pôde ser compilado.';

  @override
  String get bdfd_compiled_no_actions =>
      'Este script BDFD foi compilado com sucesso, mas não produziu nenhuma ação.';

  @override
  String get bdfd_editor_auto_indent =>
      '• Recuo automático inteligente ao pressionar Enter';

  @override
  String get bdfd_editor_diagnostics_toggle =>
      'Alternar painel de diagnósticos';

  @override
  String get bdfd_editor_docs => 'Documentacao';

  @override
  String get bdfd_editor_empty =>
      'Script vazio — comece a escrever para ver os diagnósticos.';

  @override
  String get bdfd_editor_includes => 'Inclui:';

  @override
  String get bdfd_editor_indent_guides => '• Guias de recuo ao vivo';

  @override
  String get bdfd_editor_quick_keys =>
      '• Teclas rápidas móveis para símbolos BDFD';

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
      'Não foi possível abrir o link de convite';

  @override
  String get bot_home_ios_notice_content =>
      'No modo local, o iOS pode suspender a app em segundo plano. O bot pode iniciar, mas manter a ligação ao Discord ativa não é garantido como acontece com um Runner.';

  @override
  String get bot_home_ios_notice_title => 'Restrição local do iOS';

  @override
  String get bot_home_log_desktop_stop =>
      'Paragem do bot de desktop solicitada';

  @override
  String get bot_home_log_start => 'Arranque do bot solicitado';

  @override
  String get bot_home_log_stop => 'Paragem do bot solicitada';

  @override
  String get bot_home_notif_required =>
      'A permissão de notificação é necessária para iniciar o serviço do bot.';

  @override
  String get bot_home_section_danger => 'ZONA DE PERIGO';

  @override
  String get bot_home_section_getting_started => 'INTRODUÇÃO';

  @override
  String get bot_home_section_modules => 'MÓDULOS';

  @override
  String get bot_home_section_monitoring => 'MONITORIZAÇÃO';

  @override
  String get bot_home_section_tools => 'FERRAMENTAS';

  @override
  String get bot_home_service_not_started =>
      'O serviço de primeiro plano não iniciou.';

  @override
  String get bot_home_start => 'Iniciar Bot';

  @override
  String bot_home_start_error(String error) {
    return 'Não foi possível iniciar: $error';
  }

  @override
  String get bot_home_starting => 'A iniciar…';

  @override
  String get bot_home_restart => 'Reiniciar';

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
  String get bot_home_version_history => 'Histórico de Versões';

  @override
  String get bot_config_versions_title => 'Histórico de Versões';

  @override
  String get bot_config_versions_empty => 'Nenhuma versão anterior encontrada';

  @override
  String get bot_config_versions_restore => 'Restaurar';

  @override
  String get bot_config_versions_restore_confirm =>
      'Restaurar esta versão? Sua configuração atual será salva primeiro.';

  @override
  String get bot_config_versions_restored =>
      'Configuração restaurada localmente e na nuvem.';

  @override
  String get bot_config_versions_error => 'Falha ao carregar versões';

  @override
  String get bot_config_versions_restore_error => 'Falha ao restaurar versão';

  @override
  String get bot_home_pull_dialog_changes => 'Alterações a aplicar:';

  @override
  String get bot_home_pull_dialog_local => 'Local (Dispositivo)';

  @override
  String get bot_home_pull_dialog_local_only => 'apenas local (mantido)';

  @override
  String get bot_home_pull_dialog_local_preserved =>
      'Comando(s) local(is) ausente(s) da nuvem serão preservado(s).';

  @override
  String get bot_home_pull_dialog_new_commands => 'novo(s) comando(s)';

  @override
  String get bot_home_pull_dialog_remote => 'Remoto (Nuvem)';

  @override
  String get bot_home_pull_dialog_unchanged => 'inalterado(s)';

  @override
  String get bot_home_pull_dialog_up_to_date =>
      'Já está atualizado — nenhuma alteração necessária.';

  @override
  String get bot_home_pull_dialog_updated_commands =>
      'comando(s) atualizado(s)';

  @override
  String get bot_home_push_refused_empty =>
      'Push recusado: configuração local vazia ou corrompida. Verifique seus comandos.';

  @override
  String get bot_home_token_invalid_content =>
      'O token parece ter sido redefinido. Por favor, forneça o novo token do Portal de Programadores do Discord. Deseja iniciar o bot de qualquer forma?';

  @override
  String get bot_home_token_invalid_title =>
      'O token parece ter sido redefinido';

  @override
  String get bot_home_view_logs => 'Ver registos do bot';

  @override
  String get bot_home_view_replay => 'Ver replays do depurador';

  @override
  String get bot_home_view_stats => 'Ver estatísticas do bot';

  @override
  String get bot_logs_copied => 'Logs copiados';

  @override
  String get bot_logs_disable_debug => 'Desativar logs de debug';

  @override
  String get bot_logs_empty => 'Ainda não há logs';

  @override
  String get bot_logs_enable_debug => 'Ativar logs de debug';

  @override
  String get bot_logs_filter_count => 'Número de logs exibidos';

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
  String get bot_logs_server_empty =>
      'Os servidores Bot Creator não retornaram logs para este bot.';

  @override
  String get bot_logs_server_read_failed =>
      'Não foi possível ler os logs dos servidores Bot Creator.';

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
      'Token inválido ou em falta. Introduza um novo token de bot do Discord para restaurar a ligação.';

  @override
  String get bot_settings_activity_state_label =>
      'Estado da atividade (opcional)';

  @override
  String get bot_settings_activity_url_label =>
      'URL da stream (para streaming)';

  @override
  String get bot_settings_add_status => 'Adicionar atividade';

  @override
  String get bot_settings_app_flags => 'Flags da Aplicação';

  @override
  String get bot_settings_avatar_clear_selection => 'Limpar seleção';

  @override
  String get bot_settings_avatar_important_note =>
      'Importante: As alterações de perfil (nome de usuário e avatar) só serão aplicadas no Discord quando você clicar em \'Salvar perfil e status\' na parte inferior.';

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
      'Não foi possível pré-visualizar a imagem';

  @override
  String get bot_settings_avatar_preview_label => 'Pré-visualização do avatar';

  @override
  String get bot_settings_avatar_selected => 'Imagem selecionada:';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Ficheiro selecionado: $path';
  }

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Formato de avatar não suportado: $ext. Formatos suportados: $formats.';
  }

  @override
  String get bot_settings_browse => 'Procurar';

  @override
  String get bot_settings_cancel_token_edit_btn => 'Cancelar edição de token';

  @override
  String get bot_settings_danger_zone => 'Zona de Perigo';

  @override
  String get bot_settings_delete_bot => 'Excluir Bot';

  @override
  String get bot_settings_delete_bot_btn => 'Excluir Permanentemente';

  @override
  String get bot_settings_delete_bot_desc =>
      'Esta ação é irreversível. Todos os dados locais e configurações remotas serão removidos permanentemente.';

  @override
  String bot_settings_delete_desc(String id) {
    return 'Tem certeza de que deseja excluir o bot $id? Todos os dados serão perdidos.';
  }

  @override
  String get bot_settings_delete_title => 'Confirmar Exclusão';

  @override
  String get bot_settings_edit_token_btn => 'Editar token';

  @override
  String get bot_settings_export_import => 'Exportar / Importar';

  @override
  String get bot_settings_export_import_desc =>
      'Exporte ou importe a configuração do seu bot como um ficheiro ZIP.';

  @override
  String get bot_settings_gateway_intents => 'Configuração de Gateway Intents';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Selecione quais os intents que o seu bot precisa. Configure-os no Portal de Programadores do Discord.';

  @override
  String get bot_settings_intents_saved => 'Intents guardados com sucesso';

  @override
  String get bot_settings_intents_auto_enabled =>
      'Os gateway intents privilegiados foram ativados automaticamente no Developer Portal.';

  @override
  String get bot_settings_intents_verified_bot_manual =>
      'Este bot verificado requer a ativacao manual dos intents privilegiados no Discord Developer Portal.';

  @override
  String get bot_settings_intents_auto_enable_failed =>
      'Token guardado, mas os intents privilegiados nao puderam ser ativados automaticamente. Ative-os no Discord Developer Portal.';

  @override
  String get bot_settings_lavalink_add_fallback =>
      'Adicionar servidor de reserva';

  @override
  String get bot_settings_lavalink_choose_server =>
      'Escolher um servidor público...';

  @override
  String get bot_settings_lavalink_enable_subtitle =>
      'O bot testa os servidores públicos por conta própria; nenhuma escolha de servidor é necessária.';

  @override
  String get bot_settings_lavalink_enable_title => 'Música (Lavalink)';

  @override
  String get bot_settings_lavalink_fallback_desc =>
      'Os servidores públicos são testados primeiro. Seus servidores são usados como reserva quando nenhum responde.';

  @override
  String get bot_settings_lavalink_fallback_title =>
      'Meus servidores de reserva';

  @override
  String get bot_settings_lavalink_host => 'Host';

  @override
  String get bot_settings_lavalink_host_hint =>
      'localhost ou IP do servidor Lavalink';

  @override
  String get bot_settings_lavalink_invalid_server =>
      'Informe um host e uma porta entre 1 e 65535.';

  @override
  String get bot_settings_lavalink_no_fallback =>
      'Ainda não há servidor de reserva.';

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
      'Desbloqueie o suporte de áudio Lavalink para o seu bot.';

  @override
  String get bot_settings_lavalink_premium_banner_title =>
      '🔒 Disponível com Bot Creator PREMIUM';

  @override
  String get bot_settings_lavalink_public_servers => 'Servidores públicos';

  @override
  String get bot_settings_lavalink_remove_fallback => 'Remover';

  @override
  String get bot_settings_lavalink_save_btn => 'Guardar';

  @override
  String get bot_settings_lavalink_save_caption =>
      'Salve para o bot tentar primeiro os servidores públicos e depois os seus servidores de reserva.';

  @override
  String get bot_settings_lavalink_section_title => 'Servidor Lavalink';

  @override
  String bot_settings_lavalink_server_number(int index) {
    return 'Servidor de reserva $index';
  }

  @override
  String get bot_settings_lavalink_server_picker_title =>
      'Servidores Lavalink públicos';

  @override
  String bot_settings_lavalink_server_subtitle(String port, String version) {
    return 'Porta $port — $version';
  }

  @override
  String bot_settings_lavalink_servers_available(int count) {
    return '$count servidores disponíveis';
  }

  @override
  String get bot_settings_lavalink_ssl => 'Usar SSL/TLS';

  @override
  String get bot_settings_lavalink_ssl_subtitle => 'Ligação segura wss://';

  @override
  String get bot_settings_lavalink_success => 'Ligação bem-sucedida!';

  @override
  String get bot_settings_lavalink_test_btn => 'Testar ligação';

  @override
  String get bot_settings_lavalink_testing => 'A testar...';

  @override
  String get bot_settings_lavalink_view_offers => 'Ver ofertas';

  @override
  String get bot_settings_no_activities => 'Nenhuma atividade configurada';

  @override
  String get bot_settings_presence_dnd => 'Não Perturbar';

  @override
  String get bot_settings_presence_idle => 'Ausente';

  @override
  String get bot_settings_presence_invisible => 'Invisível';

  @override
  String get bot_settings_presence_online => 'Online';

  @override
  String get bot_settings_presence_status_label => 'Presença';

  @override
  String get bot_settings_presence_status_title => 'Estado de Presença do Bot';

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
      'Isto apenas atualiza a configuração de gateway intents.';

  @override
  String get bot_settings_save_profile_caption =>
      'Isto aplica o nome de utilizador/avatar instantaneamente e guarda a rotação de estados.';

  @override
  String get bot_settings_save_profile_status_btn => 'Guardar perfil e estados';

  @override
  String get bot_settings_save_success => 'Definições guardadas com sucesso';

  @override
  String get bot_settings_save_token_btn => 'Guardar token e intents';

  @override
  String get bot_settings_save_token_caption =>
      'Alterações de token estão protegidas. Clique primeiro em \"Editar token\", depois guarde.';

  @override
  String get bot_settings_save_token_first =>
      'Por favor, guarde primeiro o token antes de aplicar alterações de perfil/estado.';

  @override
  String get bot_settings_save_token_only_btn => 'Guardar token';

  @override
  String bot_settings_status_item_title(int index) {
    return 'Atividade $index';
  }

  @override
  String get bot_settings_status_max_interval => 'Intervalo máx (s)';

  @override
  String get bot_settings_status_min_interval => 'Intervalo mín (s)';

  @override
  String get bot_settings_status_rotation_desc =>
      'Adicione uma ou mais atividades. Cada atividade precisa de um tipo, nome e intervalo mín/máx (segundos).';

  @override
  String get bot_settings_status_rotation_title => 'Rotação de Atividades';

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
  String get bot_settings_tab_advanced => 'Avançado & Manutenção';

  @override
  String get bot_settings_tab_general => 'Geral';

  @override
  String get bot_settings_tab_intents => 'Intents & Privilégios';

  @override
  String get bot_settings_tab_lavalink => 'Lavalink';

  @override
  String get bot_settings_tab_database => 'Banco de dados';

  @override
  String get bot_settings_database_section_title => 'Banco de dados externo';

  @override
  String get bot_settings_database_type_label => 'Tipo de banco de dados';

  @override
  String get bot_settings_database_type_none => 'Nenhum (Desativado)';

  @override
  String get bot_settings_database_type_postgres =>
      'PostgreSQL (palavra-chave: pgsql)';

  @override
  String get bot_settings_database_type_mysql => 'MySQL (palavra-chave: sql)';

  @override
  String get bot_settings_database_type_mongo =>
      'MongoDB (palavra-chave: mongo)';

  @override
  String get bot_settings_database_info_postgres =>
      'Disponível em seus scripts através da palavra-chave global \"pgsql\" (ex: await pgsql.query(\"SELECT * FROM users\")).';

  @override
  String get bot_settings_database_info_mysql =>
      'Disponível em seus scripts através da palavra-chave global \"sql\" (ex: await sql.query(\"SELECT * FROM users\")).';

  @override
  String get bot_settings_database_info_mongo =>
      'Disponível em seus scripts através da palavra-chave global \"mongo\" (ex: await mongo.collection(\"users\").find()).';

  @override
  String get bot_settings_database_uri_label => 'String de conexão (URI)';

  @override
  String get bot_settings_database_show_discrete_fields =>
      'Configurar campos individuais (Host, Porta, etc.)';

  @override
  String get bot_settings_database_hide_discrete_fields =>
      'Ocultar campos individuais';

  @override
  String get bot_settings_database_host => 'Host';

  @override
  String get bot_settings_database_host_hint => 'localhost ou endereço IP';

  @override
  String get bot_settings_database_port => 'Porta';

  @override
  String get bot_settings_database_name => 'Nome do banco de dados';

  @override
  String get bot_settings_database_name_hint => 'ex: bot_db';

  @override
  String get bot_settings_database_user => 'Nome de usuário';

  @override
  String get bot_settings_database_user_hint => 'ex: root ou postgres';

  @override
  String get bot_settings_database_password => 'Senha';

  @override
  String get bot_settings_database_ssl => 'Habilitar SSL / TLS';

  @override
  String get bot_settings_database_save_btn =>
      'Salvar configuração do banco de dados';

  @override
  String get bot_settings_tab_presence => 'Presença & Status';

  @override
  String get bot_settings_title => 'Personalizar Bot / Perfil';

  @override
  String get bot_settings_token_hidden_desc =>
      'A entrada de token está oculta por padrão por segurança.';

  @override
  String get bot_settings_token_hint => 'Introduza o token do seu bot aqui';

  @override
  String get bot_settings_token_mismatch_confirm =>
      'Substituir token de qualquer forma';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Este token pertence ao bot $newId, mas os dados atuais são para o bot $oldId. Comandos e definições podem não corresponder. Continuar de qualquer forma?';
  }

  @override
  String get bot_settings_token_mismatch_title => 'Diferente bot detetado';

  @override
  String get bot_settings_token_required => 'O token do bot é obrigatório.';

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
      'Substituição de nome de utilizador';

  @override
  String get bot_settings_workflow_docs => 'Documentacao';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Guias, referencia BDFD e documentacao discord.js';

  @override
  String get bot_stats_collecting => 'A recolher…';

  @override
  String get bot_stats_cpu => 'CPU do processo do Bot';

  @override
  String get bot_stats_notes =>
      'Notas: CPU disponível em Android/Linux. Armazenamento = ficheiros de dados do bot na app.';

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
  String get bot_stats_title => 'Estatísticas do Bot';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Escreva \$ e comece a escrever o nome de uma função para obter sugestões rápidas.';

  @override
  String get cmd_bdfd_autocomplete_title => 'Autocompletar prefixo BDFD';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Nenhum problema detetado no script atual.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Erro';

  @override
  String get cmd_bdfd_diagnostics_title => 'Diagnósticos BDFD';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Aviso';

  @override
  String get cmd_bdfd_script_empty_error =>
      'O corpo do script BDFD não pode estar vazio.';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nOlá do Bot Creator';

  @override
  String get cmd_bdfd_script_label => 'Corpo do script BDFD';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Este script BDFD ainda contém diagnósticos:';

  @override
  String get cmd_create_tooltip => 'Criar comando';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Nenhum problema detetado no script Dart atual.';

  @override
  String get cmd_dart_diagnostics_error => 'Erro';

  @override
  String get cmd_dart_diagnostics_title => 'Diagnósticos Dart';

  @override
  String get cmd_dart_diagnostics_warning => 'Aviso';

  @override
  String get cmd_dart_script_hint => 'return \"Olá do Dart Direto\";';

  @override
  String get cmd_dart_script_label => 'Corpo do script Dart';

  @override
  String cmd_batch_delete_confirm(int count) {
    return 'Excluir $count comandos?';
  }

  @override
  String cmd_batch_delete_success(Object count) {
    return '$count comandos excluídos';
  }

  @override
  String cmd_delete_confirm(Object name) {
    return 'Excluir comando \"$name\"?';
  }

  @override
  String cmd_delete_success(Object name) {
    return 'Comando \"$name\" excluído';
  }

  @override
  String get cmd_delete_tooltip => 'Apagar comando';

  @override
  String get cmd_deploy_close_button => 'Fechar';

  @override
  String get cmd_deploy_cloud_sync_subtitle =>
      'Sincronização segura com o seu espaço online';

  @override
  String get cmd_deploy_cloud_sync_title => 'Backup na Nuvem';

  @override
  String cmd_deploy_config_subtitle(String name) {
    return 'Configuração de /$name';
  }

  @override
  String get cmd_deploy_discord_sync_subtitle =>
      'Publicando comando na API do Discord';

  @override
  String get cmd_deploy_discord_sync_title => 'Sincronização com Discord';

  @override
  String get cmd_deploy_failed_title => 'Falha na implantação';

  @override
  String get cmd_deploy_hot_reload_subtitle =>
      'Atualização instantânea do runner do seu bot';

  @override
  String get cmd_deploy_hot_reload_title => 'Recarregamento Rápido';

  @override
  String get cmd_deploy_in_progress_title => 'Implantação em andamento...';

  @override
  String get cmd_deploy_local_save_subtitle =>
      'Salvando comando no dispositivo';

  @override
  String get cmd_deploy_local_save_title => 'Salvamento Local';

  @override
  String get cmd_deploy_reload_bot_subtitle =>
      'Aplicando configuração de hot-reload';

  @override
  String get cmd_deploy_reload_bot_title => 'Recarregando Bot';

  @override
  String get cmd_deploy_retry_button => 'Tentar Novamente';

  @override
  String get cmd_deploy_success_title => 'Implantação bem-sucedida!';

  @override
  String cmd_deploy_success_toast(String name) {
    return 'Comando \"$name\" implantado e ativo!';
  }

  @override
  String get cmd_editor_mode_advanced => 'Modo avançado';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Editor completo com resposta personalizada, opções e construtor de ações.';

  @override
  String get cmd_editor_mode_locked =>
      'O modo avançado está bloqueado para este comando.';

  @override
  String get cmd_editor_mode_simple => 'Modo simplificado';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Construa um comando rapidamente com opções guiadas e ações pré-configuradas.';

  @override
  String get cmd_editor_mode_switch_adv => 'Mudar para modo avançado';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Mudar';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Esta mudança é permanente para este comando. Não poderá voltar ao modo simplificado.';

  @override
  String get cmd_editor_mode_switch_adv_title => 'Mudar para modo avançado?';

  @override
  String get cmd_editor_mode_title => 'Modo de edição';

  @override
  String get cmd_error_fill_fields => 'Por favor, preencha todos os campos';

  @override
  String get cmd_execution_mode_bdfd => 'Modo Script BDFD';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Escreva o corpo do comando como um script estilo BDFD enquanto mantém a definição do comando visual.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'O script é compilado para ações internas. Diagnósticos são mostrados durante a edição; scripts inválidos falham quando o comando é executado.';

  @override
  String get cmd_execution_mode_dart => 'Modo Dart Direto';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Escreva o corpo do comando diretamente em Dart com diagnósticos em tempo de execução.';

  @override
  String get cmd_execution_mode_dart_note =>
      'O código Dart é compilado em execução através do motor sandbox. Mantenha os scripts determinísticos e retorne um valor quando necessário.';

  @override
  String get cmd_execution_mode_javascript => 'JavaScript';

  @override
  String get cmd_execution_mode_javascript_desc =>
      'Escreva código JS personalizado para este comando.';

  @override
  String get cmd_execution_mode_javascript_note =>
      'Todas as funções BDFD estão disponíveis como funções JS assíncronas. Use ctx.authorId, ctx.channelId, vars[\'key\'] para acessar contexto e variáveis.';

  @override
  String get cmd_execution_mode_desc =>
      'Os metadados do comando ficam no construtor visual. Escolha como o corpo do comando deve ser executado.';

  @override
  String get cmd_execution_mode_title => 'Modo de execução';

  @override
  String get cmd_execution_mode_workflow => 'Modo Workflow';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Use a resposta visual existente e o construtor de ações.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'O modo Workflow é o caminho de produção atual e continua totalmente suportado.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrar';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Gere um esqueleto de migração Dart a partir do seu script BDFD atual.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Este comando não pôde ser totalmente carregado (offline ou token inválido). Ligue um token válido para editar.';

  @override
  String get cmd_show_variables => 'Abrir documentação de variáveis';

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
      'Criar uma sondagem com uma /pergunta dinâmica e escolhas de resposta fixas.';

  @override
  String get cmd_simple_action_delete => 'Apagar mensagens';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'Usada quando /contagem não é fornecida';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Contagem padrão de eliminação';

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
      'Duração do silenciamento';

  @override
  String get cmd_simple_action_pin => 'Fixar mensagem';

  @override
  String get cmd_simple_action_pin_desc =>
      'Fixar uma mensagem no canal atual usando /id_mensagem.';

  @override
  String get cmd_simple_action_reason_hint =>
      'Razão opcional partilhada pelas ações de moderação';

  @override
  String get cmd_simple_action_reason_label => 'Razão do log de auditoria';

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
      'Mensagem enviada pela ação Enviar Mensagem';

  @override
  String get cmd_simple_action_send_message_label => 'Mensagem da ação';

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
      'Selecione o que este comando deve fazer. As opções são geradas automaticamente.';

  @override
  String get cmd_simple_actions_title => 'Ações simplificadas';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Banir utilizador e Desbanir utilizador não podem ser ativados juntos no modo simplificado.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Silenciar utilizador e Dessilenciar utilizador não podem ser ativados juntos no modo simplificado.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Fixar mensagem e Desafixar mensagem não podem ser ativados juntos no modo simplificado.';

  @override
  String get cmd_simple_execution_desc =>
      'Ajuste fino das ações geradas sem sair do modo simplificado.';

  @override
  String get cmd_simple_execution_title => 'Definições de execução';

  @override
  String get cmd_simple_generated_none =>
      'Nenhuma opção gerada ainda. Selecione pelo menos uma ação.';

  @override
  String get cmd_simple_generated_options => 'Opções de comando geradas';

  @override
  String get cmd_simple_group_messages_desc =>
      'Ações de mensagens e canais que funcionam no contexto atual.';

  @override
  String get cmd_simple_group_messages_title => 'Mensagens';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Ações de membros e moderação com opções guiadas.';

  @override
  String get cmd_simple_group_moderation_title => 'Moderação';

  @override
  String get cmd_simple_group_utility_desc =>
      'Extras úteis como convites e sondagens.';

  @override
  String get cmd_simple_group_utility_title => 'Utilidade';

  @override
  String get cmd_simple_invite_max_age_hint => '0 para não expirar, até 604800';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'A expiração do convite deve ser um número entre 0 e 604800 segundos.';

  @override
  String get cmd_simple_invite_max_age_label =>
      'Expiração do convite (segundos)';

  @override
  String get cmd_simple_invite_max_uses_hint => '0 para usos ilimitados';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'O máximo de usos do convite deve ser um número entre 0 e 1000000.';

  @override
  String get cmd_simple_invite_max_uses_label => 'Máximo de usos';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Padrões usados pela ação Criar Convite gerada.';

  @override
  String get cmd_simple_invite_settings_title => 'Definições de convite';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Os membros são removidos se saírem antes de obter um cargo.';

  @override
  String get cmd_simple_invite_temporary_label => 'Associação temporária';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Criar sempre um novo convite em vez de reutilizar um existente.';

  @override
  String get cmd_simple_invite_unique_label => 'Forçar convite único';

  @override
  String get cmd_simple_option_channel => '/canal (Canal)';

  @override
  String get cmd_simple_option_channel_desc =>
      'Substituição opcional de canal para criação de convite';

  @override
  String get cmd_simple_option_count => '/contagem (Inteiro)';

  @override
  String get cmd_simple_option_count_desc => 'Número de mensagens a apagar';

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
      'Uma resposta por linha, ou use vírgulas. Mínimo 2, máximo 10.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'As respostas da sondagem devem conter entre 2 e 10 escolhas não vazias.';

  @override
  String get cmd_simple_poll_answers_label => 'Respostas da sondagem';

  @override
  String get cmd_simple_poll_duration_hint => 'De 1 a 168 horas';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'A duração da sondagem deve ser um número entre 1 e 168 horas.';

  @override
  String get cmd_simple_poll_duration_label => 'Duração da sondagem (horas)';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Os utilizadores podem selecionar mais do que uma escolha.';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Permitir múltiplas respostas';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Padrões usados pela ação Criar Sondagem gerada.';

  @override
  String get cmd_simple_poll_settings_title => 'Definições de sondagem';

  @override
  String get cmd_simple_response_desc =>
      'Mensagem enviada de volta ao utilizador após as ações serem executadas.';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Embeds opcionais enviados com a resposta final.';

  @override
  String get cmd_simple_response_embeds_title => 'Embeds da resposta';

  @override
  String get cmd_simple_response_hint => 'Concluído ✅';

  @override
  String get cmd_simple_response_title => 'Resposta final';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'Efémero';

  @override
  String get cmd_simple_response_visibility_label => 'Visibilidade da resposta';

  @override
  String get cmd_simple_response_visibility_public => 'Público';

  @override
  String get cmd_simple_send_message_required =>
      'Por favor, preencha a mensagem da ação antes de guardar.';

  @override
  String get cmd_variables_title => 'Variáveis de Comando';

  @override
  String get code_editor_settings_title => 'Editor de código';

  @override
  String get code_editor_settings_subtitle =>
      'Tema, fonte e comportamento de edição dos editores BDFD e JavaScript';

  @override
  String get code_editor_settings_reset_tooltip => 'Restaurar padrões';

  @override
  String get code_editor_settings_reset_title => 'Redefinir configuração';

  @override
  String get code_editor_settings_reset_confirm =>
      'Restaurar todas as configurações do editor para os valores padrão?';

  @override
  String get code_editor_settings_reset_action => 'Redefinir';

  @override
  String get code_editor_settings_reset_done =>
      'Configurações do editor restauradas para o padrão';

  @override
  String get code_editor_settings_preview_title => 'Pré-visualização ao vivo';

  @override
  String get code_editor_settings_section_theme_title =>
      'Tema de realce de sintaxe';

  @override
  String get code_editor_settings_section_theme_subtitle =>
      'Escolha o estilo visual aplicado ao BDFD e ao JavaScript';

  @override
  String get code_editor_settings_theme_mode_dark => 'Modo escuro';

  @override
  String get code_editor_settings_theme_mode_light => 'Modo claro';

  @override
  String get code_editor_settings_section_font_title => 'Fonte e tipografia';

  @override
  String get code_editor_settings_section_font_subtitle =>
      'Ajuste a família da fonte e o tamanho do texto';

  @override
  String get code_editor_settings_font_family => 'Família da fonte';

  @override
  String get code_editor_settings_font_system => 'Monoespaçada do sistema';

  @override
  String get code_editor_settings_font_jetbrains_mono => 'JetBrains Mono';

  @override
  String get code_editor_settings_font_fira_code => 'Fira Code';

  @override
  String get code_editor_settings_font_consolas => 'Consolas';

  @override
  String get code_editor_settings_font_size => 'Tamanho da fonte';

  @override
  String get code_editor_settings_line_height => 'Altura da linha (entrelinha)';

  @override
  String get code_editor_settings_section_display_title =>
      'Exibição e guias visuais';

  @override
  String get code_editor_settings_section_display_subtitle =>
      'Números de linha, guias de indentação e quebra de linha';

  @override
  String get code_editor_settings_line_numbers => 'Números de linha';

  @override
  String get code_editor_settings_line_numbers_desc =>
      'Mostra a numeração na margem esquerda';

  @override
  String get code_editor_settings_indent_guides => 'Guias de indentação';

  @override
  String get code_editor_settings_indent_guides_desc =>
      'Linhas verticais para visualizar blocos de código';

  @override
  String get code_editor_settings_word_wrap => 'Quebra automática de linha';

  @override
  String get code_editor_settings_word_wrap_desc =>
      'Quebra linhas longas em vez de rolar horizontalmente';

  @override
  String get code_editor_settings_quick_chars =>
      'Barra de caracteres rápidos (celular)';

  @override
  String get code_editor_settings_quick_chars_desc =>
      'Botões rápidos para inserir o prefixo BDFD, argumentos, separadores e colchetes acima do teclado';

  @override
  String get code_editor_settings_section_editing_title =>
      'Comportamento de edição';

  @override
  String get code_editor_settings_section_editing_subtitle =>
      'Fechamento automático e espaçamento';

  @override
  String get code_editor_settings_auto_close =>
      'Fechamento automático de símbolos';

  @override
  String get code_editor_settings_auto_close_desc =>
      'Fecha automaticamente colchetes, chaves, parênteses e aspas';

  @override
  String get code_editor_settings_tab_size => 'Tamanho da tabulação (espaços)';

  @override
  String get code_editor_settings_tab_size_desc =>
      'Número de espaços inseridos ao indentar';

  @override
  String get command_alias_label => 'Alias';

  @override
  String get command_alias_hint => '!p';

  @override
  String get command_alias_help =>
      'O comando também responde a estas palavras de ativação.';

  @override
  String get command_alias_duplicate => 'Este alias já está a ser utilizado.';

  @override
  String command_alias_limit(int max) {
    return 'Máximo de $max aliases.';
  }

  @override
  String command_alias_collision(String command) {
    return 'Já utilizado pelo comando $command.';
  }

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
      'Predefinição de retorno de chamada aguardado ativa';

  @override
  String get command_awaited_preset_button =>
      'Usar Predefinição de Retorno de Chamada Aguardado';

  @override
  String get command_awaited_preset_desc =>
      'O nome do comando é gerado para você e salvo como um retorno de chamada legado interno.';

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
      'A descrição do comando deve ter no máximo 100 caracteres';

  @override
  String get command_description_required =>
      'Por favor, insira uma descrição para o comando';

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
  String get command_discord_rules_message_hint =>
      'Comandos de mensagem aparecem no menu de contexto de uma mensagem. O nome pode usar espaços e maiúsculas/minúsculas (1-32 caracteres). O Discord não usa descrição.';

  @override
  String get command_discord_rules_slash_hint =>
      'Comandos slash são registrados no Discord. O nome deve ser em minúsculas (1-32 caracteres). A descrição é obrigatória (1-100 caracteres). Nome, descrição e opções combinados não podem exceder 8000 caracteres.';

  @override
  String get command_discord_rules_user_hint =>
      'Comandos de usuário aparecem no menu de contexto de um usuário. O nome pode usar espaços e maiúsculas/minúsculas (1-32 caracteres). O Discord não usa descrição.';

  @override
  String get command_info_desc => 'Metadados básicos e disponibilidade';

  @override
  String get command_info_title => 'Informações do Comando';

  @override
  String get command_integration_guild => 'Instalação em Servidor';

  @override
  String get command_integration_label => 'Onde este comando pode ser usado';

  @override
  String get command_integration_user => 'Instalação em Usuário';

  @override
  String get command_legacy_mode_subtitle =>
      'Executado no chat com o prefixo do bot (exemplo: !config #canal).';

  @override
  String get command_legacy_mode_title => 'Ativar modo prefixo neste comando';

  @override
  String get command_legacy_prefix_desc =>
      'Disparado por messageCreate usando <prefixo><comando>.';

  @override
  String get command_legacy_prefix_title => 'Modo de Comando com Prefixo';

  @override
  String get command_legacy_preset_desc =>
      'Gere um gatilho de callback aguardado interno para um comando com prefixo apenas local.';

  @override
  String get command_legacy_preset_title => 'Predefinição de prefixo';

  @override
  String get command_legacy_response_label => 'Modo de resposta com prefixo';

  @override
  String get command_modal_disabled_legacy =>
      'Modais estão desativados no modo prefixo.';

  @override
  String get command_name_generated =>
      'Gerado pela predefinição de retorno de chamada aguardado.';

  @override
  String get command_name_label => 'Nome';

  @override
  String get command_not_found => 'Comando não encontrado';

  @override
  String get command_options_legacy_params =>
      'Parâmetros posicionais com prefixo (ordenados: obrigatórios, depois opcionais)';

  @override
  String get command_options_slash_params => 'Parâmetros do comando de barra';

  @override
  String get command_options_title => 'Opções do Comando';

  @override
  String get command_payload_hint => 'Payload do comando';

  @override
  String get command_prefix_rules_hint =>
      'Comandos com prefixo são executados por mensagens no chat (ex.: !ping) e não são registrados no Discord. As regras slash do Discord não se aplicam. A descrição é opcional.';

  @override
  String get command_permissions_admin_warning =>
      'Administrador selecionado: isso ignora outras verificações de permissão.';

  @override
  String get command_permissions_bitfield => 'Bitfield de permissão calculado';

  @override
  String get command_permissions_bitfield_helper =>
      'Calculado automaticamente a partir das permissões selecionadas.';

  @override
  String command_permissions_count(int count) {
    return '$count permissão(ões) selecionada(s)';
  }

  @override
  String get command_permissions_label =>
      'Permissões padrão de membros (opcional)';

  @override
  String get command_permissions_none =>
      'Nenhuma seleção (todos podem usar o comando)';

  @override
  String get command_permissions_tip =>
      'Dica: deixe todos desmarcados para tornar o comando disponível para todos por padrão.';

  @override
  String get command_permissions_title => 'Selecionar permissões';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Aviso: bits de permissão desconhecidos detectados nos dados salvos e preservados: $bits';
  }

  @override
  String get command_prefix_helper =>
      'Suporta modelos e variáveis de escopo (bc_ opcional). Exemplo: ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint =>
      'Exemplo: ? ou ((guild.prefix | !))';

  @override
  String get command_prefix_override_label =>
      'Substituição de prefixo (opcional)';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_scope_label => 'Escopo do comando (Contextos)';

  @override
  String get command_subcommand_workflow_desc =>
      'Escolha qual subcomando você está configurando.';

  @override
  String get command_subcommand_workflow_title => 'Workflow de Subcomando';

  @override
  String command_sync_failed_local(String error) {
    return 'Salvo localmente. Falha na sincronização com o Discord: $error';
  }

  @override
  String get command_cloud_sync_failed_saved =>
      'Salvo no Discord e localmente. Falha no backup na nuvem.';

  @override
  String get command_cloud_sync_retry => 'Tentar sincronizar novamente';

  @override
  String get cmd_block_editor_empty_title => 'Nenhuma ação ainda';

  @override
  String get cmd_block_editor_empty_hint =>
      'Adicione um bloco de ação para definir o que seu comando faz ao ser executado.';

  @override
  String get cmd_block_editor_add_action => 'Adicionar ação';

  @override
  String cmd_block_editor_action_label(int index) {
    return 'Ação $index';
  }

  @override
  String get command_target_subcommand => 'Subcomando alvo';

  @override
  String get command_type_label => 'Tipo de Comando';

  @override
  String get command_type_legacy => 'Comando com Prefixo';

  @override
  String get command_type_locked =>
      'O tipo de comando não pode ser alterado após a criação.';

  @override
  String get command_type_message => 'Comando de Mensagem';

  @override
  String get command_type_slash => 'Comando de Barra';

  @override
  String get command_type_user => 'Comando de Usuário';

  @override
  String get command_unsaved_confirm =>
      'Você tem alterações não salvas. Descartá-las?';

  @override
  String get command_unsaved_keep => 'Continuar editando';

  @override
  String get command_unsaved_title => 'Alterações não salvas';

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
      'Os comandos dentro desta pasta não serão apagados, apenas removidos da pasta.';

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
  String get common_add_option => 'Adicionar Opção';

  @override
  String get common_add_section => 'Adicionar Seção';

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
  String get common_minimize => 'Minimizar';

  @override
  String get common_maximize => 'Maximizar';

  @override
  String get common_restore => 'Restaurar';

  @override
  String get common_custom_id => 'ID Personalizado';

  @override
  String get common_custom_id_required => 'ID Personalizado *';

  @override
  String get common_default => 'Padrão';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_description => 'Descrição';

  @override
  String get common_disabled => 'Desativado';

  @override
  String get common_discard => 'Descartar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_enabled => 'Ativado';

  @override
  String get common_import => 'Importar';

  @override
  String get common_key => 'Chave';

  @override
  String get common_label => 'Rótulo';

  @override
  String get common_manage_workflows => 'Gerenciar Fluxos';

  @override
  String get common_move_down => 'Mover para baixo';

  @override
  String get common_move_up => 'Mover para cima';

  @override
  String get common_name => 'Nome';

  @override
  String get common_next => 'Próximo';

  @override
  String get common_none => 'Nenhum';

  @override
  String get common_ok => 'OK';

  @override
  String get common_operator => 'Operador';

  @override
  String get common_pick => 'Escolher';

  @override
  String get common_placeholder => 'Espaço reservado';

  @override
  String get common_refresh => 'Atualizar';

  @override
  String get common_refresh_workflows => 'Atualizar fluxos';

  @override
  String get common_remove => 'Remover';

  @override
  String get common_required => 'Obrigatório';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_search => 'Buscar';

  @override
  String get common_static_options => 'Opções Estáticas';

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
  String get component_action_row => 'Linha de Ação';

  @override
  String get component_add_action_row => 'Adicionar Linha de Ação';

  @override
  String get component_add_button => 'Adicionar Botão';

  @override
  String get component_add_button_or_select =>
      'Adicionar Botão / Menu de Seleção';

  @override
  String get component_add_checkbox_option => 'Adicionar Opção de Checkbox';

  @override
  String get component_add_child => 'Adicionar Componente Filho';

  @override
  String get component_add_media_item => 'Adicionar Item de Mídia';

  @override
  String get component_add_radio_option => 'Adicionar Opção de Rádio';

  @override
  String get component_add_root => 'Adicionar Componente Raiz';

  @override
  String get component_add_text_display => 'Adicionar Exibição de Texto';

  @override
  String get component_add_tooltip => 'Adicionar Componente';

  @override
  String get component_block_label_style => 'Estilo';

  @override
  String get component_block_workflow => 'Fluxo de Trabalho';

  @override
  String get component_button_default_label => 'Botão';

  @override
  String get component_checkbox_options => 'Opções de Checkbox';

  @override
  String get component_checked_by_default => 'Marcado por padrão';

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
  String get component_default_option_label => 'Opção';

  @override
  String get component_disabled_hint =>
      'Digite true/false ou uma variável como ((user.bc_isVip))';

  @override
  String get component_empty_option => 'Vazio';

  @override
  String get component_file_url => 'URL do Arquivo';

  @override
  String get component_label => 'Rótulo';

  @override
  String get component_label_title => 'Título do Rótulo';

  @override
  String get component_markdown_content => 'Conteúdo Markdown';

  @override
  String get component_max_selections => 'Seleções máximas';

  @override
  String get component_media_url => 'URL de Imagem / Vídeo';

  @override
  String get component_media_urls => 'URLs de Mídia';

  @override
  String get component_min_selections => 'Seleções mínimas';

  @override
  String get component_new_checkbox => 'Novo Checkbox';

  @override
  String get component_new_option => 'Nova Opção';

  @override
  String get component_new_radio => 'Novo Rádio';

  @override
  String get component_not_implemented => 'Editor ainda não implementado';

  @override
  String get component_on_click_workflow => 'Ao clicar, o workflow';

  @override
  String get component_on_select_workflow => 'Ao selecionar, o workflow';

  @override
  String get component_options => 'Opções';

  @override
  String get component_pick_accent_color => 'Escolher Cor de Destaque';

  @override
  String get component_placeholder => 'Espaço reservado';

  @override
  String get component_radio_options => 'Opções de Rádio';

  @override
  String get component_remove_confirm =>
      'Este componente será removido do layout. Continuar?';

  @override
  String get component_remove_row_title => 'Remover linha de ação';

  @override
  String get component_remove_title => 'Remover componente';

  @override
  String get component_section_accessory => 'Nó Acessório (Opcional)';

  @override
  String get component_section_text_displays => 'Exibições de Texto';

  @override
  String get component_selection_range => 'Intervalo de seleção';

  @override
  String get component_spacing_large => 'Espaçamento Grande';

  @override
  String get component_spacing_small => 'Espaçamento Pequeno';

  @override
  String get component_style => 'Estilo';

  @override
  String get component_thumbnail_url => 'URL da Miniatura';

  @override
  String get component_unknown_component => 'Componente desconhecido';

  @override
  String get component_url => 'URL';

  @override
  String get component_validation_required => 'Obrigatório';

  @override
  String get component_value_hint => 'Dica de valor do componente';

  @override
  String get component_visible_divider => 'Linha Divisória Visível';

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
      'Nome do fluxo salvo para executar na seleção';

  @override
  String get confirm => 'Confirmar';

  @override
  String get copy => 'Copiar';

  @override
  String get create => 'Criar';

  @override
  String get dart_editor_empty =>
      'Script vazio — comece a escrever para ver os diagnósticos Dart.';

  @override
  String get dart_editor_tap_hint => 'Toque para abrir o editor Dart';

  @override
  String get dart_editor_title => 'Editor Dart';

  @override
  String get dashboard_analysis_period => 'Período de análise';

  @override
  String dashboard_error(String error) {
    return 'Não foi possível carregar as estatísticas: $error';
  }

  @override
  String get dashboard_error_rate => 'Taxa de erro';

  @override
  String get dashboard_execution_health_title => 'Saúde da execução';

  @override
  String dashboard_executions(int count) {
    return '$count execuções';
  }

  @override
  String get dashboard_failed_commands => 'Falhas';

  @override
  String get dashboard_loading => 'Carregando estatísticas...';

  @override
  String get dashboard_no_data =>
      'Ainda não há dados de uso do comando. Execute seu bot para começar a rastrear.';

  @override
  String get dashboard_p50_latency => 'Latência p50';

  @override
  String get dashboard_p95_latency => 'Latência p95';

  @override
  String get dashboard_period_24h => 'Últimas 24h';

  @override
  String get dashboard_period_30d => 'Últimos 30 dias';

  @override
  String get dashboard_period_7d => 'Últimos 7 dias';

  @override
  String get dashboard_premium_analytics_desc =>
      'Desbloqueie taxa de erro, percentis de latência e insights de idioma.';

  @override
  String get dashboard_premium_analytics_title => 'Análises Premium';

  @override
  String get dashboard_refresh_sources_tooltip =>
      'Atualizar servidores de execução';

  @override
  String get dashboard_requires_runner =>
      'Conecte-se a um runner para ver as estatísticas de uso do comando.';

  @override
  String dashboard_selected_period_total(int count) {
    return '$count no período selecionado';
  }

  @override
  String get dashboard_single_runner_notice =>
      'As estatísticas mostradas são apenas do runner configurado no momento. Se você executar bots em vários runners, esta visualização pode estar incompleta.';

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
      'Todos os replays gravados serão apagados. Continuar?';

  @override
  String get debug_replay_clear_title => 'Limpar replays';

  @override
  String get debug_replay_duration_label => 'DURAÇÃO';

  @override
  String get debug_replay_empty_capturing =>
      'A capturar… Execute um comando para gravar um replay.';

  @override
  String get debug_replay_empty_idle =>
      'Captura desligada. Ative-a e execute um comando para gravar um replay.';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Profundidade do loop $depth, iteração $iteration';
  }

  @override
  String get debug_replay_overview => 'Visão geral';

  @override
  String get debug_replay_pause => 'Pausa';

  @override
  String get debug_replay_play => 'Reproduzir';

  @override
  String get debug_replay_premium_desc =>
      'Grave e reproduza as execuções dos seus comandos passo a passo. Veja exatamente o que cada ação fez, quanto tempo levou e onde ocorreram erros.';

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
    return '+$ms ms desde o início';
  }

  @override
  String get debug_replay_step_back => 'Passo anterior';

  @override
  String get debug_replay_step_first => 'Primeiro passo';

  @override
  String get debug_replay_step_forward => 'Próximo passo';

  @override
  String get debug_replay_step_last => 'Último passo';

  @override
  String get debug_replay_stop_capture => 'Desativar captura';

  @override
  String get debug_replay_title => 'Replay do Depurador';

  @override
  String get debug_replay_variables_empty => '(sem variáveis)';

  @override
  String get debug_replay_variables_label => 'VARIÁVEIS';

  @override
  String get delete => 'Eliminar';

  @override
  String get done => 'Concluído';

  @override
  String download_completed(String id) {
    return 'Download concluído: $id';
  }

  @override
  String download_failed(String error) {
    return 'Download falhou: $error';
  }

  @override
  String get download_legacy_backup => 'Download concluído (backup legado)';

  @override
  String get drive_legacy_snapshot => 'Snapshot legado';

  @override
  String get drive_manual_backup => 'Backup manual';

  @override
  String get edit_shell_all_saved => 'Todas as alterações salvas';

  @override
  String get edit_shell_command_body => 'Corpo do comando';

  @override
  String get edit_shell_command_settings => 'Configurações do comando';

  @override
  String get edit_shell_command_settings_desc =>
      'Metadados, disponibilidade, permissões e posicionamento em pastas.';

  @override
  String get edit_shell_local_draft => 'Rascunho local';

  @override
  String get edit_shell_local_only => 'Apenas local';

  @override
  String edit_shell_routes_count(int count) {
    return '$count rota(s)';
  }

  @override
  String get edit_shell_save_changes => 'Salvar alterações';

  @override
  String get edit_shell_subtitle =>
      'Configurações e entradas estão no topo. Ações e resposta seguem abaixo.';

  @override
  String get edit_shell_trigger_inputs => 'Gatilho e Entradas';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Ajuste as opções do comando, comportamento do gatilho e modo de execução.';

  @override
  String get edit_shell_type_command => 'Comando';

  @override
  String get edit_shell_type_legacy => 'Comando legado';

  @override
  String get edit_shell_type_message => 'Comando de mensagem';

  @override
  String get edit_shell_type_slash => 'Comando de barra';

  @override
  String get edit_shell_type_user => 'Comando de usuário';

  @override
  String get edit_shell_unsaved => 'Alterações não salvas';

  @override
  String get edit_shell_untitled_command => 'Comando sem título';

  @override
  String get editor_sidebar_collapse => 'Recolher barra lateral';

  @override
  String get editor_sidebar_expand => 'Expandir barra lateral';

  @override
  String get embed_add_field => 'Adicionar Campo';

  @override
  String get embed_add_section => 'Adicionar Seção';

  @override
  String get embed_add_tooltip => 'Adicionar embed';

  @override
  String get embed_color_picker_title => 'Escolher cor do embed';

  @override
  String get embed_delete_confirm => 'Este embed será removido. Continuar?';

  @override
  String get embed_delete_title => 'Excluir embed';

  @override
  String embed_empty_message(int max) {
    return 'Sem embeds. Você pode adicionar até $max embeds.';
  }

  @override
  String get embed_field_delete_confirm =>
      'Este campo será removido do embed. Continuar?';

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
  String get embed_label_author_icon => 'URL do Ícone do Autor';

  @override
  String get embed_label_author_name => 'Nome do Autor';

  @override
  String get embed_label_author_url => 'URL do Autor';

  @override
  String get embed_label_color => 'Cor (int ou #hex)';

  @override
  String get embed_label_dynamic_fields => 'Modelo de Campos Dinâmicos';

  @override
  String get embed_label_footer_icon => 'URL do Ícone do Rodapé';

  @override
  String get embed_label_footer_text => 'Texto do Rodapé';

  @override
  String get embed_label_image_url => 'URL da Imagem';

  @override
  String get embed_label_inline => 'Em linha';

  @override
  String get embed_label_thumbnail_url => 'URL da Miniatura';

  @override
  String get embed_label_timestamp => 'Data/Hora (ISO8601)';

  @override
  String get embed_checkbox_current_timestamp => 'Data/Hora atual';

  @override
  String get embed_hint_timestamp =>
      'Mostra a hora atual quando o comando é executado. Para segundos Unix no texto, use ((timestamp)) nos campos de mensagem.';

  @override
  String get embed_label_title => 'Título';

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
  String get embed_section_dynamic_fields => 'Campos Dinâmicos';

  @override
  String get embed_section_fields => 'Campos';

  @override
  String get embed_section_footer => 'Rodapé';

  @override
  String get embed_section_media => 'Mídia';

  @override
  String get embed_section_timestamp => 'Data/Hora';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Eliminar :$name: ? Esta ação não pode ser desfeita.';
  }

  @override
  String get emojis_delete_confirm_title => 'Eliminar Emoji';

  @override
  String emojis_delete_error(String error) {
    return 'Eliminação falhou: $error';
  }

  @override
  String get emojis_delete_tooltip => 'Excluir';

  @override
  String get emojis_empty =>
      'Ainda não existem emojis. Carregue um para começar.';

  @override
  String get emojis_loading_error => 'Falha ao carregar emojis';

  @override
  String emojis_rename_error(String error) {
    return 'Renomeação falhou: $error';
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
  String get emojis_title => 'Emojis da Aplicação';

  @override
  String get emojis_upload => 'Carregar Emoji';

  @override
  String emojis_upload_error(String error) {
    return 'Carregamento falhou: $error';
  }

  @override
  String get emojis_upload_name_hint => 'Nome do emoji (letras, números, _)';

  @override
  String get emojis_upload_pick_image => 'Escolher Imagem';

  @override
  String get error => 'Erro';

  @override
  String get error_delete_messages_failed => 'Falha ao apagar mensagens.';

  @override
  String get error_invalid_channel_type => 'O canal não é um canal de texto.';

  @override
  String get error_invalid_count => 'A contagem deve ser superior a 0.';

  @override
  String get error_network_timeout =>
      'A ação expirou. Por favor, tente novamente.';

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
    return 'Falha na exportação: $error';
  }

  @override
  String get export_file_picker_busy => 'Seletor de arquivo já está aberto';

  @override
  String get export_global_variables => 'Variáveis Globais';

  @override
  String get export_import_title => 'Exportar / Importar';

  @override
  String get export_section_desc =>
      'Exporte secções selecionadas do seu bot como um ficheiro ZIP. O token do bot nunca é incluído.';

  @override
  String get export_section_title => 'Exportar';

  @override
  String get export_status => 'Status & Atividades';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get globals_add => 'Adicionar Variável';

  @override
  String get globals_add_global => 'Adicionar Variável Global';

  @override
  String get globals_add_scoped => 'Adicionar Variável Scoped';

  @override
  String get globals_copy_value => 'Copiar valor';

  @override
  String globals_delete_confirm(String key) {
    return 'Apagar \"$key\"?';
  }

  @override
  String get globals_delete_title => 'Apagar Variável';

  @override
  String get globals_dialog_global_desc =>
      'Variáveis globais são partilhadas entre todos os comandos e servidores.';

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Uso: \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Uma variável scoped armazena um valor separado por contexto de $scope.';
  }

  @override
  String get globals_edit => 'Editar Variável';

  @override
  String get globals_edit_global => 'Editar Variável Global';

  @override
  String get globals_edit_scoped => 'Editar Variável Scoped';

  @override
  String get globals_empty => 'Ainda não há variáveis globais';

  @override
  String get globals_empty_subtitle =>
      'Adicione uma variável para armazenar dados persistentes acessíveis por todos os comandos.';

  @override
  String get globals_help_global =>
      'Partilhada entre todos os comandos. Aceda via \$getVar[chave].';

  @override
  String get globals_help_scoped =>
      'Armazenada por contexto (servidor, utilizador, canal…). Cada entrada mantém um valor distinto por contexto do Discord.';

  @override
  String get globals_key => 'Chave';

  @override
  String get globals_key_hint => 'ex: prefixo, nivel, mensagem_boas_vindas';

  @override
  String get globals_mode_global => 'Global';

  @override
  String get globals_mode_scoped => 'Escopo';

  @override
  String get globals_no_default => 'Sem valor padrão';

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
  String get globals_search => 'Procurar variáveis…';

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
  String get globals_title => 'Variáveis';

  @override
  String get globals_value => 'Valor';

  @override
  String get globals_value_auto_type_hint =>
      'O valor é tipado automaticamente (número, booleano, JSON).';

  @override
  String get guilds_empty_state =>
      'O bot não está em nenhum servidor.\nConvide-o para um servidor para vê-lo aqui.';

  @override
  String guilds_leave_confirm(String name) {
    return 'Sair de \"$name\"?\nO bot será removido deste servidor. Você pode convidá-lo novamente mais tarde pelo portal de desenvolvedores do Discord.';
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
  String get guilds_owner_label => '👑 Proprietário';

  @override
  String guilds_server_count_other(int count) {
    return '$count servidores';
  }

  @override
  String get guilds_tab => 'Servidores';

  @override
  String get guilds_tab_short => 'Servidores';

  @override
  String get hint_use_variables => 'Use variáveis/modelos se necessário';

  @override
  String get home_add_time => 'Adicionar Tempo';

  @override
  String get home_add_time_mobile_only =>
      'Os anúncios recompensados são assistidos no aplicativo móvel; o tempo creditado vale em todos os lugares.';

  @override
  String get home_hosting_unlimited_overline => 'Alojamento incluído';

  @override
  String get home_hosting_unlimited_headline =>
      'Ilimitado com a tua subscrição';

  @override
  String get home_hosting_remaining_overline => 'Tempo restante';

  @override
  String get home_overline => 'MEUS PROJETOS';

  @override
  String get home_create_bot_title => 'Criar um bot';

  @override
  String get home_create_bot_subtitle => 'O teu bot Discord em dois cliques';

  @override
  String home_active_on_servers_one(int count) {
    return 'Ativo em $count servidor';
  }

  @override
  String home_active_on_servers_other(int count) {
    return 'Ativo em $count servidores';
  }

  @override
  String get home_synced_active => 'Sincronizado e ativo';

  @override
  String get home_empty_support_btn => 'Junte-se ao nosso Discord';

  @override
  String get home_empty_support_hint => 'Precisa de ajuda para começar?';

  @override
  String get home_foreground_service_not_started =>
      'O serviço de primeiro plano não iniciou.';

  @override
  String get home_hosting_expired => 'Hospedagem expirada';

  @override
  String home_hosting_time_left(String time) {
    return 'Tempo de Alojamento restante: $time';
  }

  @override
  String home_hosting_banked(String time) {
    return 'Reserva: $time';
  }

  @override
  String home_hosting_expires_today(String time) {
    return 'Expira hoje às $time';
  }

  @override
  String home_hosting_expires_tomorrow(String time) {
    return 'Expira amanhã às $time';
  }

  @override
  String get home_hosting_time_preserved =>
      'O tempo é preservado enquanto o bot estiver parado.';

  @override
  String get home_hosting_time_preserved_overline => 'Tempo preservado';

  @override
  String get home_hosting_expiration_expected => 'Expiração prevista';

  @override
  String home_hosting_expires_at(String date, String time) {
    return '$date às $time';
  }

  @override
  String get home_hosting_status_active_short => 'Sessão ativa';

  @override
  String get home_hosting_status_paused_short => 'Tempo reservado';

  @override
  String get home_hosting_total => 'Tempo total';

  @override
  String get home_hosting_status_active => 'Sessão ativa (online)';

  @override
  String get home_hosting_status_paused => 'Tempo reservado (em pausa)';

  @override
  String get home_hosting_ad_history => 'Histórico de anúncios';

  @override
  String get home_hosting_ad_rewards_history_title =>
      'Histórico de recompensas de anúncios';

  @override
  String get home_hosting_ad_history_error =>
      'Falha ao carregar o histórico de anúncios';

  @override
  String get home_hosting_ad_history_empty =>
      'Nenhuma recompensa de anúncio recente registrada para este bot.';

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
      'A permissão de notificação é necessária para iniciar o bot.';

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
  String bot_start_target_title(String bot) {
    return 'Onde iniciar $bot?';
  }

  @override
  String get bot_start_local_title => 'Iniciar localmente (este dispositivo)';

  @override
  String get bot_start_local_desc =>
      'Grátis, não consome nada. O bot para quando fechas a aplicação.';

  @override
  String get bot_start_server_title => 'Iniciar no Bot Creator Server';

  @override
  String get bot_start_server_desc =>
      'Consome os teus minutos de alojamento (ilimitado com PREMIUM). O bot funciona sem o teu dispositivo.';

  @override
  String get bot_start_server_reason_platform =>
      'Este dispositivo não controla o alojamento remoto.';

  @override
  String get bot_start_server_reason_no_account =>
      'Nenhuma conta está ligada neste dispositivo.';

  @override
  String get bot_start_server_reason_cloud_disabled =>
      'O alojamento na cloud não está ativado neste servidor.';

  @override
  String get bot_start_server_reason_no_minutes =>
      'Sem minutos de alojamento: vê um anúncio na aplicação móvel ou passa para PREMIUM.';

  @override
  String get home_start_ads => 'Iniciar (Ver Anúncio)';

  @override
  String get home_start_premium => 'Iniciar (Premium)';

  @override
  String get home_status_offline => 'Offline';

  @override
  String get home_status_online => 'Online';

  @override
  String get home_stop => 'Parar';

  @override
  String get home_sync_failed => 'Falha na sincronização';

  @override
  String get home_tab => 'Início';

  @override
  String get home_time_added => 'Tempo adicionado com sucesso';

  @override
  String home_token_missing(String botName) {
    return 'Token não encontrado para $botName';
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
    return 'Falha na importação: $error';
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
  String get import_summary_variables_imported => 'variáveis importadas';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count workflow(s) importado(s)';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count workflow(s) ignorado(s)';
  }

  @override
  String js_diag_unclosed_opening(String opening, String line) {
    return '“$opening” não fechado, aberto na linha $line.';
  }

  @override
  String js_diag_unexpected_closing(String closing) {
    return 'Fechamento inesperado “$closing”.';
  }

  @override
  String get js_diag_unterminated_comment =>
      'Comentário de bloco não finalizado.';

  @override
  String get js_diag_unterminated_string => 'Literal de string não finalizado.';

  @override
  String get js_diag_unterminated_template =>
      'Template literal não finalizado.';

  @override
  String get js_editor_auto_indent =>
      '• Indentação automática inteligente ao pressionar Enter';

  @override
  String get js_editor_hint => '// Escreva seu comando JavaScript aqui...';

  @override
  String get js_editor_diagnostics_clean =>
      'Nenhum problema de sintaxe detectado.';

  @override
  String get js_editor_empty =>
      'Script vazio — comece a digitar para ver os diagnósticos.';

  @override
  String get js_editor_includes => 'Inclui:';

  @override
  String get js_editor_indent_guides => '• Guias de indentação em tempo real';

  @override
  String get js_editor_quick_keys =>
      '• Teclas rápidas móveis para símbolos JavaScript';

  @override
  String get js_editor_segmented_label => 'JS';

  @override
  String get js_editor_subtitle =>
      'Escreva JavaScript personalizado para este comando';

  @override
  String get js_editor_title => 'Editor JavaScript';

  @override
  String get js_editor_ux_title => 'UX do editor';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'Falha ao executar o script BDFD para o comando \"$command\": $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'Lida com comandos de messageCreate usando <prefixo><comando>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Usa opções posicionais (exemplo: !config #canal).';

  @override
  String get legacy_prefix_mode_title => 'Modo de Prefixo Legado';

  @override
  String get legacy_prefix_override_hint =>
      'Exemplo: ? ou ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label =>
      'Substituição de prefixo (opcional)';

  @override
  String get legacy_response_banner_body =>
      'Alguns comandos ainda usam o formato de resposta antigo. Abra-os no editor e salve novamente para ativar o novo formato.';

  @override
  String get legacy_response_banner_dismiss => 'Dispensar';

  @override
  String get legacy_response_banner_migrate => 'Migrar tudo';

  @override
  String get legacy_response_banner_migrate_failed => 'Falha na migração';

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
      'Atualização de comandos disponível';

  @override
  String get legacy_response_banner_title =>
      'Atualização do formato de resposta dos comandos';

  @override
  String get legacy_response_mode_label => 'Modo de resposta legado';

  @override
  String get local_command_awaited_desc =>
      'Presets de callback aguardados permanecem locais porque são callbacks internos de tempo de execução.';

  @override
  String get local_command_desc =>
      'Armazene o comando apenas no Bot Creator. Você pode registrá-lo dinamicamente em Servidores Específicos usando BDFD \$registerGuildCommands.';

  @override
  String get local_command_title => 'Comando Local (Não registrar no Discord)';

  @override
  String logs_runner_source(String name) {
    return 'Logs de: $name';
  }

  @override
  String get marketplace_about => 'Sobre';

  @override
  String get marketplace_add => 'Adicionar';

  @override
  String get marketplace_api_unavailable => 'Cliente API indisponível';

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
    return 'por $author · v$version';
  }

  @override
  String get marketplace_cancel => 'Cancelar';

  @override
  String marketplace_command_preview_actions(Object count) {
    return '$count ações';
  }

  @override
  String get marketplace_command_preview_no_actions => 'Nenhuma ação';

  @override
  String marketplace_command_preview_options(Object count) {
    return '$count opções';
  }

  @override
  String get marketplace_command_preview_type_message =>
      'Menu de contexto mensagem';

  @override
  String get marketplace_command_preview_type_slash => 'Comando slash';

  @override
  String get marketplace_command_preview_type_user =>
      'Menu de contexto usuário';

  @override
  String marketplace_commands_label(Object count) {
    return 'Comandos ($count)';
  }

  @override
  String get marketplace_config_hint =>
      'Preencha os valores obrigatórios antes de aplicar este modelo.';

  @override
  String get marketplace_config_required => 'Configuração necessária';

  @override
  String marketplace_conflict_apply_choice(Object count) {
    return 'Aplicar ($count template)';
  }

  @override
  String get marketplace_conflict_keep_local => 'Manter Local';

  @override
  String marketplace_conflict_local_info(Object count) {
    return 'Local ($count ações)';
  }

  @override
  String get marketplace_conflict_subtitle =>
      'Alguns comandos do template já existem. Escolhe qual versão manter:';

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'Template ($count ações)';
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
    return 'Tem certeza que deseja excluir \"$name\"? Isso não pode ser desfeito.';
  }

  @override
  String get marketplace_delete_confirm_title => 'Excluir Template';

  @override
  String get marketplace_delete_success => 'Template excluído.';

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
      'Você precisa conectar sua conta Discord para acessar o Marketplace.';

  @override
  String get marketplace_login_instructions =>
      'Por favor, autentique-se via Discord para continuar usando o Marketplace.';

  @override
  String get marketplace_login_required => 'Conexão Discord necessária';

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
  String get marketplace_no_variables => 'Nenhuma variável global definida.';

  @override
  String get marketplace_publish_add_variable => 'Adicionar variável';

  @override
  String get marketplace_publish_add_variable_title => 'Adicionar variável';

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
  String get marketplace_publish_desc_label => 'Descrição curta';

  @override
  String get marketplace_publish_desc_long_hint =>
      'Instruções detalhadas de uso, markdown suportado...';

  @override
  String get marketplace_publish_desc_long_label =>
      'Documentação completa (opcional)';

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
      'Descreva seu modelo para que outros possam encontrá-lo e usá-lo.';

  @override
  String get marketplace_publish_name_hint => 'ex: Bot de Moderação IA';

  @override
  String get marketplace_publish_name_label => 'Nome do modelo';

  @override
  String get marketplace_publish_next => 'Próximo';

  @override
  String get marketplace_publish_no_content =>
      'Nenhum comando ou workflow para publicar.\nCrie alguns primeiro!';

  @override
  String get marketplace_publish_required_fields =>
      'Por favor, preencha todos os campos obrigatórios (Nome, Descrição curta, Versão) antes de publicar.';

  @override
  String get marketplace_publish_select => 'Selecionar conteúdo';

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
  String get marketplace_publish_tags_label => 'Tags (separadas por vírgula)';

  @override
  String get marketplace_publish_title => 'Publicar modelo';

  @override
  String get marketplace_publish_user_must_define =>
      'Usuário deve definir este valor';

  @override
  String get marketplace_publish_user_must_define_hint =>
      'O usuário será solicitado a preenchê-lo antes de aplicar';

  @override
  String get marketplace_publish_variable_desc_hint =>
      'Para que serve esta variável';

  @override
  String get marketplace_publish_variable_desc_label => 'Descrição';

  @override
  String get marketplace_publish_variable_name_hint => 'ex: TOKEN_OPENAI';

  @override
  String get marketplace_publish_variable_name_label => 'Nome da variável';

  @override
  String get marketplace_publish_variables => 'Variáveis globais';

  @override
  String get marketplace_publish_variables_hint =>
      'Inclua variáveis e marque quais o usuário deve preencher.';

  @override
  String get marketplace_publish_version_label => 'Versão';

  @override
  String marketplace_publish_workflows(Object count) {
    return 'Fluxos de Trabalho ($count)';
  }

  @override
  String get marketplace_publishing => 'Publicando...';

  @override
  String get marketplace_rate_success => 'Avaliação enviada!';

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
    return '$name é obrigatório';
  }

  @override
  String get marketplace_variables_label => 'Variáveis pré-configuradas';

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
  String get modal_default_value => 'Valor padrão';

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
      'Este campo será removido do modal. Continuar?';

  @override
  String get modal_remove_field_title => 'Remover campo do modal';

  @override
  String get modal_style => 'Estilo:';

  @override
  String get modal_title_label => 'Título do Modal';

  @override
  String get modal_workflow_submit =>
      'Fluxo de trabalho para executar no envio (opcional)';

  @override
  String get more_options_title => 'Mais Opções';

  @override
  String get more_tab => 'Mais';

  @override
  String get nav_webhooks => 'Webhooks';

  @override
  String get nav_webhooks_compact => 'Hooks';

  @override
  String get no_more_options => 'Nenhuma outra opção disponível';

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
      'Exemplo:\n/hello → O bot responde \"Olá! 👋\"';

  @override
  String get onboarding_command_learn => 'Aprenda como os comandos funcionam';

  @override
  String get onboarding_command_text =>
      'Os comandos são o coração do seu bot. Eles permitem que os utilizadores interajam com o seu bot via Discord.';

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
      '1. Vá ao Portal de Programadores do Discord\n2. Crie uma nova aplicação\n3. Copie o token do bot\n4. Cole-o abaixo';

  @override
  String get onboarding_create_tip =>
      '💡 Dica: Nunca partilhe o seu token! Ele dá acesso total ao seu bot.';

  @override
  String get onboarding_create_title => 'Passo 1: Criar um Bot';

  @override
  String get onboarding_create_tutorial => 'Tutorial: Como obter um token';

  @override
  String get onboarding_remind_later => 'Lembrar mais tarde';

  @override
  String get onboarding_skip_confirm => 'Pular introdução';

  @override
  String get onboarding_skip_dialog_desc =>
      'Você pode continuar de onde parou na próxima vez ou pular o tour completamente.';

  @override
  String get onboarding_skip_dialog_title => 'Sair da introdução?';

  @override
  String get onboarding_start_button => 'Continuar';

  @override
  String get onboarding_start_desc => 'Lance o seu bot!';

  @override
  String get onboarding_start_hint =>
      'Depois de criar seu bot, você encontrará o botão Iniciar no cartão dele no aplicativo.';

  @override
  String get onboarding_start_text =>
      'Clique no botão \"Iniciar\" no cartão do seu bot. Depois teste o seu comando no Discord!';

  @override
  String get onboarding_start_tip =>
      '✨ Fantástico! Criou o seu primeiro bot do Discord. Agora pode adicionar mais comandos e personalizá-lo!';

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
      'O seu bot do Discord está pronto a funcionar!';

  @override
  String get onboarding_success_tip1 => 'Adicionar mais comandos';

  @override
  String get onboarding_success_tip2 => 'Criar fluxos de trabalho';

  @override
  String get onboarding_success_tip3 => 'Fazer cópia de segurança dos dados';

  @override
  String get onboarding_success_title => 'Parabéns! 🎉';

  @override
  String get onboarding_success_whatsnext => 'O que se segue?';

  @override
  String get onboarding_welcome_desc =>
      'Crie o seu primeiro bot do Discord em 3 passos simples. Vamos guiá-lo em cada etapa.';

  @override
  String get onboarding_welcome_skip => 'Saltar';

  @override
  String get onboarding_welcome_start => 'Começar';

  @override
  String get onboarding_welcome_title => 'Bem-vindo ao Bot Creator';

  @override
  String get option_add_choice => 'Adicionar Escolha';

  @override
  String get option_add_localizations => 'Adicionar Localizações';

  @override
  String get option_choice_delete_confirm =>
      'Esta escolha será removida. Continuar?';

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
    return 'Opção $index';
  }

  @override
  String get option_delete_argument_confirm =>
      'Este argumento será removido. Continuar?';

  @override
  String get option_delete_argument_title => 'Excluir argumento';

  @override
  String get option_delete_choice_confirm =>
      'Esta escolha será removida. Continuar?';

  @override
  String get option_delete_choice_title => 'Excluir opção';

  @override
  String get option_delete_confirm => 'Esta opção será removida. Continuar?';

  @override
  String get option_delete_localization_confirm =>
      'Esta entrada de localização será removida. Continuar?';

  @override
  String get option_delete_localization_title => 'Excluir localização';

  @override
  String get option_delete_title => 'Excluir opção';

  @override
  String get option_desc_required =>
      'Por favor, insira uma descrição para a opção';

  @override
  String option_label_number(int index) {
    return 'Rótulo $index';
  }

  @override
  String get option_localized_description => 'Descrição Localizada';

  @override
  String get option_localized_name => 'Nome Localizado';

  @override
  String get option_max_value => 'Valor Máximo';

  @override
  String get option_min_value => 'Valor Mínimo';

  @override
  String get option_name_duplicate =>
      'Este nome já está sendo usado neste nível';

  @override
  String get option_name_invalid_chars =>
      'Nomes de opção devem ter 1-32 caracteres em minúsculas. Permitidos: letras, números, hífens, sublinhados e apóstrofos.';

  @override
  String get option_name_invalid_start =>
      'O nome da opção começa com um caractere não suportado';

  @override
  String get option_name_max_length =>
      'O nome da opção deve ter no máximo 32 caracteres';

  @override
  String get option_name_required => 'Por favor, insira um nome para a opção';

  @override
  String get option_select_language => 'Selecionar Idioma';

  @override
  String option_static_label_n(int index) {
    return 'Rótulo $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Valor $index';
  }

  @override
  String get option_subcommand_options => 'Opções do Subcomando';

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
  String get option_type_mentionable => 'Mencionável';

  @override
  String get option_type_number => 'Número';

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
  String get option_type_user => 'Usuário';

  @override
  String option_value_number(int index) {
    return 'Valor $index';
  }

  @override
  String get premium_active_desc =>
      'Obrigado pelo seu apoio! Todos os anúncios estão desativados.';

  @override
  String get premium_active_title => 'Premium ativo';

  @override
  String get premium_card_button => 'Ver planos';

  @override
  String get premium_locked_hint =>
      'A tua conta está no plano gratuito: a subscrição é ativada na aplicação móvel (este dispositivo não mostra publicidade nem compras).';

  @override
  String get premium_card_desc =>
      'Assine para remover todos os anúncios e iniciar seus bots instantaneamente, sem nenhum pop-up.';

  @override
  String get premium_card_title => 'Remover Anúncios';

  @override
  String get quick_access_title => 'Acesso Rápido';

  @override
  String get recovery_delete_bot => 'Excluir bot localmente';

  @override
  String get recovery_label => 'Recuperação';

  @override
  String get recovery_retry_discord => 'Tentar novamente conexão com Discord';

  @override
  String get recovery_title => 'Modo de recuperação';

  @override
  String reply_active_route(String label) {
    return 'Rota ativa: $label';
  }

  @override
  String get reply_buttons_desc =>
      'Adicione botões interativos ou menus suspensos a esta mensagem';

  @override
  String get reply_buttons_optional => 'Botões e Menus de Seleção (opcional)';

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
      'Sistema de layout rico do Discord — contêineres, mídia, texto e formulários';

  @override
  String get reply_mode_modal => 'Formulário Modal';

  @override
  String get reply_mode_modal_desc =>
      'Diálogo pop-up com campos de entrada de texto';

  @override
  String get reply_mode_standard => 'Mensagem Padrão';

  @override
  String get reply_mode_standard_desc =>
      'Texto, embeds e botões / menus de seleção opcionais';

  @override
  String get reply_response_text_helper =>
      'Usado como texto de resposta do comando de barra. Suporta a sintaxe ((variável)).';

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
  String get response_mode_modal => 'Formulário modal';

  @override
  String get response_mode_standard => 'Mensagem padrão';

  @override
  String get response_visibility_ephemeral => 'efêmero';

  @override
  String get response_visibility_public => 'público';

  @override
  String get response_workflow_auto_defer =>
      'Adiar automaticamente se houver ações';

  @override
  String get response_workflow_auto_defer_desc =>
      'Reconheça rapidamente, execute ações e edite a resposta final.';

  @override
  String get response_workflow_condition_desc =>
      'Se a variável existir e não estiver vazia => use o texto ENTÃO, caso contrário use o texto SENÃO.';

  @override
  String get response_workflow_conditional_title =>
      'Resposta condicional (MVP)';

  @override
  String get response_workflow_deferred_reply => 'Resposta adiada';

  @override
  String get response_workflow_else_text => 'Texto de resposta ELSE (opcional)';

  @override
  String get response_workflow_enable_condition => 'Ativar condição';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Efêmero (apenas o usuário do comando)';

  @override
  String get response_workflow_error_policy => 'Política de erro';

  @override
  String get response_workflow_error_policy_desc =>
      'Quando uma ação falha, edite a mensagem adiada com um erro.';

  @override
  String get response_workflow_mode_component => 'Componente';

  @override
  String get response_workflow_mode_modal => 'Modal';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_public => 'Público';

  @override
  String get response_workflow_revert_tooltip => 'Reverter todas as alterações';

  @override
  String get response_workflow_then_text => 'Texto de resposta THEN (opcional)';

  @override
  String get response_workflow_title => 'Fluxo de Resposta';

  @override
  String get response_workflow_variable_key =>
      'Chave da variável (ex: opts.userId)';

  @override
  String get response_workflow_visibility => 'Visibilidade';

  @override
  String get restore_completed => 'Restauro concluído';

  @override
  String get restore_runtime_db_recommended =>
      'Restauro concluído (SQLite restaurado, recomenda-se reiniciar)';

  @override
  String get review_actions_title => 'Ações';

  @override
  String review_description_line(String desc) {
    return 'Descrição: $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Pasta: $folder';
  }

  @override
  String get review_info_title => 'Informações';

  @override
  String get review_legacy_mode => 'Modo prefixo ativado';

  @override
  String get review_local_only => 'Comando apenas local';

  @override
  String review_name_line(String name) {
    return 'Nome: $name';
  }

  @override
  String get review_name_untitled => '(sem título)';

  @override
  String review_options_count(int count) {
    return '$count opção(ões)';
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
      'Por favor, assista ao anúncio completo para iniciar sua sessão de hospedagem.';

  @override
  String get rewarded_start_continue => 'Continuar';

  @override
  String get rewarded_start_message =>
      'É necessário um anúncio para iniciar esta sessão de alojamento. Isto ajuda a financiar o projeto. Utilizadores Premium podem saltar isto.';

  @override
  String get rewarded_start_no_ad_available =>
      'Nenhum anúncio disponível no momento. Por favor, tente novamente mais tarde.';

  @override
  String get rewarded_start_skip => 'Saltar';

  @override
  String get rewarded_start_thanks => 'Obrigado pelo seu apoio!';

  @override
  String get rewarded_start_title => 'Anúncio Necessário';

  @override
  String get rewarded_start_watch => 'Ver anúncio';

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
      'Inicie sessão no Bot Creator nas Configurações para carregar estatísticas dos servidores do Bot Creator.';

  @override
  String get runner_source_this_device => 'Este dispositivo';

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
  String get scheduler_label_field => 'Rótulo';

  @override
  String get scheduler_label_hint => 'Rótulo de exibição opcional';

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
    return 'Workflow: $workflow • A cada $minutes min';
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
  String get scoped_default_value => 'Valor padrão';

  @override
  String get scoped_default_value_hint => 'Opcional';

  @override
  String scoped_delete_confirm(String key) {
    return 'Apagar \"$key\" e todos os seus dados de execução armazenados?';
  }

  @override
  String get scoped_delete_title => 'Apagar Variável Scoped';

  @override
  String get scoped_declare_detected => 'Declarar esta variável';

  @override
  String get scoped_detected_badge => 'Detetada';

  @override
  String scoped_detected_hint(int count) {
    return 'Nenhuma definição declarada · $count valor(es) armazenado(s)';
  }

  @override
  String get scoped_detected_tooltip =>
      'Valor presente nos dados do bot sem definição declarada. Exibido tal como está; nada é inventado.';

  @override
  String get scoped_empty => 'Nenhuma variável scoped definida';

  @override
  String get scoped_empty_subtitle =>
      'Variáveis scoped armazenam um valor por contexto do Discord (utilizador, servidor…). São preenchidas pelo bot em execução.';

  @override
  String get scoped_explore_runtime => 'Explorar dados de execução';

  @override
  String scoped_ref(String ref) {
    return 'Referência: $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legado: $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'Copiar tudo';

  @override
  String get scoped_runtime_empty =>
      'Sem dados de execução.\nEsta chave será preenchida pelo bot durante a execução.';

  @override
  String get scoped_runtime_search => 'Procurar por ID ou nome…';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Escopo: $scope · $count contexto(s) encontrado(s)';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Dados de execução — \"$key\"';
  }

  @override
  String get scoped_scope => 'Escopo';

  @override
  String get scoped_scope_help =>
      'O nível da entidade em que a variável é armazenada.';

  @override
  String get scoped_title => 'Variáveis Scoped';

  @override
  String get scratch_add_block => 'Adicionar bloco';

  @override
  String get scratch_bdfd_script => 'Script BDFD';

  @override
  String get scratch_block_entry_point => 'Gatilho do Comando';

  @override
  String get scratch_block_metadata => 'Metadados';

  @override
  String get scratch_block_required => 'Obrigatório';

  @override
  String get scratch_blocks_tab => 'Blocos';

  @override
  String get scratch_custom_id_filter_desc =>
      'Este fluxo de trabalho só será executado se o Custom ID do botão clicado ou modal enviado corresponder exatamente a este ID.';

  @override
  String get scratch_custom_id_filter_hint => 'ex: meu_id_do_botao';

  @override
  String get scratch_custom_id_filter_label => 'Filtro de Custom ID (opcional)';

  @override
  String get scratch_dart_script => 'Script Dart';

  @override
  String get scratch_entry_event_trigger => 'Gatilho de evento';

  @override
  String get scratch_entry_function => 'Função';

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
      'Quando é que este comando é executado?';

  @override
  String get scratch_event_category => 'Categoria do evento';

  @override
  String get scratch_event_name => 'Nome do evento';

  @override
  String get scratch_event_variables => 'Variáveis do evento';

  @override
  String get scratch_execution_mode => 'Como é que o comando é construído?';

  @override
  String get scratch_legacy_config => 'Configuração legada';

  @override
  String get scratch_meta_advanced => 'Definições avançadas';

  @override
  String get scratch_meta_desc_hint => 'Descrição do comando';

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
  String get scratch_mode_bdfd => 'Código BDFD';

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
      'Adicione blocos de ações abaixo para configurar o que o seu bot faz.';

  @override
  String get scratch_wizard_actions_empty_title =>
      'Nenhuma ação definida ainda.';

  @override
  String get scratch_wizard_config_button_instruction =>
      'Configure o ID do botão ou modal que irá disparar este fluxo de trabalho.';

  @override
  String get scratch_wizard_folder_hint => 'ex: admin';

  @override
  String get scratch_wizard_folder_label => 'Pasta (opcional)';

  @override
  String get scratch_wizard_save_details => 'Detalhes de salvamento';

  @override
  String get scratch_wizard_step_actions => 'Passo 3: Ações';

  @override
  String get scratch_wizard_step_config => 'Passo 2: Configuração';

  @override
  String get scratch_wizard_step_save => 'Passo 4: Salvar & Resumo';

  @override
  String get scratch_wizard_step_trigger => 'Passo 1: Tipo de Gatilho';

  @override
  String scratch_wizard_summary_actions_count(int count) {
    return '$count ação(ões) configurada(s)';
  }

  @override
  String get scratch_wizard_summary_title => 'Resumo do Fluxo de Trabalho';

  @override
  String scratch_wizard_summary_trigger_button(String id) {
    return 'Clique no Botão / Modal (Custom ID: \'$id\')';
  }

  @override
  String scratch_wizard_summary_trigger_event(String event) {
    return 'Evento: $event';
  }

  @override
  String get scratch_wizard_summary_trigger_function =>
      'Função Geral / Fluxo de Trabalho';

  @override
  String get scratch_wizard_trigger_button_desc =>
      'Dispara quando um usuário clica em um botão, usa um menu de seleção ou envia um formulário modal.';

  @override
  String get scratch_wizard_trigger_button_title =>
      'Botão ou Componente de Mensagem';

  @override
  String get scratch_wizard_trigger_event_desc =>
      'Dispara em uma ação do Discord (ex: novo membro entra, mensagem excluída, cargo atualizado).';

  @override
  String get scratch_wizard_trigger_event_title => 'Evento do Discord';

  @override
  String get scratch_wizard_trigger_function_desc =>
      'Executa o fluxo de trabalho como uma função reutilizável que pode ser chamada por outros gatilhos.';

  @override
  String get scratch_wizard_trigger_function_title => 'Função / Gatilho Manual';

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
  String get scratch_workflow_arguments => 'Argumentos (Variáveis)';

  @override
  String get scratch_workflow_metadata => 'Definições do Workflow';

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
      'Copiar JSON legível para a área de transferência';

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
      'Formato de payload de comando inválido.';

  @override
  String get serialization_invalid_structure =>
      'Estrutura de payload de comando inválida.';

  @override
  String get settings_account_connect_label =>
      'Entrar no Bot Creator com Discord';

  @override
  String get settings_account_connected_hint =>
      'Conta conectada. Seus bots e dados estão agora sincronizados com o Bot Creator.';

  @override
  String get settings_account_disconnect_label => 'Sair';

  @override
  String get settings_account_disconnected_hint =>
      'Sua conta do Bot Creator é criada automaticamente quando você adiciona um bot. Em seguida, faça login com o Discord para recuperar seus bots neste dispositivo.';

  @override
  String get settings_account_status_connected => 'Conta conectada';

  @override
  String get settings_account_status_disconnected => 'Não logado';

  @override
  String get mobile_account_required_title => 'Entrar';

  @override
  String get mobile_account_required_body => 'Entre com Discord ou e-mail.';

  @override
  String get mobile_account_required_feature_bots =>
      'Sincronize e restaure seus bots da nuvem';

  @override
  String get mobile_account_required_feature_hosted =>
      'Implante e gerencie aplicações hospedadas';

  @override
  String get mobile_account_required_feature_recovery =>
      'Recupere tudo após reinstalar ou em um novo telefone';

  @override
  String mobile_account_required_failed(String error) {
    return 'Falha no login com Discord: $error';
  }

  @override
  String get mobile_login_or_divider => 'ou';

  @override
  String get mobile_login_show_email => 'Entrar com e-mail';

  @override
  String get mobile_login_hide_email => 'Ocultar login por e-mail';

  @override
  String get mobile_login_email_title => 'Entrar com e-mail';

  @override
  String get mobile_login_email_hint =>
      'Use o e-mail e a senha vinculados à sua conta.';

  @override
  String get mobile_login_email => 'E-mail';

  @override
  String get mobile_login_password => 'Senha';

  @override
  String get mobile_login_submit => 'Entrar';

  @override
  String get mobile_login_invalid_credentials => 'E-mail ou senha inválidos.';

  @override
  String mobile_login_failed(String error) {
    return 'Falha no login: $error';
  }

  @override
  String get settings_alternative_login_title => 'Login alternativo';

  @override
  String get settings_alternative_login_desc =>
      'Adicione um e-mail e senha para entrar sem Discord.';

  @override
  String settings_alternative_login_current_email(String email) {
    return 'E-mail atual: $email';
  }

  @override
  String get settings_alternative_login_current_password => 'Senha atual';

  @override
  String get settings_alternative_login_confirm_password => 'Confirmar senha';

  @override
  String get settings_alternative_login_update => 'Atualizar credenciais';

  @override
  String get settings_add_credentials => 'Salvar credenciais';

  @override
  String get settings_alternative_login_missing_fields =>
      'E-mail e senha são obrigatórios.';

  @override
  String get settings_alternative_login_password_mismatch =>
      'As senhas não coincidem.';

  @override
  String get settings_credentials_saved => 'Login alternativo salvo.';

  @override
  String get settings_ads_privacy_loading =>
      'A verificar definições de privacidade de anúncios...';

  @override
  String get settings_ads_privacy_manage =>
      'Gerir escolhas de privacidade de anúncios';

  @override
  String get settings_ads_privacy_not_required =>
      'Opções de privacidade de anúncios não são necessárias agora';

  @override
  String get settings_ads_privacy_open_error =>
      'Não foi possível abrir as opções de privacidade de anúncios';

  @override
  String get settings_ads_privacy_opened =>
      'Opções de privacidade de anúncios abertas';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_appearance_accent_label => 'Destaque';

  @override
  String settings_appearance_contrast_ratio(String ratio) {
    return 'Contraste destaque/superfície: $ratio';
  }

  @override
  String settings_appearance_contrast_warning(String ratio) {
    return 'Contraste baixo ($ratio): o destaque quase não se distingue do fundo. A app adapta-o quando necessário, mas um destaque mais claro ou mais escuro melhora a legibilidade.';
  }

  @override
  String get settings_appearance_custom_badge => 'Personalizado';

  @override
  String get settings_appearance_custom_title => 'Cores personalizadas';

  @override
  String get settings_appearance_mode_dark => 'Escuro';

  @override
  String get settings_appearance_mode_light => 'Claro';

  @override
  String get settings_appearance_mode_system => 'Sistema';

  @override
  String get settings_appearance_mode_title => 'Modo';

  @override
  String get settings_appearance_presets_title => 'Temas predefinidos';

  @override
  String get settings_appearance_reset => 'Repor';

  @override
  String get settings_appearance_seed_label => 'Cor principal';

  @override
  String get settings_appearance_subtitle =>
      'Escolha um modo, um tema predefinido ou as suas próprias cores.';

  @override
  String get settings_appearance_title => 'Aspeto';

  @override
  String get settings_auto_backup_check_loading =>
      'A verificar cópia automática…';

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
      'Intervalo de cópia de segurança automática';

  @override
  String get settings_backup_now => 'Fazer cópia de segurança agora';

  @override
  String get settings_backup_restore_desc =>
      'Gerir a sincronização de dados com o Google Drive';

  @override
  String get settings_backup_restore_title => 'Cópia de Segurança e Restauro';

  @override
  String get settings_builtin_help => 'Comando !help legado integrado';

  @override
  String get settings_builtin_help_subtitle =>
      'Recurso obrigatório com alternância explícita. Desative-o se desejar apenas um comportamento de ajuda personalizado.';

  @override
  String get settings_clear_logs => 'Limpar registos';

  @override
  String get settings_cloud_hosting_enabled =>
      'Bots móveis agora usam os servidores do Bot Creator.';

  @override
  String get settings_compatibility_desc =>
      'Uma visão rápida da cobertura de funcionalidades para utilizadores que vêm do BDFD.';

  @override
  String get settings_compatibility_functions_category_components =>
      'Componentes / Interações';

  @override
  String get settings_compatibility_functions_category_control =>
      'Fluxo de controlo';

  @override
  String get settings_compatibility_functions_category_embeds => 'Embeds';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Guardas e permissões';

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
  String get settings_compatibility_functions_category_threads => 'Tópicos';

  @override
  String get settings_compatibility_functions_category_variables =>
      'Variáveis de âmbito';

  @override
  String settings_compatibility_functions_count(int count) {
    return 'Funções compatíveis: $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'Total de referência BDFD: $count';
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
      'Nenhuma função nesta secção.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'Entradas apenas BDFD são funções listadas no catálogo BDFD fornecido mas não implementadas atualmente no Bot Creator.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Vista de diferenças entre a implementação do Bot Creator e as funções de referência BDFD.';

  @override
  String get settings_compatibility_functions_note =>
      'Esta página é gerada a partir do âmbito de implementação atual e crescerá ao longo do tempo.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Procurar uma função (exemplo: \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Suportado apenas no Bot Creator';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Ajudantes de loop são atualmente específicos do Bot Creator.';

  @override
  String get settings_compatibility_functions_section_both =>
      'Suportado no Bot Creator e BDFD';

  @override
  String get settings_compatibility_functions_section_missing =>
      'Disponível no BDFD mas em falta no Bot Creator';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Funções atualmente implementadas e utilizáveis no modo BDFD do Bot Creator.';

  @override
  String get settings_compatibility_functions_title =>
      'Funções BDFD Compatíveis';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Cobertura total do catálogo de funções BDFD.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'Paridade de funções BDScript';

  @override
  String get settings_compatibility_item_events_desc =>
      'A maioria dos eventos comuns é suportada, alguns são limitados pelo runtime.';

  @override
  String get settings_compatibility_item_events_title => 'Cobertura de eventos';

  @override
  String get settings_compatibility_item_runner_desc =>
      'O runner remoto está disponível, o suporte multi-runner está em curso.';

  @override
  String get settings_compatibility_item_runner_title =>
      'Arquitetura do Runner';

  @override
  String get settings_compatibility_item_variables_desc =>
      'Variáveis dinâmicas e ajudantes de template são suportados.';

  @override
  String get settings_compatibility_item_variables_title =>
      'Variáveis de runtime e templates';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Fluxos de trabalho visuais de comando e resposta estão disponíveis.';

  @override
  String get settings_compatibility_item_workflows_title =>
      'Construtor de fluxos';

  @override
  String get settings_compatibility_note =>
      'Este snapshot é intencionalmente de alto nível e evoluirá com as versões.';

  @override
  String get settings_compatibility_open_functions => 'Ver funções compatíveis';

  @override
  String get settings_compatibility_status_missing => 'Em falta';

  @override
  String get settings_compatibility_status_partial => 'Parcial';

  @override
  String get settings_compatibility_status_supported => 'Suportado';

  @override
  String get settings_compatibility_title => 'Snapshot de compatibilidade BDFD';

  @override
  String get settings_data_operations_title => 'Operações de Dados';

  @override
  String get settings_debug_desc =>
      'Repor preferências locais ou repetir a introdução para testes.';

  @override
  String get settings_debug_premium_bypass => 'Bypass Premium';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Desbloquear todas as funcionalidades Premium sem subscrição (apenas depuração).';

  @override
  String get settings_debug_title => 'Ferramentas de depuração';

  @override
  String get settings_diagnostics_copied =>
      'Diagnósticos copiados para a área de transferência';

  @override
  String get settings_diagnostics_copy_all => 'Copiar todos os registos';

  @override
  String get settings_diagnostics_dialog_title => 'Diagnóstico de Arranque';

  @override
  String get settings_diagnostics_empty =>
      'Ainda não existem registos da aplicação.';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Mostra apenas registos de diagnóstico da app (registos do bot são excluídos).';

  @override
  String get settings_diagnostics_page_title => 'Registos da Aplicação';

  @override
  String get settings_diagnostics_refresh => 'Atualizar registos';

  @override
  String get settings_diagnostics_section_title => 'Diagnósticos';

  @override
  String get settings_discord_rpc_authenticating =>
      'A autenticar com o Discord…';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Código de autorização em cache; tente novamente para terminar a troca de token';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Código de autorização recebido';

  @override
  String get settings_discord_rpc_authorize => 'Autorizar';

  @override
  String get settings_discord_rpc_authorizing =>
      'A aguardar autorização do Discord…';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label =>
      'URL do broker OAuth (avançado, opcional)';

  @override
  String get settings_discord_rpc_broker_required =>
      'O ID de cliente é suficiente para o fluxo de cliente público; URL do broker e client secret são fallbacks opcionais';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Este ID é fixo no Bot Creator e não pode ser alterado nas definições.';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'ID de cliente da aplicação Discord necessário';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Fallback avançado opcional para um fluxo de cliente confidencial processado localmente.';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Segredo do cliente';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Client secret da aplicação Discord (opcional)';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Concluir autorização';

  @override
  String get settings_discord_rpc_connect => 'Atualizar presença';

  @override
  String get settings_discord_rpc_connected =>
      'Presença enviada para o Discord';

  @override
  String get settings_discord_rpc_connecting => 'A ligar ao Discord…';

  @override
  String get settings_discord_rpc_desc =>
      'Publique a atividade de desktop do Bot Creator no cliente local do Discord. O Bot Creator utiliza sempre a aplicação Discord integrada e envia SET_ACTIVITY diretamente via IPC local quando ativado.';

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
  String get settings_discord_rpc_exchanging_code => 'A concluir troca OAuth…';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'IPC local do Discord ligado; nenhum pedido HTTP OAuth enviado ainda, autenticação ainda necessária';

  @override
  String get settings_discord_rpc_ipc_open => 'IPC local já aberto';

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'Último erro: $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization =>
      'Autorização necessária';

  @override
  String get settings_discord_rpc_not_configured => 'ID de cliente necessário';

  @override
  String get settings_discord_rpc_open_ipc => 'Abrir IPC local';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence está disponível apenas em desktop';

  @override
  String get settings_discord_rpc_save => 'Guardar definições';

  @override
  String get settings_discord_rpc_saved =>
      'Definições de Discord Rich Presence guardadas';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'O transporte Discord ainda não é suportado nesta plataforma';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Utilizador autorizado: $user';
  }

  @override
  String get settings_drive_connect => 'Ligar ao Google Drive';

  @override
  String get settings_drive_connect_loading => 'A ligar ao Google Drive…';

  @override
  String get settings_drive_connected => 'Ligado ao Google Drive';

  @override
  String get settings_drive_desc =>
      'Ligue a sua conta Google Drive para sincronizar os seus dados';

  @override
  String get settings_drive_disconnect => 'Desligar';

  @override
  String get settings_drive_disconnect_loading => 'A desligar…';

  @override
  String get settings_drive_disconnected => 'Desligado do Google Drive';

  @override
  String get settings_drive_status_connected => 'Ligado';

  @override
  String get settings_drive_title => 'Ligação ao Google Drive';

  @override
  String get settings_enable_auto_backup =>
      'Ativar cópia de segurança automática';

  @override
  String get settings_enable_auto_backup_desc =>
      'Crie snapshots versionados automaticamente quando devidos.';

  @override
  String get settings_execution_mode_desc =>
      'Nesta plataforma, o Bot Creator nunca hospeda seus bots. Você pode usar seu runner auto-hospedado ou executar os bots localmente.';

  @override
  String get settings_execution_mode_local_active =>
      'Os bots agora iniciam localmente. As configurações do runner permanecem armazenadas e podem ser reativadas a qualquer momento.';

  @override
  String get settings_execution_mode_no_runner =>
      'Nenhum runner configurado ainda. O app permanece local até que você adicione um.';

  @override
  String get settings_execution_mode_runner_priority =>
      'O runner auto-hospedado é preferido. Se nenhum runner estiver configurado, o app volta para o local.';

  @override
  String get settings_execution_mode_title => 'Modo de execução';

  @override
  String get settings_execution_mode_use_runner =>
      'Usar um executor hospedado por conta própria';

  @override
  String get settings_export => 'Exportar';

  @override
  String get settings_export_app_data => 'Exportar Dados da App';

  @override
  String get settings_export_loading => 'A exportar…';

  @override
  String get settings_import => 'Importar';

  @override
  String get settings_import_app_data => 'Importar Dados da App';

  @override
  String get settings_import_loading => 'A importar…';

  @override
  String get settings_language_desc => 'Escolha o idioma utilizado pela app.';

  @override
  String get settings_language_system => 'Automático (dispositivo)';

  @override
  String get settings_language_title => 'Idioma';

  @override
  String get settings_language_updated => 'Idioma atualizado';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'Última cópia automática: $date';
  }

  @override
  String get settings_last_auto_backup_never =>
      'Última cópia automática: nunca';

  @override
  String get settings_legacy_prefix => 'Prefixo de comando legado';

  @override
  String get settings_legacy_prefix_helper =>
      'Suporta templates e variáveis de escopo (bc_ opcional). Exemplo: ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? ou ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc =>
      'Reveja como os seus dados são tratados e armazenados.';

  @override
  String get settings_legal_title => 'Avisos Legais';

  @override
  String get settings_local_hosting_enabled =>
      'Bots móveis agora usam seu dispositivo para hospedagem.';

  @override
  String get settings_logs_cleared => 'Registo de diagnósticos limpo';

  @override
  String get settings_main_api_auth_failed =>
      'A sessão do Servidor do Bot Creator é inválida ou expirou';

  @override
  String get settings_main_api_check => 'Verificar Servidor do Bot Creator';

  @override
  String get settings_main_api_clear => 'Limpar';

  @override
  String get settings_main_api_cleared =>
      'Definições do Servidor do Bot Creator limpas';

  @override
  String get settings_main_api_connect_discord => 'Ligar conta Discord';

  @override
  String get settings_main_api_connected =>
      'Servidor do Bot Creator acessível ✓';

  @override
  String get settings_main_api_connected_discord => 'Conta Discord ligada';

  @override
  String settings_main_api_connected_user(String user) {
    return 'Ligado como $user';
  }

  @override
  String get settings_main_api_desc =>
      'Ligue o Bot Creator ao seu Servidor do Bot Creator e inicie sessão com o Discord. O secret do cliente Discord deve permanecer no backend.';

  @override
  String get settings_main_api_desktop_only =>
      'O início de sessão no Discord via Servidor do Bot Creator está disponível apenas no desktop.';

  @override
  String get settings_main_api_disconnect => 'Desligar conta';

  @override
  String get settings_main_api_not_configured =>
      'URL do Servidor do Bot Creator necessário';

  @override
  String get settings_main_api_save => 'Guardar Servidor do Bot Creator';

  @override
  String get settings_main_api_saved =>
      'Definições do Servidor do Bot Creator guardadas';

  @override
  String get settings_main_api_session_connected => 'Sessão Discord ativa';

  @override
  String get settings_main_api_session_disconnected =>
      'Sessão Discord desligada';

  @override
  String get settings_main_api_session_expired => 'Sessão Discord expirou';

  @override
  String get settings_main_api_title => 'Servidor do Bot Creator';

  @override
  String get settings_main_api_unreachable =>
      'Servidor do Bot Creator inacessível';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_url_required =>
      'URL do Servidor do Bot Creator necessário';

  @override
  String get settings_main_api_user_unknown => 'Utilizador Discord';

  @override
  String get settings_manual_snapshot_label => 'Snapshot manual';

  @override
  String get settings_member_badge => 'MEMBRO';

  @override
  String get settings_notifications_desc =>
      'Escolha quais tipos de notificações push deseja receber.';

  @override
  String get settings_notifications_title => 'Notificações';

  @override
  String get settings_notifications_topic_billing => 'Faturamento';

  @override
  String get settings_notifications_topic_billing_desc =>
      'Lembretes de renovação de assinatura e confirmações de pagamento.';

  @override
  String get settings_notifications_topic_botAlerts => 'Alertas de bot';

  @override
  String get settings_notifications_topic_botAlerts_desc =>
      'Avisos quando seus bots ficam offline ou encontram erros.';

  @override
  String get settings_notifications_topic_broadcast => 'Anúncios';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'Anúncios importantes e novidades do Bot Creator.';

  @override
  String get settings_notifications_topic_updates => 'Atualizações';

  @override
  String get settings_notifications_topic_updates_desc =>
      'Novos recursos, atualizações do app e destaques do changelog.';

  @override
  String get settings_open_ad_inspector => 'Abrir Inspetor de Anúncios';

  @override
  String get settings_oss_licenses => 'Licenças Open Source';

  @override
  String get settings_owner_badge => 'PROPRIETÁRIO';

  @override
  String get settings_owner_fallback => 'Proprietário';

  @override
  String get settings_personal_owner_fallback => 'Usuário Pessoal';

  @override
  String get settings_personal_owner_id_label => 'ID do Proprietário: ';

  @override
  String get settings_personal_owner_label => 'Proprietário: ';

  @override
  String get settings_personal_ownership => 'Propriedade Pessoal';

  @override
  String get settings_preferences_reset_done => 'Preferências repostas';

  @override
  String get settings_privacy_policy => 'Política de Privacidade';

  @override
  String get settings_raw_json_tile => 'Ver JSON bruto (RAW JSON)';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_replay_onboarding => 'Repetir introdução';

  @override
  String get settings_replay_onboarding_desc =>
      'Repor introdução e lançá-la novamente agora.';

  @override
  String get settings_reset_preferences => 'Repor preferências';

  @override
  String get settings_reset_preferences_desc =>
      'Repor tema, idioma e progresso da introdução.';

  @override
  String get settings_restore_snapshot => 'Restaurar este Snapshot';

  @override
  String get settings_run_auto_backup_now => 'Executar cópia automática agora';

  @override
  String get settings_run_diagnostics => 'Executar Diagnósticos';

  @override
  String settings_runner_active(String url) {
    return 'API do Runner Ativa: $url';
  }

  @override
  String get settings_runner_auth_failed => 'Runner rejeitou o token da API';

  @override
  String get settings_runner_check => 'Verificar ligação';

  @override
  String get settings_runner_clear => 'Limpar';

  @override
  String get settings_runner_cleared => 'Definições do Runner limpas';

  @override
  String get settings_runner_connected => 'Runner acessível ✓';

  @override
  String get settings_runner_connecting => 'A verificar ligação…';

  @override
  String get settings_runner_desc =>
      'Ligue a app a um Bot Creator Runner. Runners remotos devem permanecer em redes fidedignas e usar um token bearer.';

  @override
  String get settings_runner_use_remote => 'Usar Runner remoto';

  @override
  String get settings_runner_use_remote_desc =>
      'Ligar a um Bot Creator Runner remoto. Deixe desativado para executar os bots localmente neste dispositivo.';

  @override
  String get settings_runner_disable_temp => 'Desativar Runner temporariamente';

  @override
  String get settings_runner_disable_temp_desc =>
      'Manter definições do Runner mas forçar modo local até ser reativado.';

  @override
  String get settings_runner_disconnected => 'Runner desconectado';

  @override
  String get settings_runner_not_connected => 'Não conectado';

  @override
  String get settings_runner_reenabled => 'Runner reativado';

  @override
  String get settings_runner_save => 'Guardar definições';

  @override
  String get settings_runner_saved => 'Definições do Runner guardadas';

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
  String get settings_runner_unreachable => 'Runner inacessível';

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
  String get settings_embedded_runner_title => 'Runner JS incorporado';

  @override
  String settings_embedded_runner_download_progress(
    String received,
    String total,
  ) {
    return '$received de $total';
  }

  @override
  String settings_embedded_runner_download_indeterminate(String received) {
    return '$received transferidos';
  }

  @override
  String get settings_embedded_runner_restart => 'Reiniciar';

  @override
  String get settings_embedded_runner_restart_success =>
      'Runner JS incorporado reiniciado';

  @override
  String get settings_embedded_runner_restart_failed =>
      'Falha ao reiniciar o runner JS incorporado';

  @override
  String get settings_embedded_runner_redownload => 'Transferir novamente';

  @override
  String get settings_embedded_runner_redownload_success =>
      'Runner JS incorporado transferido novamente';

  @override
  String get settings_embedded_runner_redownload_failed =>
      'Falha ao transferir novamente o runner JS incorporado';

  @override
  String get settings_embedded_runner_open_log => 'Abrir log';

  @override
  String settings_embedded_runner_binary_info(String size, String path) {
    return 'Binário: $size · $path';
  }

  @override
  String get settings_embedded_runner_status_running => 'Em execução';

  @override
  String get settings_embedded_runner_status_stopped => 'Não iniciado';

  @override
  String get settings_embedded_runner_status_failed => 'Falhou';

  @override
  String get settings_embedded_runner_status_downloading => 'A transferir…';

  @override
  String settings_embedded_runner_running_at(String url) {
    return 'Ativo em $url';
  }

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Apps: $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps neste snapshot';

  @override
  String get settings_snapshot_create_loading => 'A criar snapshot…';

  @override
  String settings_snapshot_created_at(String date) {
    return 'Criado: $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot criado: $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'A eliminar snapshot…';

  @override
  String get settings_snapshot_deleted => 'Snapshot eliminado';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Ficheiros: $count • Tamanho: $size';
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
    return '$date • $count ficheiros • $size';
  }

  @override
  String get settings_snapshot_no_metadata =>
      'Nenhum metadado de app disponível.';

  @override
  String get settings_snapshot_preview_title => 'Pré-visualização do Snapshot';

  @override
  String get settings_snapshot_restore_loading => 'A restaurar snapshot…';

  @override
  String get settings_snapshots_delete_all => 'Eliminar todos os snapshots';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return 'Eliminar permanentemente $count snapshot(s)? Esta ação não pode ser desfeita.';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count snapshot(s) eliminado(s).';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'A eliminar todos os snapshots…';

  @override
  String get settings_snapshots_delete_all_title =>
      'Eliminar todos os snapshots';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Eliminar permanentemente \"$label\"? Esta ação não pode ser desfeita.';
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
      'Ainda não foram encontrados snapshots.';

  @override
  String get settings_snapshots_refresh => 'Atualizar snapshots';

  @override
  String get settings_snapshots_refresh_loading => 'A atualizar snapshots…';

  @override
  String get settings_snapshots_title => 'Snapshots';

  @override
  String get settings_solo_pill => 'SOLO';

  @override
  String get settings_startup_mode_cloud_desc =>
      'Recomendado no Android e iOS. Logs, estatísticas e inicialização passam pelo Bot Creator.';

  @override
  String get settings_startup_mode_desc =>
      'Escolha se seus bots iniciam nos servidores do Bot Creator ou localmente neste dispositivo.';

  @override
  String get settings_startup_mode_ios_unavailable =>
      'O modo local permanece indisponível no iOS.';

  @override
  String get settings_startup_mode_ios_warning =>
      'No iOS, o modo local não é suportado. Os bots sempre usam os servidores do Bot Creator.';

  @override
  String get settings_startup_mode_local_desc =>
      'Os bots agora iniciam localmente neste dispositivo.';

  @override
  String get settings_startup_mode_local_warning =>
      'O modo local é uma opção avançada destinada a depuração ou necessidades específicas. Para uso normal, mantenha os servidores do Bot Creator ativados.';

  @override
  String get settings_startup_mode_title => 'Bot startup mode';

  @override
  String get settings_startup_mode_use_cloud =>
      'Usar servidores do Bot Creator';

  @override
  String get settings_status_remove_confirm =>
      'Esta entrada de status será removida. Continuar?';

  @override
  String get settings_tab => 'Definições';

  @override
  String get settings_team_id_label => 'ID da equipe: ';

  @override
  String settings_team_members_label(int count) {
    return 'Membros da Equipe ($count)';
  }

  @override
  String get settings_team_name_label => 'Nome da equipe: ';

  @override
  String get settings_team_owner_label => 'Líder da Equipe';

  @override
  String get settings_team_ownership => 'Propriedade da Equipe';

  @override
  String get settings_team_pill => 'EQUIPE';

  @override
  String get settings_version_title => 'Versão';

  @override
  String get settings_view_startup_logs => 'Ver registos de arranque';

  @override
  String get startup_copy_diagnostics => 'Copiar diagnósticos';

  @override
  String get startup_diagnostics_copied =>
      'Diagnósticos copiados para a área de transferência';

  @override
  String get startup_error_title => 'Erro de Inicialização';

  @override
  String get startup_failed_message =>
      'O Bot Creator falhou ao iniciar neste dispositivo.';

  @override
  String get startup_refresh_diagnostics => 'Atualizar diagnósticos';

  @override
  String get subscription_active_annual => 'Premium — Anual';

  @override
  String get subscription_active_label => 'Plano ativo:';

  @override
  String get subscription_active_monthly => 'Premium — Mensal';

  @override
  String get subscription_annual_title => 'Anual';

  @override
  String get subscription_benefit_fast_start =>
      'Bots iniciam instantaneamente, sem pop-up';

  @override
  String get subscription_benefit_no_ads =>
      'Sem anúncios em lugar nenhum do app';

  @override
  String get subscription_benefit_support =>
      'Apoie o desenvolvimento independente';

  @override
  String get subscription_error =>
      'A compra não pôde ser concluída. Por favor, tente novamente.';

  @override
  String get subscription_error_product_unavailable =>
      'Este plano está indisponível no momento. Por favor, tente novamente mais tarde.';

  @override
  String get subscription_error_purchase_start_failed =>
      'A compra não pôde ser iniciada. Por favor, tente novamente.';

  @override
  String get subscription_error_store_unavailable =>
      'A App Store está indisponível no momento. Por favor, tente novamente em um momento.';

  @override
  String get subscription_feature_analytics_desc =>
      'Acesse taxa de erro, percentis de latência e insights de localidade.';

  @override
  String get subscription_feature_analytics_title => 'Análises avançadas';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Reinicie o bot automaticamente quando um reinício completo for necessário.';

  @override
  String get subscription_feature_auto_restart_title => 'Reinício automático';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Dimensione bots grandes distribuindo a carga entre shard workers.';

  @override
  String get subscription_feature_auto_sharding_title => 'Sharding automático';

  @override
  String get subscription_feature_coming_soon => 'Em breve';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Grave e reproduza ações de comando passo a passo para depuração.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Replay visual de depuração';

  @override
  String get subscription_feature_instant_start_desc =>
      'Inicie os bots imediatamente sem interrupção de anúncio premiado.';

  @override
  String get subscription_feature_hosted_apps_title => 'Aplicações hospedadas';

  @override
  String get subscription_feature_hosted_apps_desc =>
      'Execute contêineres Docker com hospedagem ilimitada — sem anúncios.';

  @override
  String get subscription_feature_instant_start_title => 'Início instantâneo';

  @override
  String get subscription_feature_lavalink_desc =>
      'Play music and audio in Discord voice channels using Lavalink.';

  @override
  String get subscription_feature_lavalink_title => 'Lavalink audio support';

  @override
  String get subscription_feature_no_ads_desc =>
      'Remova todas as inserções de anúncios em toda a experiência do aplicativo.';

  @override
  String get subscription_feature_no_ads_title => 'Sem anúncios';

  @override
  String get subscription_feature_scheduler_desc =>
      'Execute fluxos de trabalho automaticamente a cada X minutos (até 10 ativos).';

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
  String get subscriptions_hub_title => 'Assinaturas';

  @override
  String get subscriptions_hub_subtitle =>
      'Veja e gerencie seus planos Bot Premium e aplicações hospedadas.';

  @override
  String get subscriptions_hub_open_settings => 'Assinaturas e cobrança';

  @override
  String get subscriptions_hub_bot_premium_section => 'Bot Premium';

  @override
  String get subscriptions_hub_bot_premium_desc =>
      'Remova anúncios e desbloqueie recursos premium para seus bots Discord.';

  @override
  String get subscriptions_hub_hosted_section => 'Aplicações hospedadas';

  @override
  String get subscriptions_hub_hosted_desc =>
      'Execute contêineres Docker na nuvem sem assistir anúncios.';

  @override
  String get subscriptions_hub_status_active => 'Ativo';

  @override
  String get subscriptions_hub_status_inactive => 'Não assinado';

  @override
  String get subscriptions_hub_subscribe => 'Assinar';

  @override
  String get subscriptions_hub_summary_both =>
      'Bot Premium e aplicações hospedadas ativos';

  @override
  String get subscriptions_hub_summary_bot_only => 'Bot Premium ativo';

  @override
  String get subscriptions_hub_summary_hosted_only =>
      'Aplicações hospedadas ativas';

  @override
  String get subscriptions_hub_summary_none => 'Nenhuma assinatura ativa';

  @override
  String subscriptions_hub_expires_at(String date, String time) {
    return 'Renova até $date às $time';
  }

  @override
  String get subscriptions_hub_permanent => 'Permanente (sem expiração)';

  @override
  String get subscriptions_hub_unlimited_bots => 'Bots ilimitados';

  @override
  String get subscriptions_hub_managed_by_server => 'Gerenciado pelo servidor';

  @override
  String get plan_limit_own_bots_title =>
      'Bots próprios não incluídos no seu plano';

  @override
  String get plan_limit_own_bots_desc =>
      'O seu plano só dá acesso a bots prontos (turnkey). Mude para um plano que inclua bots próprios para iniciar este.';

  @override
  String get plan_limit_bot_quota_title =>
      'Limite de bots em execução atingido';

  @override
  String get plan_limit_bot_quota_desc =>
      'O seu plano limita quantos bots podem estar em execução ao mesmo tempo. Pare um bot ou mude para um plano superior.';

  @override
  String plan_limit_bot_quota_ad_funded_desc(int count) {
    return 'O seu plano executa $count bots em simultâneo. Este é extra: vai funcionar com tempo de hospedagem ganho ao ver anúncios, e para quando esse tempo acabar.';
  }

  @override
  String get plan_limit_quota_continue_ad => 'Iniciar financiado por anúncios';

  @override
  String get plan_limit_turnkey_title =>
      'Bots prontos não incluídos no seu plano';

  @override
  String get plan_limit_turnkey_desc =>
      'O seu plano não inclui bots prontos nem aplicações hospedadas. Escolha um plano que os inclua.';

  @override
  String get plan_limit_turnkey_quota_title =>
      'Limite de bots prontos atingido';

  @override
  String get plan_limit_turnkey_quota_desc =>
      'O seu plano limita quantos bots prontos podem estar em execução ao mesmo tempo. Pare um ou mude para um plano superior.';

  @override
  String get plan_limit_view_offers => 'Ver planos';

  @override
  String get subscription_upgrade_annual => 'Atualizar para anual';

  @override
  String get subscription_upgrade_two_apps => 'Atualizar para 2 contêineres';

  @override
  String get subscription_manage_cancel_hint =>
      'Para cancelar ou alterar a cobrança, use Gerenciar assinatura — isso abre a App Store ou Google Play.';

  @override
  String get subscription_monthly_title => 'Mensal';

  @override
  String get subscription_not_available_on_platform =>
      'As assinaturas estão disponíveis no momento apenas para dispositivos móveis.';

  @override
  String get subscription_per_month => 'por mês';

  @override
  String get subscription_per_year => 'por ano';

  @override
  String get subscription_plan_desc =>
      'Remova anúncios e tenha acesso a todos os recursos premium atuais e futuros.';

  @override
  String get subscription_plan_label => 'Premium Básico';

  @override
  String get subscription_privacy => 'Política de privacidade';

  @override
  String get subscription_restore => 'Restaurar compras';

  @override
  String get subscription_restore_not_found =>
      'Nenhuma assinatura ativa encontrada.';

  @override
  String get subscription_restored => 'Assinatura restaurada com sucesso!';

  @override
  String subscription_save_badge(int percent) {
    return 'ECONOMIZE $percent%';
  }

  @override
  String get subscription_subtitle =>
      'Escolha um plano para desbloquear todos os recursos premium.';

  @override
  String get subscription_success =>
      'Bem-vindo ao Premium! Todos os anúncios foram removidos.';

  @override
  String get subscription_terms => 'Termos de uso';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_unavailable_platform =>
      'Não disponível nesta plataforma.';

  @override
  String get support_card_desc =>
      'Uma dúvida, um bug, uma sugestão? Venha conversar com a equipa e a comunidade.';

  @override
  String get support_card_title => 'Suporte & Comunidade';

  @override
  String get support_discord_badge => 'Suporte oficial';

  @override
  String get team_tab => 'Team';

  @override
  String get team_tab_short => 'Team';

  @override
  String get team_chat_title => 'Team & chat';

  @override
  String get team_chat_empty =>
      'No messages yet. Start the conversation with your team.';

  @override
  String get team_chat_input_hint => 'Write a message...';

  @override
  String get team_permissions_title => 'Permissions';

  @override
  String get team_chat_send => 'Send';

  @override
  String get team_chat_load_error => 'The team chat could not be loaded.';

  @override
  String get team_chat_send_error =>
      'Message not sent. Check your connection and try again.';

  @override
  String get team_collaborators_title => 'Collaborators';

  @override
  String get team_collaborators_empty =>
      'No collaborator yet. Add someone by their Discord user ID.';

  @override
  String get team_add_by_discord_id => 'Add by Discord user ID';

  @override
  String get team_add_discord_id_label => 'Discord user ID';

  @override
  String get team_add_error => 'The collaborator could not be added.';

  @override
  String get team_remove => 'Remove';

  @override
  String team_remove_confirm(String name) {
    return 'Remove $name from this bot\'s team? They will immediately lose access to the bot and to its chat.';
  }

  @override
  String get team_remove_error => 'The collaborator could not be removed.';

  @override
  String get team_not_in_portal_warning =>
      'This Discord user ID is not part of your application\'s team in the Discord Developer Portal. You can still add them: this bot will simply not show up in their portal team.';

  @override
  String get team_permission_edit_commands => 'Edit commands';

  @override
  String get team_permission_start_stop => 'Start and stop the bot';

  @override
  String get team_permission_claim_ads => 'Claim ad rewards';

  @override
  String get team_permission_invite => 'Invite the bot to servers';

  @override
  String get team_permission_view_chat => 'Read and write in the team chat';

  @override
  String get team_portal_section_title =>
      'Discord Developer Portal team (read-only)';

  @override
  String get team_unavailable =>
      'The team chat needs a connection to the Bot Creator server.';

  @override
  String get team_owner_badge => 'OWNER';

  @override
  String get home_section_my_bots => 'MY BOTS';

  @override
  String get home_section_shared_with_me => 'SHARED WITH ME';

  @override
  String get support_join_discord => 'Juntar-se ao servidor de Discord';

  @override
  String get template_fun_description =>
      'Cara ou coroa, enquetes e bola 8 mágica.';

  @override
  String get template_fun_name => 'Bot de Diversão';

  @override
  String template_gallery_already_exists(String name) {
    return 'O comando \"$name\" já existe e foi ignorado.';
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
  String get template_gallery_empty => 'Nenhum modelo disponível.';

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
      'Comandos salvos localmente. Inicie seu bot para registrá-los no Discord.';

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
  String get template_moderation_name => 'Bot de Moderação';

  @override
  String get template_utility_description =>
      'Ping, busca de avatar e comandos de fala do bot.';

  @override
  String get template_utility_name => 'Bot Utilitário';

  @override
  String get template_welcome_description =>
      'Cumprimente novos membros, diga olá e mostre informações do servidor.';

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
      one: '1 mês',
      zero: '0 meses',
    );
    return '$_temp0';
  }

  @override
  String get unit_short_month => 'Meses';

  @override
  String get unit_short_day => 'Dias';

  @override
  String get unit_short_hour => 'Horas';

  @override
  String get unit_short_minute => 'Min';

  @override
  String get validation_awaited_callback_format =>
      'O retorno de chamada aguardado deve usar \$awaitedCommand[nome;filtro] ou \$awaitedCommandError[nome].';

  @override
  String validation_awaited_callback_length(int max) {
    return 'O gatilho de retorno de chamada aguardado deve ter no máximo $max caracteres';
  }

  @override
  String get validation_awaited_callback_local_only =>
      'Retornos de chamada aguardados requerem um Comando com Prefixo apenas local.';

  @override
  String get validation_command_name_invalid_chars =>
      'Nomes slash devem ter 1-32 caracteres em minúsculas. Permitidos: letras, números, hífens, sublinhados e apóstrofos.';

  @override
  String validation_command_name_length(int max) {
    return 'O nome do comando deve ter no máximo $max caracteres';
  }

  @override
  String get validation_command_name_must_be_lowercase =>
      'Nomes slash devem usar letras minúsculas quando existir variante minúscula.';

  @override
  String validation_command_payload_too_large(int current, int max) {
    return 'Este comando slash excede o limite do Discord de $max caracteres ($current usados). Encurte nomes, descrições, opções ou escolhas.';
  }

  @override
  String get validation_command_name_no_ampersand =>
      'O nome do comando não pode começar com um e comercial (&)';

  @override
  String get validation_command_name_no_at =>
      'O nome do comando não pode começar com uma arroba (@)';

  @override
  String get validation_command_name_no_exclamation =>
      'O nome do comando não pode começar com um ponto de exclamação';

  @override
  String get validation_command_name_no_hash =>
      'O nome do comando não pode começar com um cerquilha (#)';

  @override
  String get validation_command_name_no_percent =>
      'O nome do comando não pode começar com um sinal de porcentagem';

  @override
  String get validation_command_name_no_slash =>
      'O nome do comando não pode começar com uma barra';

  @override
  String get validation_command_name_no_spaces =>
      'O nome do comando não pode conter espaços';

  @override
  String get validation_command_name_no_underscore =>
      'O nome do comando não pode começar com um sublinhado';

  @override
  String get validation_command_name_required =>
      'Por favor, insira um nome para o comando';

  @override
  String get validation_interaction_no_response =>
      'Comandos de interação devem incluir pelo menos uma ação de resposta (Responder com mensagem, Componente V2 ou Modal).';

  @override
  String get validation_interaction_no_response_short =>
      'Nenhuma ação de resposta';

  @override
  String get validation_invalid_permissions =>
      'Bitfield de permissões de membro padrão inválido. Use um número inteiro positivo ou deixe vazio.';

  @override
  String get validation_legacy_chat_input_only =>
      'O modo prefixo está disponível apenas para comandos de entrada de chat.';

  @override
  String get validation_legacy_only_new_or_local =>
      'O modo apenas legado só pode ser usado para novos comandos ou comandos locais existentes.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Comandos apenas locais requerem que o modo prefixo esteja ativado.';

  @override
  String get validation_modal_not_legacy =>
      'Respostas de modal não são suportadas no modo de comando legado.';

  @override
  String get validation_option_description_required =>
      'Toda opção deve ter uma descrição.';

  @override
  String get validation_option_group_only_subcommands =>
      'Um SubCommandGroup só pode conter opções de Subcomando.';

  @override
  String get validation_option_group_top_level_only =>
      'SubCommandGroup só é permitido no nível superior.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'Subcomando e Grupo de Subcomandos não podem definir escolhas.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'Subcomando e Grupo de Subcomandos não podem definir valores mínimos/máximos.';

  @override
  String get validation_option_hierarchy_not_required =>
      'Subcomando e Grupo de Subcomandos não podem ser marcados como obrigatórios.';

  @override
  String get validation_option_leaf_no_nested =>
      'Opções regulares não podem conter opções aninhadas.';

  @override
  String get validation_option_max_entries =>
      'Cada nível de opção suporta no máximo 25 entradas.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Nome de opção duplicado \"$name\" no mesmo nível.';
  }

  @override
  String get validation_option_name_must_be_lowercase =>
      'Nomes de opção devem usar letras minúsculas quando existir variante minúscula.';

  @override
  String get validation_option_required_before_optional =>
      'Opções obrigatórias devem ser listadas antes das opcionais.';

  @override
  String get validation_option_name_required => 'Toda opção deve ter um nome.';

  @override
  String get validation_option_no_mix_top_level =>
      'Opções de nível superior não podem misturar subcomandos/grupos com opções regulares.';

  @override
  String get validation_option_subcommand_depth =>
      'A profundidade de aninhamento do subcomando excede os limites do Discord.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Um Subcomando não pode conter Subcomandos ou Grupos de Subcomandos aninhados.';

  @override
  String get variable_autocomplete_numeric_title =>
      'Sugestões numéricas dinâmicas';

  @override
  String get variable_autocomplete_title =>
      'Variáveis disponíveis — toque para inserir';

  @override
  String get variable_category_author => 'Autor';

  @override
  String get variable_category_bot => 'Bot';

  @override
  String get variable_category_channel => 'Canal';

  @override
  String get variable_category_context => 'Contexto';

  @override
  String get variable_category_functions => 'Funções';

  @override
  String get variable_category_guild => 'Servidor';

  @override
  String get variable_category_interaction => 'Interação';

  @override
  String get variable_category_member => 'Membro';

  @override
  String get variable_category_message => 'Mensagem';

  @override
  String get variable_category_other => 'Outro';

  @override
  String get variable_category_temp => 'Temporário';

  @override
  String get variable_category_user => 'Usuário';

  @override
  String get webhooks_actions => 'Ações';

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
    return 'Excluir \"$label\"? Isso não pode ser desfeito.';
  }

  @override
  String get webhooks_delete_confirm_no_label => 'Isso não pode ser desfeito.';

  @override
  String get webhooks_delete_title => 'Excluir webhook de entrada?';

  @override
  String get webhooks_edit_title => 'Editar webhook de entrada';

  @override
  String get webhooks_empty => 'Nenhum webhook de entrada ainda.';

  @override
  String get webhooks_generate => 'Gerar';

  @override
  String get webhooks_invalid_runner_url => 'A URL do Runner é inválida.';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Limite de webhooks de entrada atingido ($limit).';
  }

  @override
  String get webhooks_missing_data =>
      'O caminho ou o segredo do webhook está faltando.';

  @override
  String get webhooks_no_workflows =>
      'Crie pelo menos um fluxo de trabalho antes de adicionar um webhook de entrada.';

  @override
  String get webhooks_page_title => 'Webhooks de Entrada';

  @override
  String get webhooks_path_copied => 'Caminho copiado.';

  @override
  String get webhooks_path_exists => 'Este caminho já existe. Escolha outro.';

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
  String get wizard_advanced_trigger => 'Configurações de gatilho avançadas';

  @override
  String get wizard_apply_quick_start => 'Aplicar início rápido ao rascunho';

  @override
  String get wizard_bdfd_mode_enabled => 'Modo de script BDFD ativado';

  @override
  String get wizard_code_advanced => 'Código / Avançado';

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
      'Opções de comando legado e comportamento apenas local';

  @override
  String get wizard_quick_start_applied =>
      'Início rápido aplicado ao rascunho do comando.';

  @override
  String get wizard_quick_start_subtitle =>
      'Use o construtor simples legado como ponto de partida e aplique-o ao rascunho compartilhado.';

  @override
  String get wizard_quick_starts => 'Inícios rápidos';

  @override
  String get wizard_reply_summary => 'Resumo da resposta';

  @override
  String get wizard_save_command => 'Salvar comando';

  @override
  String get wizard_step_actions => 'Ações';

  @override
  String get wizard_step_infos => 'Informações';

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
      'Argumento do workflow (acessível via \$arg)';

  @override
  String get workflow_arguments_section => 'Argumentos do Fluxo';

  @override
  String get workflow_auto_defer => 'Auto deferir';

  @override
  String get workflow_auto_defer_actions => 'Auto deferir se houver ações';

  @override
  String get workflow_bdfd_editor_desc =>
      'Escreva o código BDFD completo para a resposta deste workflow. Os diagnósticos são exibidos ao vivo.';

  @override
  String get workflow_bdfd_editor_title => 'Editor de Script BDFD';

  @override
  String get workflow_condition_off => 'Condição desativada';

  @override
  String get workflow_condition_off_upper => 'CONDIÇÃO DESATIVADA';

  @override
  String get workflow_condition_on => 'Condição ativada';

  @override
  String get workflow_condition_on_upper => 'CONDIÇÃO ATIVADA';

  @override
  String get workflow_dart_editor_desc =>
      'Escreva código Dart completo para a resposta deste workflow. Os diagnósticos são exibidos ao vivo.';

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
      'Escreva todo o seu workflow como um único script BDFD. O script é compilado e validado em tempo real.';

  @override
  String get workflow_mode_dart => 'Dart Direto';

  @override
  String get workflow_mode_dart_note =>
      'Escreva o seu workflow em Dart. Os diagnósticos são atualizados durante a edição para detetar erros precocemente.';

  @override
  String get workflow_mode_desc =>
      'Escolha entre um construtor de ações visual ou um editor de script BDFD completo.';

  @override
  String get workflow_mode_title => 'Modo Workflow';

  @override
  String get workflow_mode_visual => 'Visual';

  @override
  String get workflow_mode_visual_note =>
      'Construa o seu workflow visualmente adicionando ações individuais com o editor de cartões.';

  @override
  String get workflow_no_auto_defer => 'Não auto deferir';

  @override
  String get workflow_no_workflow_note =>
      'Nota: Se nenhum workflow for selecionado, o envio deste modal não fará nada.';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'Ao enviar, o workflow \"$name\" será executado (entrada: $entry, args: $args).';
  }

  @override
  String get workflow_root_json_error => 'A raiz deve ser um objeto JSON';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" salvo ($count ação(ões)).';
  }

  @override
  String get workflow_set_call_args => 'Definir Argumentos de Chamada';

  @override
  String get workflow_visibility_ephemeral => 'Efêmero';

  @override
  String get workflow_visibility_public => 'Público';

  @override
  String get workflows_add_arg => 'Adicionar argumento';

  @override
  String get workflows_arg_default => 'Valor padrão';

  @override
  String get workflows_arg_hint =>
      'Argumentos tornam-se variáveis de execução como ((arg.name)) e ((workflow.arg.name)).';

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
  String get workflows_create_subtitle =>
      'Automatize ações e eventos do bot em poucos cliques';

  @override
  String get workflows_create_event => 'Criar Evento';

  @override
  String get workflows_create_event_subtitle =>
      'Reaja a mensagens, entradas de membros e eventos do Discord';

  @override
  String workflows_delete_confirm(String name) {
    return 'Tem a certeza que deseja apagar \"$name\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get workflows_delete_title => 'Apagar workflow';

  @override
  String get workflows_docs_tooltip => 'Abrir centro de documentação';

  @override
  String get workflows_edit => 'Editar Workflow';

  @override
  String get workflows_empty => 'Ainda não há workflows';

  @override
  String get workflows_entry_point => 'Ponto de Entrada Padrão';

  @override
  String get workflows_entry_point_hint =>
      'Usado se quem chama não o substituir';

  @override
  String get workflows_event_available_vars => 'Variáveis disponíveis';

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
      'Ativado sempre que um canal é atualizado.';

  @override
  String get workflows_event_hint =>
      'Escolha o evento do Discord que deve ativar este workflow.';

  @override
  String get workflows_event_invite_create => 'Convite Criado';

  @override
  String get workflows_event_invite_create_desc =>
      'Ativado sempre que um convite é criado.';

  @override
  String get workflows_event_member_join => 'Membro Entrou';

  @override
  String get workflows_event_member_join_desc =>
      'Ativado sempre que um membro entra no servidor.';

  @override
  String get workflows_event_member_remove => 'Membro Saiu';

  @override
  String get workflows_event_member_remove_desc =>
      'Ativado sempre que um membro sai ou é removido do servidor.';

  @override
  String get workflows_event_message_create => 'Mensagem Criada';

  @override
  String get workflows_event_message_create_desc =>
      'Ativado sempre que uma nova mensagem é criada.';

  @override
  String get workflows_event_message_delete => 'Mensagem Apagada';

  @override
  String get workflows_event_message_delete_desc =>
      'Ativado sempre que uma mensagem é apagada.';

  @override
  String get workflows_event_message_update => 'Mensagem Atualizada';

  @override
  String get workflows_event_message_update_desc =>
      'Ativado sempre que uma mensagem existente é editada.';

  @override
  String workflows_event_preview(String event) {
    return 'Ouvir por: $event';
  }

  @override
  String get workflows_event_section => 'Workflows de Eventos';

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count ação(ões) • Ouvir por: $event';
  }

  @override
  String get workflows_export_base64 => 'Copiar como Base64';

  @override
  String get workflows_export_base64_desc =>
      'Conveniente para partilha compacta.';

  @override
  String get workflows_export_json => 'Copiar como JSON';

  @override
  String get workflows_export_json_desc => 'Legível e fácil de editar.';

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
      'Formato inválido. Use JSON ou Base64(JSON).';

  @override
  String get workflows_import_no_valid => 'Nenhum workflow válido encontrado.';

  @override
  String get workflows_import_overwrite =>
      'Substituir quando o nome já existir';

  @override
  String get workflows_import_title => 'Importar workflows';

  @override
  String get workflows_import_tooltip => 'Importar workflows';

  @override
  String get workflows_js_event_available_context_copy_hint =>
      'Toque para copiar no seu script';

  @override
  String workflows_js_event_available_context_copied(String name) {
    return '$name copiado';
  }

  @override
  String get workflows_js_event_available_context_sparse_note =>
      'O primeiro argumento deste evento não é vinculado como message/interaction/member/channel/guild. Use client e suas variáveis/db, ou a documentação Discord.js para o payload completo.';

  @override
  String get workflows_js_event_available_context_subtitle =>
      'Estas globais são injetadas no seu script para este evento. Use propriedades discord.js (ex. message.author.username), não ((message.content)).';

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
    return '$count ação(ões) • entrada: $entry • args: $args';
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
      'Lógica reutilizável chamada por comandos, botões, modais ou outros workflows.';

  @override
  String get workflows_type_title => 'Tipo de Workflow';

  @override
  String get settings_sync_title => 'Sincronização';

  @override
  String get settings_sync_force_title => 'Forçar Sincronização de Comandos';

  @override
  String get settings_sync_force_desc =>
      'Recria no Discord os comandos ausentes e remove os que já não estão definidos no Bot Creator.';

  @override
  String get settings_sync_force_button => 'Sincronizar com o Discord';

  @override
  String get settings_sync_force_dialog_title => 'Forçar Sincronização';

  @override
  String get settings_sync_force_dialog_desc =>
      'Os comandos ausentes no Discord serão recriados e os que já não estão definidos no Bot Creator serão removidos. Continuar?';

  @override
  String get settings_sync_force_dialog_confirm => 'Forçar';

  @override
  String settings_sync_force_success_counts(
    int created,
    int relinked,
    int deleted,
  ) {
    return 'Sincronização concluída: $created recriado(s), $relinked reassociado(s), $deleted removido(s) no Discord.';
  }

  @override
  String get settings_sync_force_no_local_commands =>
      'Nenhum comando local para registrar: nada foi alterado no Discord (uma sincronização vazia apagaria todos os seus comandos).';

  @override
  String settings_sync_force_error(Object error) {
    return 'Falha ao forçar sincronização: $error';
  }

  @override
  String get settings_runtime_engine_switch_dialog_title =>
      'Alterar o motor de execução?';

  @override
  String get settings_runtime_engine_switch_dialog_desc =>
      'Esta é uma ação destrutiva.\n\n• Sua configuração é salva na nuvem antes de remover os dados locais.\n• A alteração só terá efeito após reiniciar o bot.\n• Todos os comandos, workflows e triggers agendados locais serão removidos.\n• Todos os comandos registrados no Discord também serão excluídos.\n\nVocê pode restaurar tudo pelo Histórico de Versões (restauração local automática).';

  @override
  String get settings_runtime_engine_switch_dialog_confirm => 'Alterar motor';

  @override
  String get settings_runtime_engine_switch_success =>
      'Motor de execução atualizado. Reinicie o bot quando estiver pronto.';

  @override
  String settings_runtime_engine_switch_error(String error) {
    return 'Falha ao alterar o motor de execução: $error';
  }

  @override
  String get settings_runtime_engine_switch_empty_payload =>
      'Troca cancelada: a nova configuração ficaria vazia (nenhum comando, nenhum evento, nenhum webhook, nenhuma variável). Seus comandos e workflows locais não foram alterados.';

  @override
  String get app_create_select_type_title => 'Selecionar Tipo de Aplicação';

  @override
  String get app_create_select_type_desc =>
      'Escolha o tipo de aplicação que deseja criar para começar.';

  @override
  String get app_create_type_discord => 'Bot do Discord';

  @override
  String get app_create_type_discord_desc =>
      'Crie e configure um bot do Discord personalizável com ações, eventos e camadas de canvas.';

  @override
  String get app_create_type_hosted => 'Bot Pronto para Uso';

  @override
  String get app_create_type_hosted_desc =>
      'Implante em segundos um bot pronto para uso (música, moderação, utilitários...) hospedado 24/7.';

  @override
  String get app_create_coming_soon => 'Em breve';

  @override
  String get app_create_sample_title => 'Criar comando de exemplo';

  @override
  String app_create_sample_desc(String botName) {
    return 'Gostaria de adicionar um comando /ping de exemplo ao $botName? Ele responde com \"Pong!\" e é um ótimo ponto de partida para aprender como o Bot Creator funciona.';
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
      'Um comando permite que seu bot responda quando alguém digita /algo no Discord.';

  @override
  String get commands_empty_create_button => 'Criar um comando';

  @override
  String get commands_empty_marketplace_link =>
      'Ou comece com um template do Marketplace';

  @override
  String get command_created_success_title => 'Seu comando está pronto!';

  @override
  String get command_created_success_subtitle => 'O que você quer fazer agora?';

  @override
  String get command_created_start_bot => 'Iniciar meu bot';

  @override
  String get command_created_start_bot_hint =>
      'Abra a aba Início do seu bot e toque em Iniciar para colocá-lo online.';

  @override
  String get command_created_invite => 'Convidar para um servidor';

  @override
  String get command_created_invite_error =>
      'Não foi possível abrir o link de convite.';

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
  String get container_list_title => 'Bots Prontos para Uso';

  @override
  String get container_list_session_missing => 'Sessão indisponível';

  @override
  String get container_list_session_hint =>
      'Por favor, conecte-se à sua conta primeiro.';

  @override
  String get container_list_error => 'Falha ao carregar bots';

  @override
  String get container_list_retry => 'Tentar novamente';

  @override
  String get container_list_empty => 'Nenhum bot pronto para uso';

  @override
  String get container_list_empty_hint =>
      'Implante seu primeiro bot pronto para uso em 1 clique.';

  @override
  String get container_list_deploy_btn => 'Implantar Bot Pronto para Uso';

  @override
  String get container_list_unsupported_badge => 'Não suportado';

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
  String get container_deploy_title => 'Implantar Bot Pronto para Uso';

  @override
  String get container_deploy_template_section => 'Modelo Pronto para Uso';

  @override
  String get container_deploy_managed_hosting => 'Hospedagem Gerenciada 24/7';

  @override
  String get container_deploy_bot_config_section =>
      'Configuração do Bot do Discord';

  @override
  String get container_deploy_paste_token_hint =>
      'Cole o token do bot do Discord aqui';

  @override
  String get container_deploy_env_fields_section => 'Variáveis de ambiente';

  @override
  String get container_deploy_env_server_provided => 'Fornecido pelo servidor';

  @override
  String container_deploy_env_field_required(String field) {
    return 'O campo $field é obrigatório.';
  }

  @override
  String get container_deploy_discord_prereqs => 'Pré-requisitos do Discord';

  @override
  String get container_deploy_launch_btn => 'Iniciar Bot Pronto para Uso';

  @override
  String get container_deploy_image_label => 'Imagem';

  @override
  String get container_deploy_image_hint =>
      'Imagem Docker com tag (ex.: ghcr.io/albertgmz/beatdock:latest)';

  @override
  String get container_deploy_template_label => 'Modelo';

  @override
  String get container_deploy_template_easy_music => 'Bot de música fácil';

  @override
  String get container_deploy_template_custom => 'Imagem personalizada';

  @override
  String get container_deploy_easy_music_hint =>
      'Apenas o token do seu bot Discord é necessário. Usa servidores Lavalink públicos — sem login no registry, chaves de API ou configuração extra.';

  @override
  String get container_deploy_pick_bot => 'Usar um bot existente';

  @override
  String get container_deploy_pick_bot_manual => 'Inserir token manualmente';

  @override
  String get container_deploy_bot_token_hint =>
      'Crie um bot no Portal de Desenvolvedores do Discord, ative a intenção Message Content e convide-o para o seu servidor.';

  @override
  String get container_deploy_bot_token_required =>
      'O token do bot Discord é obrigatório';

  @override
  String get container_deploy_image_required => 'Imagem é obrigatória';

  @override
  String get container_deploy_cpu_label => 'CPU (millis)';

  @override
  String get container_deploy_cpu_min => 'Mín 128';

  @override
  String get container_deploy_memory_label => 'Memória (MB)';

  @override
  String get container_deploy_memory_min => 'Mín 128 MB';

  @override
  String get container_deploy_storage_label => 'Armazenamento (GB)';

  @override
  String get container_deploy_storage_min => 'Mín 1 GB';

  @override
  String get container_deploy_ttl_label => 'TTL (minutos)';

  @override
  String get container_deploy_ttl_min => 'Mín 1 minuto';

  @override
  String get container_deploy_env_label => 'Variáveis de Ambiente';

  @override
  String get container_deploy_env_key_hint => 'CHAVE';

  @override
  String get container_deploy_env_value_hint => 'valor';

  @override
  String get container_deploy_submit => 'Implantar';

  @override
  String get container_deploy_submitting => 'Implantando...';

  @override
  String get container_deploy_not_auth => 'Não autenticado';

  @override
  String container_deploy_success(String containerId) {
    return 'Implantando $containerId...';
  }

  @override
  String get container_deploy_submitted_starting =>
      'Hosted app submitted — starting up now...';

  @override
  String container_deploy_failed(String error) {
    return 'Falha na implantação: $error';
  }

  @override
  String container_deploy_token_invalid(String error) {
    return 'Token do bot do Discord inválido: $error';
  }

  @override
  String get container_deploy_blocked_container_limit =>
      'You\'ve reached your hosted app limit. Delete or stop an existing hosted app to free up a slot before deploying another.';

  @override
  String get container_deploy_blocked_no_minutes =>
      'You\'re out of free hosting minutes. Watch a rewarded ad to unlock more minutes, or go Premium for unlimited hosting.';

  @override
  String get container_deploy_blocked_cloud_disabled =>
      'O alojamento na cloud não está ativado neste servidor: a implementação remota não está disponível. Executa o bot localmente ou através do teu próprio runner.';

  @override
  String get container_deploy_blocked_eligibility_error =>
      'Couldn\'t check whether you can deploy right now.';

  @override
  String container_deploy_ad_slot_full(int granted) {
    return '+$granted hosting minutes earned, but your container slot is still full. Delete or stop an existing hosted app to deploy a new one.';
  }

  @override
  String get container_detail_state => 'Estado';

  @override
  String get container_detail_expires => 'Expira em';

  @override
  String get container_detail_extend_ttl => 'Estender TTL';

  @override
  String get container_detail_stop_title => 'Parar Contêiner';

  @override
  String get container_detail_stop_confirm =>
      'Isso encerrará o contêiner e seus dados serão perdidos.';

  @override
  String get container_detail_stop_btn => 'Parar';

  @override
  String get container_detail_stopped_ok => 'Contêiner parado';

  @override
  String get container_detail_start_btn => 'Iniciar';

  @override
  String get container_detail_starting => 'Iniciando...';

  @override
  String get container_detail_started_ok => 'Contêiner está iniciando';

  @override
  String get container_detail_open => 'Detalhes';

  @override
  String get container_detail_delete_title => 'Excluir contêiner';

  @override
  String get container_detail_delete_confirm =>
      'Isso exclui permanentemente o contêiner do banco de dados e da nuvem. Não pode ser desfeito.';

  @override
  String get container_detail_delete_btn => 'Excluir';

  @override
  String get container_detail_deleted_ok => 'Contêiner excluído';

  @override
  String get container_detail_stopped_hint =>
      'Este contêiner está desligado. Você pode reiniciá-lo sem inserir as variáveis de ambiente novamente.';

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
  String container_logs_errors_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erros',
      one: '1 erro',
      zero: 'Sem erros',
    );
    return '$_temp0';
  }

  @override
  String get container_detail_deploying => 'Contêiner está sendo implantado...';

  @override
  String container_detail_status_stopped(String state) {
    return 'Este contêiner está $state.';
  }

  @override
  String get container_detail_not_connected => 'Não conectado';

  @override
  String get container_detail_console_connecting => 'Conectando...';

  @override
  String get container_detail_console_closed => '--- Conexão fechada ---';

  @override
  String get container_detail_console_hint => 'Digite um comando...';

  @override
  String container_detail_failed(String error) {
    return 'Falha: $error';
  }

  @override
  String get container_state_running => 'Em execução';

  @override
  String get container_state_pending => 'Pendente';

  @override
  String get container_state_provisioning => 'Provisioning';

  @override
  String get container_state_stopped => 'Parado';

  @override
  String get container_state_stopping => 'Parando';

  @override
  String get container_state_failed => 'Falhou';

  @override
  String get container_health_image_pull_failed =>
      'Couldn\'t pull the container image. Check that the image name and tag are correct and that any required registry credentials are set.';

  @override
  String get container_health_crash_loop =>
      'The container keeps crashing shortly after starting. Check your environment variables and logs.';

  @override
  String get container_health_starting => 'Still starting up...';

  @override
  String get container_hosted_subtitle =>
      'Implante bots prontos para uso (música, etc.) em 1 clique';

  @override
  String get container_premium_badge => 'Premium';

  @override
  String container_detail_title(String id) {
    return 'Bot $id';
  }

  @override
  String get container_list_premium_host_anytime_tooltip =>
      'Premium — hospede a qualquer momento';

  @override
  String get container_list_premium_host_anytime_fab =>
      'Hospedar a qualquer momento';

  @override
  String get container_list_free_limit_reached =>
      'Limite gratuito atingido (1 bot). Assine para hospedar mais.';

  @override
  String get container_hosted_premium_host_anytime =>
      'Hospede a qualquer momento';

  @override
  String get container_hosted_premium_host_anytime_compact =>
      'Assinar — hospede a qualquer momento';

  @override
  String get container_hosted_premium_desc =>
      'Assine para hospedar bots prontos para uso 24/7 — sem anúncios.';

  @override
  String get container_hosted_premium_view_btn => 'Ver planos';

  @override
  String get hosted_app_subscription_title => 'Bots Prontos para Uso';

  @override
  String get hosted_app_subscription_subtitle =>
      'Hospede bots prontos para uso na nuvem 24/7 sem interrupções.';

  @override
  String get hosted_app_subscription_benefit_unlimited =>
      'Tempo de hospedagem ilimitado';

  @override
  String get hosted_app_subscription_benefit_no_ads =>
      'Sem anúncios recompensados';

  @override
  String get hosted_app_subscription_one_app_title => '1 bot hospedado';

  @override
  String get hosted_app_subscription_one_app_desc =>
      'Hospede um bot pronto para uso a qualquer momento';

  @override
  String get hosted_app_subscription_two_app_title => '2 bots hospedados';

  @override
  String get hosted_app_subscription_two_app_desc =>
      'Hospede até dois bots prontos para uso';

  @override
  String get hosted_app_subscription_recommended => 'Melhor valor';

  @override
  String get container_hosted_free_title =>
      'Hospedagem gratuita (máx. 1 contêiner)';

  @override
  String container_hosted_expires_at(String dateTime) {
    return 'Expira em $dateTime';
  }

  @override
  String container_hosted_topup_ad_hint(int reward) {
    return 'Assista a um anúncio para adicionar $reward min a este contêiner (acumulável).';
  }

  @override
  String container_hosted_at_limit_open_detail(int active, int max) {
    return 'Contêiner ativo ($active/$max). Abra-o para estender com um anúncio.';
  }

  @override
  String container_hosted_minutes_available(int minutes) {
    return '$minutes minutos de hospedagem disponíveis (acumuláveis).';
  }

  @override
  String get container_hosted_resume_with_time =>
      'Você ainda tem tempo de hospedagem neste contêiner. Toque em Iniciar para retomar.';

  @override
  String container_hosted_watch_ad_earn(int reward) {
    return 'Assista a um anúncio para ganhar $reward minutos de hospedagem.';
  }

  @override
  String container_hosted_ad_button(int reward) {
    return 'Anúncio +$reward min';
  }

  @override
  String container_hosted_balance_after_ad(int minutes) {
    return 'Saldo após último anúncio: $minutes min';
  }

  @override
  String container_deploy_ad_unlock_success(int granted, int balance) {
    return '+$granted minutos de hospedagem (total: $balance min).';
  }

  @override
  String container_deploy_ad_unlock_failed(String error) {
    return 'Falha ao desbloquear: $error';
  }

  @override
  String get container_deploy_requires_premium_or_ad =>
      'Assinatura Premium ou anúncio recompensado necessário para implantar um contêiner.';

  @override
  String get container_deploy_premium_account => 'Conta Premium';

  @override
  String container_deploy_premium_containers(int max, int active) {
    return 'Até $max contêineres ativos ($active/$max).';
  }

  @override
  String get container_deploy_ephemeral_storage =>
      'Armazenamento efêmero (sem volume persistente)';

  @override
  String get container_deploy_private_image => 'Imagem privada';

  @override
  String get container_deploy_private_image_hint =>
      'Forneça credenciais do registry para baixar imagens privadas (ex.: GHCR).';

  @override
  String get container_deploy_use_custom_credentials =>
      'Usar credenciais personalizadas';

  @override
  String get container_deploy_registry_profile => 'Perfil de registry salvo';

  @override
  String get container_deploy_registry_profile_none => 'Selecionar um perfil';

  @override
  String container_deploy_registry_detected(String host) {
    return 'Registry: $host';
  }

  @override
  String get container_deploy_save_registry_auth =>
      'Salvar credenciais para reutilização';

  @override
  String get container_deploy_registry_auth_required =>
      'Nome de usuário e senha são obrigatórios para imagens privadas.';

  @override
  String get container_deploy_registry_profile_required =>
      'Selecione um perfil de registry salvo ou use credenciais personalizadas.';

  @override
  String get registry_credentials_title => 'Credenciais do registry';

  @override
  String get registry_credentials_add => 'Adicionar credenciais';

  @override
  String get registry_credentials_edit => 'Editar credenciais';

  @override
  String get registry_credentials_manage => 'Gerenciar credenciais do registry';

  @override
  String get registry_credentials_empty =>
      'Nenhuma credencial de registry salva ainda.';

  @override
  String get registry_credentials_label => 'Rótulo';

  @override
  String get registry_credentials_label_required => 'O rótulo é obrigatório';

  @override
  String get registry_credentials_host => 'Host do registry';

  @override
  String get registry_credentials_host_required =>
      'O host do registry é obrigatório';

  @override
  String get registry_credentials_username => 'Nome de usuário';

  @override
  String get registry_credentials_username_required =>
      'O nome de usuário é obrigatório';

  @override
  String get registry_credentials_password => 'Senha ou token';

  @override
  String get registry_credentials_password_required =>
      'Senha ou token é obrigatório';

  @override
  String get registry_credentials_password_hint =>
      'Token de acesso pessoal ou senha do registry';

  @override
  String get registry_credentials_password_edit_hint =>
      'Deixe em branco para manter a senha atual';

  @override
  String get registry_credentials_ghcr_hint =>
      'Para GHCR, use um PAT do GitHub com escopo read:packages.';

  @override
  String get registry_credentials_delete_title => 'Excluir credenciais?';

  @override
  String registry_credentials_delete_body(String label) {
    return 'Excluir \"$label\"? Isso não pode ser desfeito.';
  }

  @override
  String get registry_credentials_deleted =>
      'Credenciais do registry excluídas';

  @override
  String registry_credentials_delete_failed(String error) {
    return 'Falha ao excluir credenciais: $error';
  }

  @override
  String registry_credentials_save_failed(String error) {
    return 'Falha ao salvar credenciais: $error';
  }

  @override
  String container_detail_private_registry(String host, String username) {
    return 'Registry privado: $host · $username';
  }

  @override
  String container_detail_topup_applied(int minutes) {
    return '+$minutes min adicionados a este contêiner.';
  }

  @override
  String container_detail_topup_credited(int minutes) {
    return '+$minutes min creditados.';
  }

  @override
  String container_detail_apply_stored_minutes(int minutes) {
    return 'Aplicar $minutes min armazenados';
  }

  @override
  String container_detail_minutes_applied(int minutes) {
    return '$minutes min aplicados.';
  }

  @override
  String get docs_hub_title => 'Documentacao';

  @override
  String get docs_tab_guide => 'Guia';

  @override
  String get docs_tab_bot_creator => 'Docs Bot Creator';

  @override
  String get docs_tab_discordjs => 'discord.js';

  @override
  String get docs_webview_error => 'Nao foi possivel carregar a documentacao';

  @override
  String get docs_webview_unavailable =>
      'In-app documentation preview is not available on this device. Open the docs in your browser instead.';

  @override
  String get docs_open_in_browser => 'Abrir no navegador';

  @override
  String get docs_reload => 'Recarregar';

  @override
  String get common_duplicate => 'Duplicar';

  @override
  String get commands_batch_select => 'Seleção em lote';

  @override
  String commands_selected_count(int count) {
    return '$count selecionado(s)';
  }

  @override
  String get image_editor_title => 'Editor de Imagem';

  @override
  String get image_editor_add_operation => 'Adicionar operação';

  @override
  String get image_editor_add_layer => 'Adicionar camada';

  @override
  String get image_editor_operations => 'Operações';

  @override
  String get image_editor_op_container => 'Contêiner / Moldura';

  @override
  String get image_editor_op_progress_bar => 'Barra de progresso';

  @override
  String get image_editor_op_composite_image => 'Imagem composta';

  @override
  String get image_editor_op_set_pixel => 'Definir pixel';

  @override
  String get image_editor_op_invert => 'Inverter cores';

  @override
  String get image_editor_op_grayscale => 'Converter para escala de cinza';

  @override
  String get image_editor_op_rotate => 'Girar tela';

  @override
  String get image_editor_zoom_in => 'Ampliar zoom';

  @override
  String get image_editor_zoom_out => 'Reduzir zoom';

  @override
  String get image_editor_zoom_fit => 'Ajustar à tela';

  @override
  String get image_editor_undo => 'Desfazer';

  @override
  String get image_editor_redo => 'Refazer';

  @override
  String get image_editor_canvas => 'Tela';

  @override
  String get image_editor_width => 'Largura';

  @override
  String get image_editor_height => 'Altura';

  @override
  String get image_editor_properties => 'Propriedades';

  @override
  String get image_editor_visible => 'Visível';

  @override
  String get image_editor_opacity => 'Opacidade';

  @override
  String image_editor_ops_summary(int count, int hidden) {
    return '$count operações, $hidden oculta(s)';
  }

  @override
  String image_editor_empty_hint(String op) {
    return 'Adicione uma operação \"$op\" para começar';
  }

  @override
  String get image_editor_tap_to_edit => 'Toque para editar';

  @override
  String get image_editor_no_operations => 'Nenhuma operação ainda';

  @override
  String get image_editor_select_operation =>
      'Selecione uma operação para editar suas propriedades';

  @override
  String get image_editor_insert_variable => 'Inserir variável';

  @override
  String get image_editor_variable_label => 'Variável';

  @override
  String get image_editor_variable_hint =>
      'Digite para filtrar ou toque numa sugestão abaixo';

  @override
  String get image_editor_insert => 'Inserir';

  @override
  String get image_editor_pick_image => 'Escolher ficheiro de imagem';

  @override
  String get image_editor_color_picker => 'Seletor de cores';

  @override
  String get image_editor_hue => 'Matiz';

  @override
  String get image_editor_saturation => 'Saturação';

  @override
  String get image_editor_no_url => 'sem URL';

  @override
  String get image_editor_unknown => 'Desconhecido';

  @override
  String get image_editor_field_text => 'Texto';

  @override
  String get image_editor_field_font_size => 'Tamanho da fonte';

  @override
  String get image_editor_field_max_width => 'Largura máxima';

  @override
  String get image_editor_field_text_align => 'Alinhamento do texto';

  @override
  String get image_editor_field_blend => 'Mesclagem';

  @override
  String get image_editor_field_fill => 'Preencher';

  @override
  String get image_editor_field_radius => 'Raio';

  @override
  String get image_editor_field_thickness => 'Espessura';

  @override
  String get image_editor_field_shape => 'Forma';

  @override
  String get image_editor_field_percentage => 'Percentagem';

  @override
  String get image_editor_field_bar_color => 'Cor da barra';

  @override
  String get image_editor_field_track_color => 'Cor da faixa';

  @override
  String get image_editor_field_text_color => 'Cor do texto';

  @override
  String get image_editor_field_border_width => 'Largura da borda';

  @override
  String get image_editor_field_border_radius => 'Raio da borda';

  @override
  String get image_editor_field_orientation => 'Orientação';

  @override
  String get image_editor_field_angle => 'Ângulo (graus)';

  @override
  String get image_editor_field_container => 'Contêiner';

  @override
  String get image_editor_field_background_color => 'Cor de fundo';

  @override
  String get image_editor_hint_auto_size => 'auto (tamanho original)';

  @override
  String get image_editor_hint_optional_background => 'fundo opcional';

  @override
  String get image_editor_hint_parent_container => 'nome do contêiner pai';

  @override
  String get image_editor_hint_container_width =>
      'largura do contêiner para alinhamento';

  @override
  String get action_card_duration => 'Duração';

  @override
  String get action_card_error_message => 'Mensagem de erro';

  @override
  String get action_card_jump_to => 'Ir para';

  @override
  String get action_card_maximum => 'Máximo';

  @override
  String get action_card_minimum => 'Mínimo';

  @override
  String get action_card_skip_count => 'Quantidade a pular';

  @override
  String get action_edit_request => 'Editar requisição';

  @override
  String get action_error_jump => 'Saltar para ação';

  @override
  String get action_error_skip => 'Pular N ações';

  @override
  String get component_max_length => 'Comprimento máximo';

  @override
  String get component_min_length => 'Comprimento mínimo';

  @override
  String get http_request_header_name => 'Nome do cabeçalho';

  @override
  String get http_request_json_body => 'Corpo JSON';

  @override
  String get http_request_section_body => 'Corpo';

  @override
  String get http_request_section_headers => 'Cabeçalhos';

  @override
  String get http_request_section_request => 'Requisição';

  @override
  String get http_request_text_body => 'Corpo de texto';

  @override
  String marketplace_summary_commands(int count) {
    return '$count comandos';
  }

  @override
  String marketplace_summary_variables(int count, int required) {
    return '$count variáveis ($required obrigatórias)';
  }

  @override
  String marketplace_summary_workflows(int count) {
    return '$count workflows';
  }

  @override
  String get modal_builder_configure_submit_actions =>
      'Configurar Ações de Envio';

  @override
  String get modal_builder_edit_submit_actions => 'Editar Ações de Envio';

  @override
  String get modal_builder_identity => 'Identidade';

  @override
  String get modal_builder_submit_actions => 'Ações de Envio';

  @override
  String get announcement_see_more => 'Saber mais';

  @override
  String get announcement_dismiss => 'Fechar';

  @override
  String get announcement_acknowledge => 'Entendi';

  @override
  String get announcement_later => 'Mais tarde';

  @override
  String get announcement_link_open_failed => 'Não foi possível abrir o link.';

  @override
  String get container_invite_btn => 'Convidar o bot';

  @override
  String get container_invite_busy => 'A convidar...';

  @override
  String get container_invite_unavailable =>
      'Não foi possível identificar o bot desta aplicação: o token está ausente ou foi revogado. Refazer o deploy.';

  @override
  String get container_invite_failed =>
      'Não foi possível convidar: verifique a sua ligação e tente novamente.';

  @override
  String get container_invite_open_failed =>
      'Não foi possível abrir o link de convite.';

  @override
  String get bot_payload_refused_local_kept =>
      'Envio recusado: a configuração a enviar estava vazia (nenhum comando, nenhum evento, nenhum webhook, nenhuma variável). Nada foi enviado e a sua configuração local ficou intacta — pode continuar a editar.';

  @override
  String get bot_config_overshrink_title =>
      'Tem a certeza de que quer enviar esta configuração reduzida?';

  @override
  String get bot_config_overshrink_body =>
      'Removeu a maior parte da configuração deste bot. Ainda nada foi enviado: o servidor continua a executar a versão anterior e a sua configuração local está intacta.';

  @override
  String get bot_config_overshrink_send_anyway => 'Enviar mesmo assim';

  @override
  String get bot_config_overshrink_keep_local => 'Manter local, sem enviar';

  @override
  String get command_history_title => 'Histórico de versões deste comando';

  @override
  String get command_history_empty =>
      'Ainda não há nenhuma versão registada para este comando. As versões aparecem aqui depois de guardar.';

  @override
  String get command_history_restore => 'Restaurar';

  @override
  String command_history_version_meta(Object author, Object date, num size) {
    String _temp0 = intl.Intl.pluralLogic(
      size,
      locale: localeName,
      other: '$size bytes',
      one: '1 byte',
    );
    return '$author · $date · $_temp0';
  }

  @override
  String get command_history_conflict =>
      'Esta versão não foi restaurada: o comando mudou no servidor desde que o carregou. Nada foi escrito em lado nenhum — recarregue a versão do servidor para sobrescrever de facto.';

  @override
  String get command_history_conflict_reload =>
      'Recarregar a versão do servidor e sobrescrever';

  @override
  String get command_history_unavailable_no_v2 =>
      'O histórico não está disponível para este bot: o servidor ainda não oferece a API granular /api/v2, por isso não é possível listar nem restaurar versões. Isto não é um histórico vazio.';

  @override
  String get command_history_unavailable_offline =>
      'Não foi possível obter a lista de versões (offline ou servidor inacessível). As versões nunca são armazenadas neste dispositivo, por isso a lista tem de ser obtida do servidor.';

  @override
  String get command_history_restore_confirm =>
      'Restaurar esta versão? O conteúdo que está atualmente no servidor será substituído pelo desta versão. A restauração é registada como uma nova versão, por isso continua a ser reversível.';

  @override
  String get menu_file => 'Arquivo';

  @override
  String get menu_new_bot => 'Novo bot';

  @override
  String get menu_close_window => 'Fechar janela';

  @override
  String get menu_edit => 'Editar';

  @override
  String get menu_undo => 'Desfazer';

  @override
  String get menu_redo => 'Refazer';

  @override
  String get menu_cut => 'Recortar';

  @override
  String get menu_copy => 'Copiar';

  @override
  String get menu_paste => 'Colar';

  @override
  String get menu_select_all => 'Selecionar tudo';

  @override
  String get menu_view => 'Exibir';

  @override
  String get menu_theme => 'Tema';

  @override
  String get menu_window => 'Janela';

  @override
  String get menu_help => 'Ajuda';

  @override
  String get menu_preferences => 'Preferências…';

  @override
  String get menu_website => 'Site';

  @override
  String bot_config_versions_restore_error_detail(String reason) {
    return 'Falha ao restaurar a versão: $reason';
  }

  @override
  String get bot_config_versions_restore_refused =>
      'O servidor não confirmou a restauração. Nada foi restaurado.';

  @override
  String bot_config_versions_restore_local_failed(String reason) {
    return 'A versão foi restaurada no servidor, mas a aplicação local falhou: $reason';
  }

  @override
  String get import_engine_title => 'Motor de execução';

  @override
  String get import_engine_missing =>
      'Este ZIP não declara um motor. Escolha o motor que este bot deve usar:';

  @override
  String import_engine_declared(String engine) {
    return 'Motor declarado pelo ZIP: $engine';
  }

  @override
  String import_engine_will_switch(String from, String to) {
    return 'O bot passará de $from para $to na próxima reinicialização.';
  }

  @override
  String get import_engine_dart_label => 'Bot Creator (Dart / blocos)';

  @override
  String get import_engine_javascript_label => 'JavaScript (runner-js)';

  @override
  String get bot_config_versions_restore_too_small =>
      'Versão recusada pelo servidor: pequena demais para reconstituir uma configuração — restaurá-la esvaziaria o bot. Escolha uma versão mais completa.';

  @override
  String get bot_config_versions_force_restore_title =>
      'Restaurar esta versão apesar do tamanho?';

  @override
  String get bot_config_versions_force_restore_body =>
      'O servidor a considera pequena demais para reconstituir uma configuração e recusa aplicá-la sozinho. Uma restauração é um retrocesso pedido: você pode forçá-la.';

  @override
  String get bot_config_versions_force_restore_confirm =>
      'Restaurar mesmo assim';

  @override
  String get bot_config_versions_force_restore_keep => 'Manter a versão atual';

  @override
  String get bot_config_versions_restore_too_small_unforced =>
      'O servidor ainda recusa: o manager precisa aceitar uma restauração forçada para esta versão.';
}
