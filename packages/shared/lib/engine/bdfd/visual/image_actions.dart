import '../../../services/canvas_image_renderer.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Image blocks on the native engine: `runtimeImageBlock`, `attachImage` and
/// the six visual-only `canvas*Block` types.
///
/// Parity strategy: `bc_runtimeImageBlock` / `bc_attachImage` run the very same
/// renderer the historical loop uses (`executeRuntimeImageBlock`,
/// `executeAttachImage`, the code behind BDFD's `$canvas*` / `$attachImage`
/// too), fed with the same resolved values, the native result list
/// ([ActionCall.sink]) and the shared variables map. Result keys
/// (`results[key]` / `variables[key]` = base64 PNG, `results[key]` =
/// `attached`), the `temp._canvasAttachment_<name>` attachment consumed by the
/// message senders, the image source resolution (URL, data URL, raw base64)
/// and the error text are therefore identical by construction. The rendering
/// is not deferred by the block: it completes before the action returns, as
/// today. The six `canvas*Block` types are never executable on their own and
/// fail with the historical error.

const imageActionTypes = <BotCreatorActionType>{
  BotCreatorActionType.runtimeImageBlock,
  BotCreatorActionType.attachImage,
  ...canvasSubBlockTypes,
};

const canvasSubBlockTypes = <BotCreatorActionType>{
  BotCreatorActionType.canvasCreateBlock,
  BotCreatorActionType.canvasLoadImageBlock,
  BotCreatorActionType.canvasDrawTextBlock,
  BotCreatorActionType.canvasDrawCircleBlock,
  BotCreatorActionType.canvasDrawRectBlock,
  BotCreatorActionType.canvasDrawLineBlock,
};

/// Every payload of these types is covered natively.
bool supportsImageAction(Action action) =>
    imageActionTypes.contains(action.type);

/// Routing predicates of the types of this family (read by `ActionTranslator`).
final imageLeafPredicates = <BotCreatorActionType, bool Function(Action)>{
  for (final type in imageActionTypes) type: supportsImageAction,
};

/// Handlers of the types of this family (read by the `bc_*` registry).
final imageActionHandlers = <BotCreatorActionType, ActionHandler>{
  BotCreatorActionType.runtimeImageBlock: runtimeImageBlockAction,
  BotCreatorActionType.attachImage: attachImageAction,
  for (final type in canvasSubBlockTypes) type: canvasSubBlockAction,
};

Future<String?> runtimeImageBlockAction(ActionCall call) async {
  await executeRuntimeImageBlock(
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: call.env.variables,
    resolveValue: call.resolve,
  );
  return null; // Results were written through the sink.
}

Future<String?> attachImageAction(ActionCall call) async {
  await executeAttachImage(
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: call.env.variables,
    resolveValue: call.resolve,
  );
  return null;
}

Future<String?> canvasSubBlockAction(ActionCall call) async {
  // Same message as the historical executor (variables_executor.dart).
  throw StateError(
    'Canvas block type ${call.type.name} must be nested inside an '
    'Image Manipulation Block (runtimeImageBlock) and cannot be '
    'executed standalone.',
  );
}
