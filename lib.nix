# Imports the iohk-nix library.
# The version can be overridden for debugging purposes by setting
# NIX_PATH=iohk_nix=/path/to/iohk-nix
let
  iohkNix = import (
  let try = builtins.tryEval <iohk_nix>;
  in if try.success
  then builtins.trace "using host <iohk_nix>" try.value
  else
    let
      spec = builtins.fromJSON (builtins.readFile ./nix/iohk-nix-src.json);
    in builtins.fetchTarball {
      url = "${spec.url}/archive/${spec.rev}.tar.gz";
      inherit (spec) sha256;
    }) { nixpkgsJsonOverride = ./nix/nixpkgs-src.json; };
  arionPkgs = import (let
      spec = builtins.fromJSON (builtins.readFile ./nix/arion-src.json);
    in builtins.fetchTarball {
      url = "${spec.url}/archive/${spec.rev}.tar.gz";
      inherit (spec) sha256;
    }) {};
  pkgs = iohkNix.pkgs;
  rustPkgs = iohkNix.rust-packages.pkgs;
  makeSnap = pkgs.callPackage ./nix/make-snap.nix {};
  snapcraft = pkgs.callPackage ./nix/snapcraft.nix {};
in
{
  inherit iohkNix rustPkgs arionPkgs makeSnap snapcraft;
  pkgs = rustPkgs.pkgs.extend (self: super: {
    libuuid = if self.stdenv.isLinux
      then super.runCommand "libuuid" {} ''
        mkdir $out/bin -pv
        cp -v ${super.utillinuxMinimal}/bin/uuidgen $out/bin/uuidgen
      ''
      else super.runCommand "libuuid" {} ''
        mkdir $out/bin -pv
        ln -sv /usr/bin/uuidgen $out/bin/uuidgen
      '';
  });
  inherit (pkgs) lib;
}
