{ pkgs ? import <nixpkgs> {} }:

let
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
    export PATH="/nix/store/ssvifqky480dqd5kv5dvcjvn3drfhiw7-flutter-wrapped-3.47.0-sdk-links/bin:$PATH"
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH"
  '';
}
