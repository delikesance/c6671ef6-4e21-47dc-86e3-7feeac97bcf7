{ pkgs ? import <nixpkgs> {} }:

let
  # Bibliotheques que le build Linux de l'app lie reellement. GTK vient du
  # moteur Flutter, le reste des plugins : `desktop_webview_window` exige
  # WebKitGTK (il cherche webkit2gtk-4.1 puis, en repli, 4.0 — qui n'existe
  # PLUS dans nixpkgs, d'ou l'echec de build quand cette liste l'oublie).
  libraries = with pkgs; [
    gtk3
    glib
    pango
    cairo
    gdk-pixbuf
    atk
    harfbuzz
    libepoxy
    libxkbcommon
    libx11
    sysprof
    fontconfig
    freetype
    sqlite
    webkitgtk_4_1
    libsoup_3
  ];
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
    ninja
    clang
  ];

  buildInputs = libraries;

  shellHook = ''
    # LD_LIBRARY_PATH : le binaire de debug lie les .so des plugins.
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH"

    # Le SDK Flutter utilise sur cette machine vit dans ~/development/flutter ;
    # on le met DEVANT pour que `flutter run -d linux` utilise la version avec
    # laquelle le pubspec.lock a ete resolu (celle de nixpkgs peut differer).
    if [ -x "$HOME/development/flutter/bin/flutter" ]; then
      export PATH="$HOME/development/flutter/bin:$PATH"
    fi
  '';
}
