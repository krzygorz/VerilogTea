{ pkgs ? import <nixpkgs> {} }:
  with pkgs;
  let
  nextpnr_gui = nextpnr.override { enableGui = true; qtbase = qt5.qtbase; wrapQtAppsHook = qt5.wrapQtAppsHook; };
  in
  mkShell {
    nativeBuildInputs = [
        verilog yosys nextpnr_gui gtkwave
        xdot graphviz 
        delta
    ];
}
