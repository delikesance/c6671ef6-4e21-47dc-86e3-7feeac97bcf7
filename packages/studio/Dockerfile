# Image du Studio : nginx qui sert le build web Flutter déjà compilé.
#
# POURQUOI PAS DE COMPILATION DANS L'IMAGE : l'URL de l'API est figée à la
# compilation (--dart-define=STUDIO_API_URL=…) et le build se fait dans la CI,
# où le SDK Flutter est déjà en cache. L'image ne contient donc que des fichiers
# statiques : elle est petite, sans compilateur, et identique à ce qui a été
# testé.
#
# Construire (depuis packages/studio) :
#   flutter build web --release --wasm --dart-define=STUDIO_API_URL=https://dev.bot-creator.fr
#   docker build -t bot-creator-studio .
#   docker run --rm -p 8080:8080 bot-creator-studio
FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html

# nginx-unprivileged écoute sur 8080 et tourne sans privilèges.
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
