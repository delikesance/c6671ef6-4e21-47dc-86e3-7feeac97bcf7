import '../../../types/action.dart';
import 'action_environment.dart';
import 'component_actions.dart' show componentsInteractionsAction;

/// Interaction listeners on the native engine: listenForButtonClick,
/// listenForSelectMenu, listenForModalSubmit and listenAndExecute.
///
/// A listener is not an in-script wait: it is a deferred trigger. The hidden
/// `bc_listen*` functions only register a `ListenerEntry` in the in-memory
/// `InteractionListenerRegistry` (TTL clamped to 1..60 minutes, one-shot for
/// modals, bound to the optional message id, initial context forwarded) and,
/// when the current interaction already carries the listened `customId`, start
/// the handler workflow / inline actions right away. The handler workflows run
/// later, in a new execution, when `handleComponentInteraction` finds the
/// entry. Registry, matching rules and results (`listening:<customId>`) are the
/// ones of the historical blocks; nothing like `$awaitComponent` exists.
bool supportsListenerAction(Action action) =>
    listenerLeafPredicates.containsKey(action.type);

const listenerLeafPredicates = <BotCreatorActionType, bool Function(Action)>{
  BotCreatorActionType.listenForButtonClick: supportsListenerAction,
  BotCreatorActionType.listenForSelectMenu: supportsListenerAction,
  BotCreatorActionType.listenForModalSubmit: supportsListenerAction,
  BotCreatorActionType.listenAndExecute: supportsListenerAction,
};

const listenerActionHandlers = <BotCreatorActionType, ActionHandler>{
  BotCreatorActionType.listenForButtonClick: componentsInteractionsAction,
  BotCreatorActionType.listenForSelectMenu: componentsInteractionsAction,
  BotCreatorActionType.listenForModalSubmit: componentsInteractionsAction,
  BotCreatorActionType.listenAndExecute: componentsInteractionsAction,
};
