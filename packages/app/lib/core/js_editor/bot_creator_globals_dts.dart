/// Type declarations exposed to Bot Creator JavaScript command scripts.
const botCreatorGlobalsDts = '''
/** Bot Creator script globals — available in every command handler. */

interface BotCreatorInteraction {
  readonly commandName: string;
  reply(
    content: string | { content: string; ephemeral?: boolean },
  ): Promise<unknown>;
  editReply(
    content: string | { content: string; ephemeral?: boolean },
  ): Promise<unknown>;
  deferReply(options?: { ephemeral?: boolean }): Promise<unknown>;
  followUp(
    content: string | { content: string; ephemeral?: boolean },
  ): Promise<unknown>;
  options: {
    getString(name: string, required?: boolean): string | null;
    getInteger(name: string, required?: boolean): number | null;
    getBoolean(name: string, required?: boolean): boolean | null;
    getUser(name: string): unknown;
    getChannel(name: string): unknown;
    getRole(name: string): unknown;
  };
}

interface BotCreatorMessage {
  readonly content: string;
  readonly author: { readonly id: string; readonly username: string };
  reply(content: string): Promise<unknown>;
}

declare const interaction: BotCreatorInteraction | undefined;
declare const message: BotCreatorMessage | undefined;
declare const client: { readonly user: { readonly id: string; readonly username: string } | null };
declare const guild: { readonly id: string; readonly name: string } | null;
declare const channel: { readonly id: string; readonly name: string | null } | null;
declare const member: unknown;
declare const config: Record<string, unknown>;
declare const variables: Record<string, unknown>;
declare const webhook: {
  readonly path: string;
  readonly payload: unknown;
  readonly headers: Record<string, string>;
} | null;
declare function require(moduleId: string): unknown;
declare const fetch: typeof globalThis.fetch;
declare const console: Console;
''';
