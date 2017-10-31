{
  allowUnfree = true;
  chromium = {
     enablePepperFlash = true;
  };
  packageOverrides = pkgs: with pkgs; rec {
      unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {
          config = {
              allowUnfree = true;
          };
      };

      # https://github.com/NixOS/nixpkgs/issues/18640
      tla-plus = callPackage pkgs/tla-plus { inherit pkgs; };
      dummy-wget = callPackage pkgs/dummy-wget { inherit pkgs; };
      polyml-5-4 = callPackage pkgs/polyml-5-4 {};
      isabelle2011-1 = callPackage pkgs/isabelle2011-1 {
          inherit (pkgs) stdenv fetchurl nettools perl;
          inherit (pkgs.emacs25Packages) proofgeneral;
          polyml = polyml-5-4;
      };
  };
}
