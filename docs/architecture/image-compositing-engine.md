# Image Compositing Engine — Architecture Design

> **Status:** Reviewed — open questions resolved, decisions documented  
> **Date:** 2026-06-04  
> **Scope:** Image Editor feature within Bot Creator Flutter monorepo  
> **Author:** engineer (kanban task t_47660f0b)

---

## 1. Overview

The Image Compositing Engine allows Bot Creator users to generate composite images at runtime by stacking visual operations (create canvas, load images, draw shapes, add text, apply masks). Images are produced server-side in the Discord bot runner and delivered as message attachments — there is no in-app visual preview canvas today.

The engine is split across two packages:

| Layer | Package | Role |
|---|---|---|
| **Runtime Executor** | `packages/shared` (Dart-only) | Executes image operations, encodes PNG, returns base64 |
| **Visual Builder** | `packages/app` (Flutter) | Lets users author canvas operations via the action editor UI |

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  packages/app — Flutter Editor                                  │
│                                                                 │
│  Command Editor Page                                            │
│  ├─ ActionsBuilderPage                                          │
│  │   └─ ActionCard × N  ← each canvas sub-action is one card    │
│  │       └─ ParameterDefinition → typed fields (number, url...) │
│  │                                                                   │
│  State: CommandEditorNotifier (ChangeNotifier)                        │
│  Models: ActionItem { type, parameters: Map, runtimeId }             │
│  Serialization: action_normalization.dart                             │
│       canvasCreateBlock ──┐                                           │
│       canvasLoadImageBlock─┤ _canvasBlockToOp mapping → runtimeImageBlock
│       canvasDrawTextBlock──┤                                          │
│       canvasDrawCircleBlock┤                                          │
│       canvasDrawRectBlock─┘                                           │
└───────────────────────┬─────────────────────────────────────────┘
                        │ JSON (Bot Creator Action format)
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│  packages/shared — Runtime (Dart, no Flutter)                   │
│                                                                 │
│  handler.dart                                                   │
│  └─ variables_executor.dart                                     │
│       └─ executeRuntimeImageBlock()                             │
│           └─ image_executor.dart                                │
│               ├─ op: create      → _opCreate()                  │
│               ├─ op: loadImage   → _opLoadImage()    [network]  │
│               ├─ op: compositeImage → _opCompositeImage()       │
│               ├─ op: drawText    → _opDrawText()                │
│               ├─ op: drawCircle  → _opDrawCircle()              │
│               └─ op: drawRect    → _opDrawRect()                │
│                                                                 │
│  Dependencies: image: ^4.5.0 (resolved 4.8.0)                  │
│                http: ^1.6.0  (for loadImage URLs)               │
│                                                                 │
│  Output: base64 PNG + data URL in variables/runtime_results      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. State Management

### 3.1 Current Approach (Provider + ChangeNotifier + local callbacks)

The Bot Creator app uses a **layered** approach, not a single global store:

| Scope | Mechanism | What it manages |
|---|---|---|
| **App-wide** | `Provider<T>` (ThemeProvider, LocaleProvider, OnboardingManager) | Cross-cutting concerns injected at root |
| **Editor page** | `CommandEditorNotifier` (ChangeNotifier) | Command-level state: name, description, action list, variables |
| **Action editing** | Callbacks (`onParameterChanged`, `onSuggestionSelected`) | Individual action parameters — changes bubble up through widget tree |

**Why this works for the image editor:**
- Canvas blocks are individual `ActionItem` entries in a mutable `List<ActionItem>` owned by the editor notifier
- Each block's parameters are `Map<String, dynamic>` — simple, serializable, no custom model classes needed
- Adding a new canvas operation = adding an entry to `parameterDefinitions` in `action_type_extension.dart` + `_canvasBlockToOp` in `action_normalization.dart`

**Decision: No migration to Riverpod/Bloc needed.** The existing Provider + ChangeNotifier pattern is sufficient. Introducing a second state management library would create inconsistency without proportionate benefit.

### 3.2 What would change with an in-app preview canvas

If/when a visual preview is added, the canvas state would become a separate model:

```dart
class CanvasPreviewState {
  final int width;
  final int height;
  final ColorRgba8 backgroundColor;
  final List<CanvasOperation> operations; // ordered list
  final Uint8List? renderedBytes;         // null while dirty
}
```

This would be owned by a dedicated `ChangeNotifier` (e.g., `CanvasPreviewNotifier`) scoped below the command editor, not at the app root.

---

## 4. Data Models

### 4.1 Action Models (existing)

```
BotCreatorActionType  (enum, in shared)
├── runtimeImageBlock          ← runtime: collapsed block with all ops
├── canvasCreateBlock          ← visual-only sub-action
├── canvasLoadImageBlock       ← visual-only sub-action
├── canvasDrawTextBlock        ← visual-only sub-action
├── canvasDrawCircleBlock      ← visual-only sub-action
└── canvasDrawRectBlock        ← visual-only sub-action

Action (shared, runtime)       ActionItem (app, editor)
├── type: BotCreatorActionType     ├── type: BotCreatorActionType
├── key: String?                   ├── id: String
├── payload: Map<String, dynamic>  ├── runtimeId: String
└── enabled: bool                  ├── actionKey: String
                                   ├── parameters: Map<String, dynamic>
                                   └── enabled: bool
```

### 4.2 Canvas Operation Model (runtime)

Each canvas operation is a `Map<String, dynamic>` with an `'op'` field:

```
{
  'op': 'create',
  'width': '400',    // string (may contain ((placeholders)))
  'height': '300',
  'color': '#ffffff',
}
```

Supported operations:

| Op | Parameters | Description |
|---|---|---|
| `create` | width, height, color | Create blank canvas (must be first) |
| `loadImage` | url | Load image from URL/base64 (replaces canvas) |
| `compositeImage` | url, x, y, width?, height?, shape? | Overlay image at position, optional mask |
| `drawText` | text, x, y, fontSize, color | Draw bitmap text |
| `drawCircle` | x, y, radius, color, fill | Draw/fill circle |
| `drawRect` | x, y, width, height, color, fill | Draw/fill rect |
| `drawLine` | x1, y1, x2, y2, color, thickness | Draw line between two points |

### 4.3 Canvas Result Model

After execution, two entries are written to the runtime variables map:

```dart
variables['rtImage_0']         = '<base64 PNG bytes>'
variables['rtImage_0.dataUrl'] = 'data:image/png;base64,<base64>'
```

The `.dataUrl` variant is consumed by `respondWithMessage` attachments: the executor decodes it and attaches the binary PNG to the Discord message.

---

## 5. Canvas Rendering Strategy

### 5.1 Current: Dart-Native Image Package (CPU rendering)

**Library:** `image` package v4.8.0 (`pub.dev/packages/image`)

**Why this was chosen:**
- Runs in pure Dart — no Flutter dependency in the `shared` package (the runner is a CLI, not a Flutter app)
- Supports all needed primitives: fill, drawString, drawCircle, drawRect, compositeImage
- PNG encode/decode built-in
- No GPU, no window, no platform channel — works in Docker containers and CI

**Limitations:**
- **CPU-bound**: pixel-level loops in Dart (no SIMD/GPU acceleration). A 1024×1024 canvas with multiple composites can take 100-300ms.
- **No anti-aliasing for shapes** — bitmap fonts are aliased at their native sizes; circle masks are hard-edged. Anti-aliased circle masking is planned (see §5.4).
- **No SVG/filter support** — no blurs, shadows, gradients
- **No Flutter interoperability** — the rendered bytes can't be directly painted to a Flutter `Canvas` without decoding/encoding roundtrip

### 5.2 Alternatives Considered

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **`image` package (current)** | Pure Dart, no Flutter dep, proven | CPU-bound, limited effects | ✓ Keep for runtime |
| **Flutter CustomPainter + `ui.Image`** | GPU-accelerated, anti-aliased, rich API | Requires Flutter, can't run headless in runner | Only viable for in-app preview |
| **`dart:ui` Canvas via Flutter engine** | Same as CustomPainter but programmatic | Needs Flutter engine, not available in CLI runner | Not viable |
| **ImageMagick subprocess** | Feature-rich, fast C impl | External dep, fragile across platforms | Rejected |
| **CanvasKit/WASM** | Skia rendering in non-Flutter contexts | Heavy (~3MB), async API mismatch | Over-engineered |

### 5.3 Recommended Path Forward

**Dual-mode rendering:**

```
                  ┌─────────────────────────┐
                  │   Same operation list    │
                  │   (serialized as JSON)   │
                  └───────────┬─────────────┘
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
   ┌────────────────────┐            ┌────────────────────┐
   │  Runtime (runner)  │            │  Editor (app)      │
   │  image package     │            │  CustomPainter      │
   │  CPU rendering     │            │  GPU rendering      │
   │  → PNG output      │            │  → Live preview     │
   └────────────────────┘            └────────────────────┘
```

- **Runtime stays on `image` package** — it works, it's battle-tested, and replacing it would add risk without user-facing benefit
- **Editor preview adds a `CanvasPreviewWidget`** using Flutter's `CustomPainter` — this renders the same operation list to screen, giving users visual feedback
- The operation list is the single source of truth — both renderers interpret it

### 5.4 Anti-Aliased Circle Masking (Planned)

The `image` package's `drawCircle()` with `fill` produces hard-edged circles — no sub-pixel alpha blending. For `compositeImage` with `shape:circle`, anti-aliased edges are preferred for visual quality.

**Approach:**

Instead of using `drawCircle(..., fill: true)` to create the mask, generate a circle mask with **manual alpha blending** using `image.copyInto()` with `alpha: true`:

```dart
img.Image _createAntiAliasedCircleMask(int diameter) {
  final mask = img.Image(width: diameter, height: diameter);
  final radius = diameter / 2.0;
  final center = radius - 0.5; // sub-pixel center

  for (var y = 0; y < diameter; y++) {
    for (var x = 0; x < diameter; x++) {
      final dx = x - center;
      final dy = y - center;
      final dist = math.sqrt(dx * dx + dy * dy);
      // Smoothstep alpha: 1.0 at center, 0.0 at edge, transition over 1px boundary
      final alpha = (1.0 - (dist / (radius - 0.5))).clamp(0.0, 1.0);
      if (alpha > 0) {
        mask.setPixelRgba(x, y, 255, 255, 255, (alpha * 255).round());
      }
    }
  }
  return mask;
}
```

This produces a per-pixel alpha mask that smoothly fades at the circle boundary. The mask is then composited with the source image via `image.compositeImage()` using `srcAlpha` blend mode:

```dart
final masked = img.compositeImage(
  source: sourceImage,
  destination: img.Image(width: diameter, height: diameter),
  srcX: 0, srcY: 0, dstX: 0, dstY: 0,
  srcW: diameter, srcH: diameter,
  blend: false,
);
// Apply mask alpha to masked image
for (var px in masked) {
  final maskAlpha = mask.getPixel(px.x, px.y).a;
  px.a = ((px.a * maskAlpha) / 255).round();
}
```

**Trade-off:** Per-pixel iteration in Dart is CPU-intensive (~5-10ms for a 128×128 circle). For production, pre-compute mask lookup tables or move to isolate (see §8.3).

---

## 6. Data Flow

### 6.1 Authoring Flow (BDFD transpiler path)

```
User writes BDFD script:
  $canvasCreate[welcome;800;400;#2c2f33]
  $canvasLoadImage[https://cdn.example.com/logo.png]
  $canvasDrawText[Welcome!;50;200;48;white]
  $canvasCompositeImage[((author.avatar));600;50;96;96;circle]
  $attachImage[welcome-card]

       │
       ▼
bdfd_ast_transpiler/image_canvas.dart
  → _canvasCreate()    → start deferred image block, add 'create' op
  → _canvasLoadImage() → add 'loadImage' op
  → _canvasDrawText()  → add 'drawText' op
  → _canvasCompositeImage() → add 'compositeImage' op
  → _canvasAttachImage() → flush block → runtimeImageBlock + setTemporaryVariable

       │
       ▼
Serialized Action:
  { type: runtimeImageBlock, key: rtImage_0,
    payload: { operations: [
      {op: create, width: 800, height: 400, ...},
      {op: loadImage, url: "https://..."},
      ...
    ]}}

       │
       ▼
handler.dart → variables_executor.dart → executeRuntimeImageBlock()
  → Iterates operations sequentially
  → Each op mutates an in-memory img.Image buffer
  → Final: img.encodePng() → base64 → variables map
```

### 6.2 Authoring Flow (Visual Builder path)

```
User adds canvas blocks via the action editor:
  [+ Add Action] → Image → Create Canvas    (canvasCreateBlock)
  [+ Add Action] → Image → Load Image       (canvasLoadImageBlock)
  [+ Add Action] → Image → Draw Text        (canvasDrawTextBlock)

       │
       ▼
ActionItem list in CommandEditorNotifier.state:
  [canvasCreateBlock, canvasLoadImageBlock, canvasDrawTextBlock]

       │
       ▼
Serialization (action_normalization.dart):
  _canvasBlockToOp mapping identifies adjacent canvas blocks
  Collapses them into ONE runtimeImageBlock with all operations
  Rest of the action list remains unchanged

       │
       ▼
Same runtime path as transpiler flow above.
```

### 6.3 Variable Resolution Flow

Canvas parameters support `((placeholders))`:

```
Parameter value: "((author.avatar))"
       │
       ▼
_resolve() in image_executor.dart
  → Detects '(( ' pattern
  → Calls resolveValue("((author.avatar))")
  → Template resolver replaces with actual runtime value
  → Returns "https://cdn.discordapp.com/avatars/..."
```

This means canvas operations can reference:
- Command arguments (`((1))`, `((2))`)
- Runtime variables (`((myVar))`)
- Discord context (`((author.avatar))`, `((guild.name))`)
- Bot variables (`((botVar.uptime))`)
- Global/scoped variables from storage

---

## 7. Component Breakdown

```
packages/shared/lib/
├── types/
│   └── action.dart                    # BotCreatorActionType enum + Action model
├── actions/
│   ├── handler.dart                   # Main action dispatcher (routes runtimeImageBlock)
│   └── executors/
│       ├── variables_executor.dart    # Case runtimeImageBlock → executeRuntimeImageBlock()
│       └── image_executor.dart        # Operation handlers + helpers
├── utils/
│   └── bdfd_ast_transpiler/
│       ├── bdfd_ast_transpiler.dart   # Main transpiler (declares _deferredImage* state)
│       └── image_canvas.dart          # Canvas function transpilation (part of transpiler)
└── engine/
    ├── command_executor.dart          # Routes Discord interactions
    └── workflow_executor.dart         # Executes action lists

packages/app/lib/
├── features/bot_editor/
│   ├── logic/
│   │   ├── command_editor_notifier.dart    # Owns action list state
│   │   ├── command_editor_state.dart       # Immutable state model
│   │   └── action_normalization.dart       # Canvas block → runtimeImageBlock collapse
│   └── presentation/screens/bot_sub_pages/
│       └── builder/
│           ├── action_types.dart           # ActionItem, ParameterDefinition, ParameterType
│           ├── action_type_extension.dart  # Per-type displayName, icon, parameterDefinitions
│           ├── action_card.dart            # Renders parameter fields
│           └── action_summary.dart         # Compact action descriptions
```

### Responsibilities

| Component | Responsibility |
|---|---|
| `image_executor.dart` | Execute a list of canvas operations sequentially on an `img.Image` buffer. Handles URL resolution, color parsing, font selection, shape masking. |
| `image_canvas.dart` | BDFD transpiler extension: detects canvas functions in AST, collects operations, emits `runtimeImageBlock` action on flush. |
| `action_normalization.dart` | Collapses adjacent `canvas*Block` visual sub-actions into a single `runtimeImageBlock` with an `operations` list. |
| `variables_executor.dart` | Routes `runtimeImageBlock` to `executeRuntimeImageBlock()`. Guards against standalone canvas sub-actions (throws StateError). |
| `action_type_extension.dart` | Declares `parameterDefinitions` for each canvas block type — which fields the editor shows. |
| `action_card.dart` | Renders parameter input fields based on `ParameterDefinition`. Includes file picker integration for `canvasLoadImageBlock`. |
| `action_summary.dart` | Shows a compact description of each canvas block in the action list. |

---

## 8. Performance Considerations

### 8.1 Current Performance Profile

| Operation | ~500×500 canvas | ~1024×1024 canvas |
|---|---|---|
| create | <1ms | <1ms |
| drawText (arial14, 20 chars) | ~2ms | ~5ms |
| drawCircle (filled, r=100) | ~5ms | ~15ms |
| drawRect (filled, 200×100) | ~3ms | ~8ms |
| compositeImage (500×500 overlay) | ~15ms | ~50ms |
| **Total: typical 3-op block** | **~30ms** | **~80ms** |
| PNG encode (final) | ~10ms | ~40ms |

These are measured on a typical x86-64 runner. On ARM (Raspberry Pi), expect 2-3× slower.

### 8.2 Mitigation Strategies

1. **URL cache per block**: Already implemented — `_resolveImageSource` caches HTTP responses in a `Map<String, Uint8List>` scoped to the execution of one block. Multiple composite operations referencing the same URL only download once.

2. **No unnecessary copies**: Operations mutate the canvas in-place (`compositeImage`, `drawText`, etc. all take and return the same `img.Image` reference). Masks create temporary buffers then discard them.

3. **Deferred execution**: The transpiler collects all canvas operations before emitting the block — no partial execution. If the BDFD script encounters a `stopUnless` before the canvas is attached, the image block is never executed (wasted work avoided).

### 8.3 Future Optimizations

- **Isolate offloading**: Move `executeRuntimeImageBlock()` to a Dart isolate. The `image` package is pure Dart, so it serializes cleanly. This would avoid blocking the Nyxx event loop on large compositions.
- **Lazy PNG encoding**: Only encode to PNG if the result is actually consumed (i.e., attached to a message). If the result is only used as `((rtImage_0))` in a subsequent canvas block, keep it as `img.Image` to avoid decode/re-encode.
- **Operation batching**: If multiple sequential `drawText` calls have the same font/color, combine them into a single `drawString` call with line breaks.

---

## 9. Extension Points for Dynamic Variables

### 9.1 Current Variable Support

Canvas parameters already resolve `((placeholders))` via the `resolveValue` callback:

```dart
// Any string parameter can be a template:
'color': '((userConfig.accentColor))'   // resolves at runtime
'text':  'Hello ((author.name))!'        // resolves at runtime
'url':   '((guild.icon))'                // resolves at runtime
```

Resolution happens at execution time in the runner, which has access to the full Discord context.

### 9.2 Proposed Extensions

**A. Conditional Canvas Operations**

Add a `condition` field to each operation that gates execution:

```json
{
  "op": "compositeImage",
  "url": "((member.premiumBadge))",
  "x": "10", "y": "10",
  "condition": "((member.isPremium)) != false"
}
```

Implementation: before executing each op, resolve and evaluate `condition`. If empty or resolves to truthy, execute normally. If falsy, skip.

**B. Iteration over Lists (Canvas Loops)**

Allow `forEach`-style loops in canvas blocks for leaderboard images, member lists, etc.:

```json
{
  "op": "forEach",
  "list": "((leaderboard.entries))",
  "itemTemplate": {
    "op": "drawText",
    "text": "((item.rank)). ((item.name))",
    "x": "10",
    "y": "((item.index * 24 + 100))",
    "fontSize": "14",
    "color": "white"
  }
}
```

The `item.index` and `item.<field>` variables are scoped to the iteration.

**C. Data-Bound Templates (Compositions)**

A "composition" is a named, reusable layout with variable slots:

```json
{
  "composition": "welcomeCard",
  "slots": {
    "avatar": "((author.avatar))",
    "username": "((author.name))",
    "memberCount": "((guild.memberCount))"
  }
}
```

Compositions are defined as named operation lists **in the bot's configuration** (stored alongside the bot's JSON config, not in a separate resource file). Each composition uses `$slot.name` placeholders that get replaced at invocation time. This keeps the bot definition self-contained — the composition is part of the bot's serialized state, not an external dependency.

### 9.3 Implementation Approach for Extensions

All three extensions follow the same pattern: **enrich the operation map before it reaches the executor**. This keeps `image_executor.dart` simple while the transpiler/normalizer handles the higher-level constructs.

```
BDFD script → transpiler → enriched operations with loops/conditions
                               │
                               ▼
                       Operation expander
                     (resolves conditions,
                      unrolls forEach loops,
                      substitutes composition slots)
                               │
                               ▼
                       Flat operation list
                               │
                               ▼
                       image_executor.dart
                     (unchanged — receives flat list)
```

---

## 10. Integration Points

### 10.1 With Existing Bot Creator Systems

| System | Integration |
|---|---|
| **BDFD Transpiler** | `image_canvas.dart` — detects `$canvas*` functions, emits `runtimeImageBlock` |
| **Command/Workflow Editor** | `canvas*Block` action types appear in action palette, configurable via `ParameterDefinition` |
| **Action Serialization** | `action_normalization.dart` — collapses visual blocks into runtime format |
| **Runtime Variables** | Output written to `variables['rtImage_N']` and `variables['rtImage_N.dataUrl']` |
| **Message Attachments** | `respondWithMessage` consumes `_canvasAttachment_name` to attach PNG to Discord message |
| **Debug Replay** | Canvas operations are captured in replay frames if replay is active |
| **Variable Suggestion** | Canvas parameter editors use `VariableTextField` — same autocomplete as other action params |

### 10.2 Adding a New Canvas Operation

Step-by-step guide for future contributors:

1. **`action.dart`** — Add new enum entry in `BotCreatorActionType` (e.g., `canvasDrawLineBlock`)
2. **`action_type_extension.dart`** — Add `displayName`, `icon`, and `parameterDefinitions` cases
3. **`action_normalization.dart`** — Add entry to `_canvasBlockToOp` mapping
4. **`image_canvas.dart`** — Add case in `_isImageCanvasFunction()`, add transpile method
5. **`image_executor.dart`** — Add `case` in main switch, implement `_opDrawLine()` handler
6. **`image_executor_test.dart`** — Add test
7. **i18n ARB files** — Add translations for `action_name_canvasDrawLineBlock`

The recently approved `drawLine` operation follows this exact checklist, including the corresponding BDFD function `$canvasDrawLine[x1;y1;x2;y2;color;thickness]`.

---

## 11. Deployment & Platform Considerations

### 11.1 Runner Contexts

| Platform | Works? | Notes |
|---|---|---|
| Linux x86-64 (main) | ✓ | Primary target |
| Linux ARM64 (Raspberry Pi, OrangePi) | ✓ | 2-3× slower; consider isolate offloading |
| Windows x86-64 | ✓ | Via `dart run` in the runner |
| macOS | ✓ | Not a primary deployment target |
| Web (Flutter Web) | N/A | Image package doesn't run in browser; would need CanvasKit fallback |

### 11.2 Docker / Containerized

The `image` package has no native dependencies — it's pure Dart. No need for `apt-get install imagemagick` or similar in Dockerfiles.

### 11.3 Memory

A 1024×1024 RGBA canvas is ~4 MB. With 2-3 overlays in flight (source + mask + composite), peak memory per image block is ~12-16 MB. This is acceptable for the bot runner (typically 128-512 MB allocated).

---

## 12. Risks & Resolved Decisions

### 12.1 Risks

| Risk | Mitigation |
|---|---|
| **CPU-bound rendering blocks Nyxx event loop** | Offload to isolate (Dart 3.x isolates have good ergonomics with send/receive ports) |
| **Large images cause OOM** | Enforce max canvas dimensions (2048×2048) in transpiler; validate in executor |
| **Malicious URLs in `loadImage`** | HTTP client already has 15s timeout; can add content-length check before download |
| **User expects real-time preview** | Explicitly communicate server-side rendering; preview feature is Phase 2 |
| **Font limitations** | `image` package ships with 3 bitmap fonts (arial14/24/48). TrueType support requires `flutter` or a native extension |

### 12.2 Resolved Decisions

**1. Anti-aliased edges for `compositeImage` with `shape:circle`**

*Decision:* Anti-aliased edges are preferred for visual quality. The approach uses manual per-pixel alpha blending with `image.copyInto()` — generating a smooth circle mask with sub-pixel alpha, then compositing via `srcAlpha` blend mode. See §5.4 for the detailed approach and code. Trade-off: per-pixel loops in Dart are CPU-intensive (~5-10ms for 128×128), mitigated by pre-computed lookup tables or isolate offloading.

**2. Add `drawLine` operation**

*Decision:* Yes — add `drawLine` as a supported canvas operation with parameters `x1, y1, x2, y2, color, thickness`. The corresponding BDFD function is `$canvasDrawLine[x1;y1;x2;y2;color;thickness]`. Implementation follows the standard 7-step new-operation checklist in §10.2. The line-drawing algorithm (Bresenham) is trivial to implement in the `image` package.

**3. Composition/template storage location**

*Decision:* Compositions are stored in the bot's configuration (the serialized JSON config), not in a separate resource file. This keeps the bot definition self-contained — the composition is part of the bot's state, portable, and doesn't introduce an external file dependency. See §9.2.C for the updated storage model.

---

## 13. References

- `packages/shared/lib/actions/executors/image_executor.dart` — Runtime executor (465 lines)
- `packages/shared/lib/utils/bdfd_ast_transpiler/image_canvas.dart` — BDFD transpiler extension (183 lines)
- `packages/shared/lib/types/action.dart` — Action type enum + model (203 lines)
- `packages/app/lib/features/bot_editor/logic/action_normalization.dart` — Canvas block → runtime block collapse (159 lines)
- `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart` — Parameter definitions (3427 lines — canvas blocks at ~L3273)
- `packages/shared/test/image_executor_test.dart` — Executor tests (478 lines, 10 test cases)
- `pub.dev/packages/image` v4.8.0 — Dart image manipulation library
