# Déployer le Studio

Le Studio est un site statique (build web Flutter) servi par nginx. L'image est
publiée par la CI (`.github/workflows/studio.yml`) à chaque push sur `dev` ou
`main`/`master` qui touche `packages/studio/`.

| Environnement | Branche | Site | API figée dans le build | Étiquettes de l'image GHCR |
|---|---|---|---|---|
| Staging | `dev` | `https://studio-dev.bot-creator.fr` | `https://dev.bot-creator.fr` | `dev-<sha>`, `dev`, `<x.y.z>-dev.<n°>` |
| Production | `main` / `master` | `https://studio.bot-creator.fr` | `https://api.bot-creator.fr` | `<x.y.z>`, `sha-<sha>`, `latest` |

## Versions

Le Studio a sa propre version SemVer, indépendante de celle de l'app (tags Git
`studio-vX.Y.Z` ; `vX.Y.Z` reste celui de l'app). Sur `main`/`master`, la CI :

1. déduit la montée des Conventional Commits qui touchent `packages/studio` et
   `packages/ui` depuis le dernier tag `studio-v*` (`!:` ou `BREAKING CHANGE` →
   majeure, `feat` → mineure, le reste → correctif ; la première version est celle
   du `pubspec.yaml` du Studio) ;
2. pose le tag et la release GitHub (jamais marquée « latest » : celle de l'app le
   reste) ;
3. publie l'image sous `<x.y.z>`, avec les labels OCI `version` et `revision`, et
   compile le site avec cette version : `/version.json` du site déployé la donne.

Un lancement manuel (`workflow_dispatch`) accepte un `bump` pour forcer le type de
montée. Sur `dev`, l'image porte `<dernière version>-dev.<n°>` en plus de `dev`.

**Kubernetes** : `latest` et `dev` sont mobiles. Pour figer un environnement sur une
version, mettre cette version dans `newTag` de l'overlay
(`kube-infra/overlays/<env>/kustomization.yaml`, image
`ghcr.io/<owner>/bot-creator-studio`) ; pour savoir ce qui tourne :
`curl https://studio.bot-creator.fr/version.json`.

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
n'arrive jamais chez ceux qui ont déjà ouvert le site), que `/version.json` porte
bien la version publiée, et le type MIME de `main.dart.wasm`. Si l'un saute, l'image n'est pas publiée.
