# Native documentation

Guide and Bot Creator documentation tabs use the public Vitrine API directly,
without Manager credentials or an MCP transport. discord.js remains in the
existing WebView (or the platform's external-browser fallback).

## Public API

- `GET https://bot-creator.fr/api/native-guides-index.json`: blog guides.
- `GET https://bot-creator.fr/api/native-docs-index.json`: function/reference pages.
- `GET https://bot-creator.fr/api/native/{guides|docs}/{id}.md`: portable Markdown.

Each index entry includes id, name, description, category, mode, compatibility
status, locale, canonical website URL, Markdown URL and SHA-256 content revision.
Nested documentation paths retain distinct identities even when filenames match.

The Jekyll generator resolves Liquid against the page/site payload and converts
presentation HTML to Markdown. Layouts, CSS, scripts, SVG decorations and iframes
are not part of the native output; code blocks, tables, links and images remain.
Mermaid diagrams are readable source code, not interactive diagrams. Existing MCP
indexes and raw Markdown endpoints are unchanged.

## App behavior

Tabs load on first selection. Search matches names, descriptions, ids and
categories locally; it does not claim full-text search of unvisited articles.
Category/mode filters and loaded tab state survive tab switches. Articles support
text selection, code copying, a heading menu and internal article/heading links.
Website-only pages open externally; the existing privacy-policy view is unchanged.
The token tutorial resolves natively, including legacy URLs without `.html`.

The shared repository coalesces duplicate requests. Public indexes have a one-hour
TTL, article bodies a one-day TTL. The persistent cache is limited to 64 entries
and 4 MiB; each HTTP response is limited to 1 MiB with a 12-second deadline.
Cache identity includes the article revision, and content hashes are verified.
Refresh bypasses TTL; if a fetch fails, a previously validated cached entry is
shown with a cached/offline indicator. An uncached failure offers retry and the
website link. No credentials or private bot state are stored in this cache.

## Verification and rollout

Run `bundle exec ruby tests/native_documentation_test.rb` and
`JEKYLL_ENV=production bundle exec jekyll build` in Vitrine.
Run Flutter tests `documentation_repository_test.dart`,
`native_documentation_view_test.dart`, `documentation_hub_test.dart` and
`documentation_webview_support_test.dart` in `packages/app`.

Publish Vitrine's generated endpoints before releasing the new App. Until the
API is deployed, an uncached reader shows the retry/browser fallback. A push
alone does not confirm that these endpoints are live.
