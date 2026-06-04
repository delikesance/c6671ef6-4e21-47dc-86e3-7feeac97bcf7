# Image Editor — Design Tokens & Interaction Notes

> Bot Creator Visual Builder — Image Editor module
> Version 2.0 · June 2026
>
> **Updated to match real codebase:** Operations-based editing with numeric parameters, read-only canvas preview. No mouse-based dragging or resizing.

---

## 1. Design Tokens

All tokens extend the Bot Creator `AppTheme` design system. No new palette — reuse existing.

### Colors

| Token | Value | Usage |
|---|---|---|
| `--brand-primary` | `#6A0FA2` | Header, primary buttons, active toolbar icons, selection border |
| `--brand-secondary` | `#9B30FF` | Hover states, selected operation highlight on canvas, gradient accents |
| `--dark-surface` | `#2C2C3A` | Operations panel bg, toolbar bg, property panel bg |
| `--dark-surface-variant` | `#3A3A4A` | Hover states, secondary buttons, insert-op buttons |
| `--code-surface` | `#1E1E1E` | Input fields, select dropdowns |
| `--discord-border` | `#404249` | Panel borders, input borders, separators |
| `--discord-text` | `#B5BAC1` | Body text, labels, operation names |
| `--white` | `#FFFFFF` | Header text, canvas background, tooltips |
| `--grey` | `#9E9E9E` | Secondary text, hints, disabled state |
| `--warning` | `#FFA726` | Variable placeholders (`#{var}`), unresolved variable warnings |
| `--success` | `#2E7D32` | Preview button, save confirmation |
| `--error` | `#E53935` | Error banners, broken image indicators |
| Canvas checkboard | `#2C2C3A` / transparent | Repeating conic gradient 20px — indicates transparency in canvas area |

### Spacing

Reuse `AppTheme` spacing scale:

| Token | Value | Usage |
|---|---|---|
| `spacingXs` | 4px | Toolbar icon padding, op-item gaps |
| `spacingSm` | 8px | Panel padding, toolbar gaps, prop row gaps |
| `spacingMd` | 12px | Property panel body padding, operation item padding |
| `spacingLg` | 16px | Section gaps, panel padding |
| `spacingXl` | 20px | Quick-size buttons padding |
| `spacingXxl` | 24px | Empty state padding |

### Radii

| Token | Value | Usage |
|---|---|---|
| `radiusXs` | 4px | Add-op button, drag handles, delete button |
| `radiusSm` | 8px | Toolbar buttons, input fields, operation items |
| `radiusMd` | 12px | Quick-size buttons, property groups |
| `radiusPill` | 999px | Variable badges, mode badges |

### Typography

| Element | Size | Weight | Color |
|---|---|---|---|
| Header title | 14px | 600 (semiBold) | `white` |
| Panel section headers | 12px | 700 | `grey`, uppercase, 0.5px letter-spacing |
| Operation names | 13px | 400 | `discord-text` |
| Operation summaries | 11px | 400 | `grey`, `font-mono` |
| Property labels | 12px | 400 | `grey` |
| Property values | 13px | 400 | `discord-text`, `font-mono` |
| Variable placeholders | 13px | 400 | `warning`, `font-mono` |
| Empty state title | 18px | 600 | `white` |
| Empty state description | 14px | 400 | `grey` |
| Button text | 13px | 600 | varies |
| Zoom indicator | 12px | 400 | `white` |

Font family: System sans-serif for UI (`-apple-system, BlinkMacSystemFont, Segoe UI, Roboto`), monospace for code/values (`SF Mono, Cascadia Code, JetBrains Mono, Fira Code`).

### Elevation

| Token | Value | Usage |
|---|---|---|
| `elevationLow` | `0 1px 3px rgba(0,0,0,0.12)` | Toolbar border shadow |
| `elevationMedium` | `0 4px 12px rgba(0,0,0,0.18)` | Canvas frame shadow, mobile sidebar overlays |
| `elevationHigh` | `0 8px 32px rgba(0,0,0,0.5)` | Canvas frame shadow (desktop) |

### Animation

| Token | Duration | Usage |
|---|---|---|
| `animFast` | 200ms | Operation selection transition, button hover |
| `animNormal` | 300ms | Panel slide, zoom scale transition |
| Pulse | 1.5s ease-in-out | Loading skeleton animation |

Respect `prefers-reduced-motion`: disable pulse and scale transitions when set.

---

## 2. Interaction Patterns

### 2.1 Architecture: Operations-Based Editing

The Image Editor uses an **operation-based editing model** matching the real codebase (`action_normalization.dart`, `image_executor.dart`):

- **Each operation** = one canvas sub-action (`canvasCreateBlock`, `canvasLoadImageBlock`, `canvasDrawTextBlock`, `canvasDrawCircleBlock`, `canvasDrawRectBlock`)
- Operations execute **sequentially** in order (like a script)
- **No mouse-based manipulation on canvas** — position and size are set via numeric fields in the property panel
- Canvas preview is **read-only** — it renders the operation list passively

### 2.2 Canvas Interactions

**Pan (desktop)**
- Middle-click + drag anywhere on canvas
- Space + left-click drag
- Two-finger drag on trackpad

**Pan (mobile)**
- One-finger drag on canvas (always pans — no element selection on canvas)

**Zoom (desktop)**
- Scroll wheel (mouse) or two-finger pinch (trackpad)
- Zoom buttons in toolbar (+/-)
- Range: 25% to 300%
- Zoom centers on cursor position

**Zoom (mobile)**
- Two-finger pinch-to-zoom
- Double-tap to fit canvas in viewport
- Toolbar zoom buttons always available

**Operation Selection**
- Click on operation in operations panel (left) → selects it, shows properties on right
- Selected operation's rendered element on canvas gets a dashed purple outline
- Click on empty canvas area → deselects all (shows canvas properties)
- There is NO clicking on canvas elements to select them (canvas is read-only)

**Position/Size Editing**
- ALL position (x, y) and size (width, height, radius) values are set via **numeric input fields** in the property panel
- No drag-to-move on canvas
- No resize handles on canvas
- Values update the preview in real-time (on change/blur)
- Arrow key nudging (±1px) when property field is focused

### 2.3 Operations Panel (Left Sidebar)

**Layout:**
- Ordered list of operations with index numbers
- Each operation shows: index (#1), drag handle, icon, type name, compact summary
- Selected operation highlighted with purple left border + tinted background
- Drag handle (⠿) to reorder operations (except Create Canvas which stays first)
- Hover reveals delete (×) button
- Header shows operation count

**Drag & Drop Reordering:**
- Drag operations by the ⠿ handle
- Live preview of new position
- Create Canvas cannot be moved (must remain first)
- Other canvas operations cannot be moved above Create Canvas

**Adding Operations:**
- Toolbar buttons: Canvas, Image, Text, Circle, Rect
- "+ Add" button in panel header
- "Insert after" buttons in property panel (when an operation is selected)

### 2.4 Property Panel (Right Sidebar)

**When no operation selected → Canvas Properties:**
- Displays read-only canvas dimensions and background color
- Hint to edit Create Canvas operation

**When operation selected → Operation Properties:**
- Shows all parameters for the selected operation type (matching `parameterDefinitions` in code)
- All fields are editable
- Variable fields highlighted in orange (`--warning` color + tinted background)
- Variable badge shown below fields containing `#{...}` or `((...))`

**Per-operation parameters:**

| Operation | Parameters |
|---|---|
| Create Canvas | Width (number), Height (number), Color (hex/name) |
| Load Image | URL (text/url), Target Width (number, -1=original), Target Height (number, -1=original) |
| Draw Text | Text (string), X (number), Y (number), Font Size (number), Color (hex/name) |
| Draw Circle | X (number, center), Y (number, center), Radius (number), Color (hex/name), Fill (boolean) |
| Draw Rectangle | X (number), Y (number), Width (number, fixed), Height (number, fixed), Color (hex/name), Fill (boolean) |

### 2.5 Toolbar Interactions

**Layout:**
- Desktop: Horizontal bar below header, all tools visible
- Mobile: Collapsed to bottom bar with primary actions; zoom controls always visible

**Button states:**
- Default: transparent bg, `discord-text` color
- Hover: `dark-surface-variant` bg
- Primary (Create Canvas): `brand-primary` bg always, `brand-secondary` on hover

**Tool actions:**

| Icon | Action | Behavior |
|---|---|---|
| 🎨 Canvas | Create Canvas | Adds canvasCreateBlock as first operation |
| 🖼️ Image | Load Image | Adds canvasLoadImageBlock at end |
| 🅰️ Text | Draw Text | Adds canvasDrawTextBlock at end |
| ◯ Circle | Draw Circle | Adds canvasDrawCircleBlock at end |
| ▭ Rect | Draw Rectangle | Adds canvasDrawRectBlock at end |
| 🔍− | Zoom Out | -10% per click (min 25%) |
| 100% | Reset Zoom | Resets to 100% |
| 🔍+ | Zoom In | +10% per click (max 300%) |

### 2.6 Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Delete / Backspace` | Delete selected operation (with confirmation for canvas) |
| `Escape` | Deselect operation (shows canvas properties) |
| `Arrow keys` | Nudge focused property field by ±1 (Shift + 10) |
| `Ctrl/Cmd + +/-` | Zoom in/out |
| `Ctrl/Cmd + 0` | Reset zoom |
| `Space + drag` | Pan canvas |
| `Ctrl/Cmd + S` | Save & close |

---

## 3. Screen States

### 3.1 Empty State

**Trigger:** No canvas created yet (new `runtimeImageBlock` with no operations)

**Display:**
- Centered illustration + title "Start creating your image"
- Description text explaining the operation-based model
- Three quick-start buttons:
  - **400 × 300** — Compact banner
  - **800 × 600** — Standard composition (default)
  - **1200 × 630** — OG Image / social media
- Custom width × height input with Create button
- Clicking any creates a canvasCreateBlock and switches to editing state

### 3.2 Loading State

**Trigger:** Canvas being created, image URLs resolving in preview

**Display:**
- Skeleton canvas frame at target dimensions
- Pulsing opacity animation (1.5s ease-in-out)
- "Rendering preview…" text centered
- Toolbar remains interactive (user can edit params)
- Transitions to editing state once render completes or times out

### 3.3 Editing State (Normal)

**Display:**
- Three-zone layout: Operations Panel | Canvas Preview | Property Panel
- Operations listed in order with drag handles
- Canvas with checkerboard background, rendered elements (read-only)
- Property panel reflects selected operation or canvas properties
- Toolbar fully interactive
- Bottom bar shows dimensions + variable count

### 3.4 Error / Broken Image State

**Trigger per operation:** Image URL fails to load (404, CORS, invalid)

**Display:**
- Operation item in panel gets ⚠️ prefix
- Error banner at top: "image.png failed to load — [Retry] [✕]"
- Property panel shows broken URL highlighted in red
- Retry button re-attempts fetch; dismiss hides banner
- Other operations remain functional

**Trigger global:** All images fail or critical error

**Display:**
- Canvas shows ❌ icon + "Image failed to render" + retry button
- Operations panel remains visible for debugging

### 3.5 Unsaved Changes Guard

**Trigger:** User tries to navigate away (back button, close, switch tab) with unsaved changes

**Display:**
- Dialog: "Leave editor? Unsaved changes will be lost."
- Buttons: [Stay] [Discard & Leave]
- Stays if confirmed; discards local state if user chooses to leave

### 3.6 Save Confirmation

**Trigger:** User clicks "Save & Close"

**Behavior:**
- Serializes operations to `runtimeImageBlock` format:
  - Each operation → `{type: "canvasCreateBlock", payload: {width, height, color}}`
  - Operations array stored in `payload.operations`
- Collapses via `action_normalization.dart` `_canvasBlockToOp` mapping
- Variable placeholders preserved as-is (e.g., `#{user.avatar_url}`)
- Closes editor, returns to workflow builder
- Brief "✓ Saved" confirmation

---

## 4. Dynamic Variable Placeholders

### 4.1 Supported Fields

Every text, number, and URL field in the property panel supports variable interpolation:

| Field | Example |
|---|---|
| Image URL | `#{user.avatar_url}` or `((author.avatar))` |
| Text content | `Welcome #{user.name}! Today is #{date.now}` |
| Position X/Y | `#{config.margin}` |
| Width/Height | `#{image.width}` |
| Color | `#{config.accent_color}` |
| Font size | `#{config.title_size}` |
| Radius | `#{config.circle_size}` |
| Fill | N/A (boolean only) |

### 4.2 Visual Treatment

- Active variable placeholder: orange text (`#FFA726`) on orange-tinted background (`rgba(255,167,38,0.08)`)
- Orange border on input field when it contains a variable
- Variable badge (🔗) below field showing the placeholder text
- Real-time preview renders with sample values where applicable

### 4.3 Variable Count

- Bottom bar shows variable tally
- Updates in real-time as user types/edits fields
- Helps user understand how dynamic the image composition is

### 4.4 Unresolved Variable Warning

- When saving, scan all fields for `#{...}` / `((...))` patterns
- If any variable is not recognized, show warning:
  - "2 variables may not resolve at runtime: #{custom_font}, #{unknown_key}. Continue?"
- User can save anyway (graceful fallback: empty string for unresolved text, 0 for unresolved numbers)

---

## 5. Data Models

### 5.1 Operation Types (matching `BotCreatorActionType` enum)

```
runtimeImageBlock          ← runtime: collapsed block with all ops
  operations: [
    canvasCreateBlock       ← visual-only sub-action
    canvasLoadImageBlock    ← visual-only sub-action
    canvasDrawTextBlock     ← visual-only sub-action
    canvasDrawCircleBlock   ← visual-only sub-action
    canvasDrawRectBlock     ← visual-only sub-action
  ]
```

### 5.2 Operation Serialization (matching action_normalization.dart)

```json
{
  "type": "runtimeImageBlock",
  "payload": {
    "operations": [
      {"op": "create", "width": "800", "height": "600", "color": "#2C2C3A"},
      {"op": "loadImage", "url": "#{bg_url}", "width": "-1", "height": "-1"},
      {"op": "drawText", "text": "Welcome #{user.name}!", "x": "20", "y": "20", "fontSize": "24", "color": "#ffffff"},
      {"op": "drawCircle", "x": "400", "y": "300", "radius": "45", "color": "#9B30FF", "fill": "true"},
      {"op": "drawRect", "x": "640", "y": "550", "width": "150", "height": "40", "color": "#FFA726", "fill": "true"}
    ]
  }
}
```

### 5.3 Editor State Model (Dart-ready)

```dart
class ImageEditorState {
  final List<CanvasOperation> operations;  // ordered list
  final int? selectedOperationIndex;       // null = canvas properties
  final int canvasWidth;
  final int canvasHeight;
  final String canvasColor;
}

class CanvasOperation {
  final String type;         // BotCreatorActionType name
  final Map<String, dynamic> params;  // parameter values
}
```

The first operation MUST be `canvasCreateBlock`. Its `width`/`height`/`color` define the canvas.

---

## 6. Integration Notes

### 6.1 Entry Point

The Image Editor is accessed from the `runtimeImageBlock` action editor in the workflow builder.

**Current:** Block parameter view (operations list as JSON)
**New:** "Open in Visual Editor" button at the top of the parameter form

### 6.2 Serialization (Two-Way)

**Deserialization (opening existing block):**
1. Parse `payload.operations` array
2. For each op, map `op` field → `BotCreatorActionType` (reverse of `_canvasBlockToOp`)
3. Extract parameters into visual editor state

**Serialization (saving):**
1. Collect all operations in order
2. For each, run through `_canvasBlockToOp` mapping
3. Write to `payload.operations` as flat `Map<String, String>` array

### 6.3 File/Image Picker

Reuse existing pattern from `canvasLoadImageBlock`: local file → base64 data URL conversion. User sees filename preview, never the base64 string.

### 6.4 Mobile Adaptation

- **Panel management:** Mobile uses tab bar (Preview | Operations | Properties) instead of side panels
- **Toolbar:** Collapses to bottom bar with primary operation buttons; zoom controls always visible
- **Canvas:** Fills viewport; pinch-to-zoom; double-tap to fit
- **Operations panel:** Slides in from left when "Operations" tab active
- **Property panel:** Slides in from right when "Properties" tab active
- **Touch targets:** Minimum 44×44pt (WCAG 2.2)

### 6.5 Accessibility

- **Screen reader:** All UI elements have semantic labels. Operations list reads "Operation 1: Create Canvas, 800 by 600"
- **Keyboard:** Full keyboard navigation (Tab through operations and properties, arrows to navigate operation list)
- **Contrast:** All text meets WCAG AA (4.5:1 for body, 3:1 for large text)
- **Focus:** Visible focus ring on all interactive elements
- **Motion:** Respects `prefers-reduced-motion` — disables pulse animation and smooth zoom transitions

### 6.6 What Changed from v1 (WYSIWYG) to v2 (Operations-Based)

| Aspect | v1 (incorrect) | v2 (matches real code) |
|---|---|---|
| Canvas manipulation | Drag to move, corner resize handles | Read-only preview, no mouse interaction |
| Position | Set by dragging | Set via numeric X/Y fields |
| Size | Set by resizing handles | Set via numeric width/height/radius fields |
| Layer concept | Visual layers with z-index reorder | Ordered operations (sequential execution) |
| Property editing | In-place on canvas | Property panel with form fields |
| Rectangle behavior | Resizable by dragging | Fixed size (set in fields) |
| Circle behavior | Resizable by dragging | Fixed radius (set in field) |

---

## 7. Deliverables Checklist

| Deliverable | File | Status |
|---|---|---|
| User flow diagram | `Image Editor User Flow.excalidraw` | ✅ (updated for v2) |
| Interactive prototype | `Image Editor Prototype.html` | ✅ (v2 — operation-based) |
| Design tokens & interaction notes | `Image Editor Design Tokens.md` (this file) | ✅ (v2) |

### How to Use

1. **Flow diagram:** Open the `.excalidraw` file at [excalidraw.com](https://excalidraw.com) — drag and drop
2. **Prototype:** Open `Image Editor Prototype.html` in any browser — click "800 × 600 Standard" to see editing state with 5 demo operations, select operations to edit properties, try reordering and deleting
3. **Tokens:** Reference this document (`Image Editor Design Tokens.md`) during implementation for exact values
