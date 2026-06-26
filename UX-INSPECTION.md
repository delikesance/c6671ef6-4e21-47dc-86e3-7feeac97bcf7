# Bot Creator — UX Inspection: Onboarding & Command Creation

## Problem Statement

Users are lost when they first try to create a command for their bot. This document maps every friction point and proposes solutions. No code changes yet.

---

## 1. The Novice Journey (As It Exists Today)

```
[App Open] → [Onboarding 5 steps, text-only] → [Home: empty, FAB +]
  → [Paste token] → [Popup: sample /ping?]
  → [Bot Editor: 12 tabs] → [Commands tab: empty list, FAB +]
  → [Bottom sheet: 3 choices] → [CommandCreatePage: THE WALL]
```

### The Wall: CommandCreatePage Step 1

A novice who wants to make `/hello` that says "Hi!" is confronted with:

| Field | Novice understands? | Required? |
|-------|---------------------|-----------|
| Command name | Yes | Yes |
| Description | Somewhat | Yes |
| Command type (chatInput/user/message) | No | Shown |
| Legacy command toggle | No | Hidden in expansion |
| Integration types (guildInstall/userInstall) | No | Shown |
| Contexts (guild/botDM/privateChannel) | No | Shown |
| Default member permissions | No | Empty field |
| Folder | Premature | Optional |
| Show variables button | Vague | Side action |

Then Step 3 (Actions): 70+ action types with no "start here" guidance, plus a hidden toggle between Workflow visual mode and BDFD code mode.

---

## 2. Friction Points (Ranked by Severity)

### P0 — Critical (Users quit here)

**F1. Cognitive overload on first command creation**
The CommandCreatePage dumps 8+ fields and jargon (integration types, contexts, permissions) on a user who just wants "when I type /hello, bot says Hi". No progressive disclosure. No "required vs optional" labeling.
→ ✅ Mitigated: Block editor uses progressive disclosure — MetadataBlock shows name/description/type, advanced settings collapsed by default. EntryPointBlock shows mode toggle clearly labelled.

**F2. No guided empty state in Commands tab**
When a bot has 0 commands, the user sees an empty list with a small FAB. No "Create your first command!" CTA, no visual nudge, no explanation of what a command IS.
→ ✅ Fixed (S2): Rich guided empty state with illustration, title, description, primary "Create a command" button, and secondary marketplace/sample-ping links.

**F3. Bottom sheet with 3 ambiguous choices**
The + button opens Command / Template / Folder. A novice doesn't know what "template" or "folder" means in this context. The first-use path should be a single obvious button.
→ ✅ Fixed (S2): Empty state uses a single primary button → direct command creation, no bottom sheet.

### P1 — High (Significant confusion)

**F4. Two editing modes with no explanation**
Workflow visual vs BDFD script. The toggle is buried in an ExpansionTile labeled "Code Advanced". If a novice accidentally switches to BDFD mode, they face a code editor with 500+ functions and zero on-screen help.
→ ✅ Mitigated: Block editor's EntryPointBlock labels the modes clearly ("Blocks" vs "BDFD") with descriptive subtitles.

**F5. Actions list is an unsorted supermarket**
70+ action types (respondWithMessage, banMember, createChannel, httpRequest, etc.) presented flat. No categories, no "simplest action first", no tooltips explaining when to use each.
→ ✅ Already existed (S3): Actions grouped into 10 categories with search.

**F6. No live preview during creation**
The user builds a command blind. They never see what the bot's response will look like in Discord until they save, start the bot, and test manually.
→ ✅ Fixed (S4): Discord-style preview bubble in message-producing actions, renders content with markdown + ((placeholder)) highlighting in real-time.

**F7. Onboarding is disconnected from reality**
The 5-step onboarding describes actions ("create a command", "start the bot") but provides no interactive path to actually do them. Steps 3-4 reference a bot card that doesn't exist yet.
→ ✅ Fixed: Step 2 has "Create my bot now" button → navigates to AppCreatePage, auto-advances to step 3 on return. Step 3 has "Create your first command" → opens the bot editor, auto-advances to step 4 on return.

### P2 — Medium (Frustrating but survivable)

**F8. No post-save guidance**
After saving a command, the user returns to the list. No "Your command is ready! Start your bot to test it" or "Invite your bot to a server". Silent return.
→ ✅ Fixed (S6): Post-save success sheet with start bot / invite to server / create another command.

**F9. Too many bot editor tabs for first use**
12 tabs (Home, Commands, Workflows, Variables, Scheduler, Webhooks, Guilds, Emojis, Settings, Logs, Stats, Debug Replay). 90% irrelevant to a novice making their first command.
→ ✅ Fixed (S7): Beginner mode auto-enables for bots with 0 commands, shows only Home/Commands/Settings. Toggle in sidebar.

**F10. Onboarding "Skip" loses all progress**
If a user skips at step 3, they restart from step 1 next time. No resume capability.
→ ✅ Fixed (S5): "Remind me later" button saves current step position, resumes on next launch.

### P3 — Low (Polish issues)

**F11. No step progress indicator in onboarding**
No "2/5" or dot indicators. Users don't know how many steps remain.
→ ✅ Fixed (S5): "Step X of 5" label + animated dot row on every onboarding step.

**F12. Sample /ping dialog is easy to dismiss**
The dialog offering the sample command appears once. If the user clicks "Skip" by accident, there's no way to get it back.
→ ✅ Fixed: "Add a sample /ping command" button permanently available in the commands empty state.

**F13. "Show variables" button is vague**
In the command editor step 1, there's a "Show variables" button that opens documentation. It's unclear what variables are or why the user should care at this point.
→ ✅ Mitigated: Tooltip updated to "Open variable documentation" in the active block editor (dead wizard code still has old label but is unreachable).

---

## 3. Proposed Solutions (No Code Yet)

### S1. Guided First Command Wizard (addresses F1, F4, F5)

Replace the full CommandCreatePage for first-time users with a simplified 3-step wizard:

**Step 1 — Name**
"Comment veux-tu appeler ta commande ?"
Single text field. No type selector, no integration types, no permissions. Just the name.

**Step 2 — What should the bot do?**
Three large cards:
- "Envoyer un message" (respondWithMessage) — the 80% case
- "Modérer un membre" (ban/kick/mute) — common use case
- "Personnalisé (avancé)" — opens the full editor

**Step 3 — Response content**
Based on step 2 selection:
- For "message": single text area + optional embed preview
- For "moderation": user selector + action type
- For "custom": redirect to full ActionsCard

**After save:** "Parameters avancés" button on the command card for users who want to add options, permissions, etc.

### S2. Guided Empty State (addresses F2, F3)

When commands list is empty:
- Large illustration (bot waving)
- "Crée ta première commande !"
- Short text: "Une commande permet à ton bot de répondre quand quelqu'un tape /quelquechose sur Discord"
- Single large button: "Créer une commande" (not a bottom sheet)
- Secondary link: "Ou pars d'un template du Marketplace"

### S3. Action Categories (addresses F5)

Reorganize the 70+ actions into clear categories with descriptions:

| Category | Actions | Description for novice |
|----------|---------|----------------------|
| "Messages" | reply, send, edit, delete, react | "Faire répondre ou envoyer des messages" |
| "Modération" | ban, kick, mute, warn, timeout | "Bannir, exclure ou sanctionner" |
| "Channels & Roles" | create, delete, modify channels/roles | "Gérer les salons et rôles" |
| "Embeds & Components" | embed builder, buttons, dropdowns | "Messages riches avec boutons et menus" |
| "Variables & Math" | get/set variable, math operations | "Stocker et calculer des données" |
| "Avancé" | HTTP, JSON, webhooks, canvas, code | "Pour les utilisateurs expérimentés" |

Each category collapsible, with the simplest actions at the top.

### S4. Live Preview (addresses F6)

Split-screen on desktop / collapsible panel on mobile:
- Left: editor
- Right: mock Discord chat showing the bot's response in real-time
- Updates as the user types the message content
- Shows embeds, buttons, images as they'll appear

For the first version: just preview the message content text in a Discord-like bubble.

### S5. Connected Onboarding (addresses F7, F10, F11)

Redesign onboarding as an interactive flow:

**Step 1 — Welcome** (keep as-is, add progress dots 1/5)

**Step 2 — Create your bot**
Keep the explanation BUT add a prominent button:
"Créer mon bot maintenant" → opens create_page.dart directly
Skip button stays for those who want to explore first.

**Step 3 — Your first command** (only if bot was created)
"Ajoute une commande à {botName}"
Button: "Créer /hello" → opens the simplified wizard (S1)

**Step 4 — Start your bot** (only if command was created)
"Démarre ton bot pour le tester !"
Button: "Démarrer" → starts the actual bot

**Step 5 — Success + Invite link**
"Ton bot est en ligne ! Invite-le sur ton serveur : [OAuth URL button]"
"Que faire ensuite ?" → links to docs, marketplace, settings

Progress saved at each step. Resume capability. Skip at any point preserves completed steps.

### S6. Post-Save Guidance (addresses F8)

After saving a command, show a success state with 3 actions:
- "Démarrer mon bot" (if not running)
- "Inviter sur un serveur" (OAuth URL)
- "Créer une autre commande"

Not a silent return to the list.

### S7. Beginner Mode (addresses F9)

Detect first-time usage (0 commands ever created OR onboarding just completed).

Show only 3 tabs: **Home / Commands / Settings**

Gradually reveal other tabs as the user:
- Creates their first workflow → Workflows tab appears
- First bot starts → Logs tab appears
- Uses scheduler trigger → Scheduler tab appears

Or: a "Mode débutant" toggle in Settings that shows/hides advanced tabs.

---

## 4. The Ideal Novice Journey (Target)

```
1. [App Open]
2. [Onboarding Step 1: Welcome + progress 1/5]
3. [Onboarding Step 2: "Create your bot" → REAL creation flow]
   → Token paste → bot saved → sample /ping offered
4. [Onboarding Step 3: "Add a command" → SIMPLIFIED WIZARD]
   → Name: hello → Action: Send message → Content: "Hi!" → LIVE PREVIEW
5. [Onboarding Step 4: "Start your bot" → REAL start button]
   → Bot starts → status: online
6. [Onboarding Step 5: Success + Invite URL + next steps]
7. [Home: bot card shows online status, guild count, /hello command listed]
```

Total time: under 3 minutes from app install to working bot.

---

## 5. Priority Implementation Order

| Priority | Solution | Effort | Impact | Status |
|----------|---------|--------|--------|--------|
| 1 | S1: Guided First Command Wizard | High | Eliminates the #1 drop-off point | ✅ Mitigated — block editor uses progressive disclosure (advanced fields collapsed by default, metadata block shows only name/desc/type initially) |
| 2 | S2: Guided Empty State | Low | Quick win, huge UX improvement | ✅ Done — rich empty state with illustration, CTA, and marketplace link |
| 3 | S6: Post-save Guidance | Low | Closes the loop, reduces "what now?" | ✅ Done — success sheet with start bot / invite / create another |
| 4 | S3: Action Categories | Medium | Makes actions discoverable | ✅ Already existed — 70+ actions grouped into 10 categories with search |
| 5 | S5: Connected Onboarding | High | Fixes the onboarding-to-action gap | ✅ Done — progress dots, "Open Dev Portal" button, "Remind me later" option |
| 6 | S4: Live Preview | Medium | Builds confidence during creation | ✅ Done — Discord-style preview bubble in message actions (respondWithMessage/sendMessage/sendDm/editInteractionMessage), renders content with markdown + ((placeholder)) highlighting in real-time |
| 7 | S7: Beginner Mode | Medium | Reduces cognitive load long-term | ✅ Done — auto-enables for bots with 0 commands, shows Home/Commands/Settings only, toggle in sidebar |

---

## 6. Key Metrics to Track

- % of new users who create a bot after onboarding (currently unknown)
- % of users who create at least 1 command after creating a bot
- Time from app install to first bot online
- Drop-off rate at CommandCreatePage Step 1
- Drop-off rate at CommandCreatePage Step 3 (Actions)
- % of users who successfully start their bot after creating a command
