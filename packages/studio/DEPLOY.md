# Déployer le Studio

Le Studio est un site statique (build web Flutter) servi par nginx. L'image est
publiée par la CI (`.github/workflows/studio.yml`) à chaque push sur `dev` ou
`main`/`master` qui touche `packages/studio/`.

| Environnement | Branche | Site | API figée dans le build | Image GHCR |
|---|---|---|---|---|
| Staging | `dev` | `https://studio-dev.bot-creator.fr` | `https://dev.bot-creator.fr` | `bot-creator-studio:dev-<sha>`, `:dev` |
| Production | `main` / `master` | `https://studio.bot-creator.fr` | `https://api.bot-creator.fr` | `bot-creator-studio:sha-<sha>`, `:latest` |

L'URL de l'API est **figée à la compilation** : une image par environnement, on
ne peut pas pointer l'image de staging vers la production en changeant une
variable.

## Checklist de mise en ligne

1. **DNS + certificat** : `studio-dev.bot-creator.fr` et `studio.bot-creator.fr`
   (un nom à un seul niveau est couvert par `*.bot-creator.fr`).
2. **Portail Discord** : ajouter comme URI de retour OAuth
   `https://studio-dev.bot-creator.fr/` et `https://studio.bot-creator.fr/`
   (avec la barre finale, c'est ce que le Studio envoie).
3. **Manager** : `CORS_ALLOWED_ORIGINS` contient l'origine du Studio (déjà dans
   `docker-compose.staging.yml` / `docker-compose.prod.yml`).
4. **Hébergement** : lancer l'image, port `8080`, derrière le reverse proxy en
   HTTPS. Sonde de santé : `GET /healthz`.

## Lancer l'image à la main

```bash
docker run --rm -p 8080:8080 ghcr.io/<owner>/bot-creator-studio:dev
```

## Construire en local

```bash
cd packages/studio
flutter build web --release --wasm --dart-define=STUDIO_API_URL=https://dev.bot-creator.fr
docker build -t bot-creator-studio .
```

## Ce que la CI vérifie avant de publier

Elle construit l'image, la lance et contrôle : la sonde de santé, le repli vers
`index.html` (le retour OAuth arrive sur `/?code=…&state=…`), les en-têtes de
sécurité, le cache désactivé sur les fichiers d'entrée (sinon une mise à jour
n'arrive jamais chez ceux qui ont déjà ouvert le site) et le type MIME de
`main.dart.wasm`. Si l'un saute, l'image n'est pas publiée.
