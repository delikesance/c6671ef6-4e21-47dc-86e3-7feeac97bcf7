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
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH"
  '';
}
