# Bot Creator Shared Engine

The core bot execution engine for the Bot Creator mono-repo. This library provides the BDFD transpiler, interaction handling, and runtime variable resolution used by both the Flutter app (`packages/app`) and the CLI runner (`packages/runner`).

## Features

- **BDFD Transpiler**: High-performance Lexer, Parser, and Transpiler for BDFD scripts.
- **Bot Engine**: Centralized orchestration for bot sessions, events, and workflows.
- **Generic Storage**: Abstract `BotDataStore` interface allowing for any database backend.
- **Rich Metadata**: Automated extraction of Discord metadata (Guild, Channel, Member, User) into runtime variables.
- **Action System**: Extensible action handler architecture for custom bot functionality.

## Usage

This package is a workspace member of the `bot-creator` repository. From the repo root:

```bash
flutter pub get
```

`packages/app` and `packages/runner` depend on it via:

```yaml
dependencies:
  bot_creator_shared:
    path: ../shared
```

## Internal Architecture

- `lib/engine`: Core BotEngine and session management.
- `lib/utils/bdfd_*`: Lexing, parsing, and transpilation logic.
- `lib/actions`: Handlers for Discord interactions and bot actions.
- `lib/bot`: Data models and storage interfaces.

---
© 2026 Jeremy. Licensed under the [GNU Lesser General Public License v3.0 or later](https://www.gnu.org/licenses/lgpl-3.0.en.html).
