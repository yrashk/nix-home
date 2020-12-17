{
  allowUnfree = true;
  chromium = {
#     enablePepperFlash = true;
  };
  packageOverrides = pkgs: with pkgs; rec {
      unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {
          config = {
              allowUnfree = true;
          };
      };

       kdenlive = pkgs.kdenlive.overrideAttrs (oldAttrs: rec {
         postInstall = ''
          wrapProgram $out/bin/kdenlive --prefix FREI0R_PATH : ${pkgs.frei0r}/lib/frei0r-1
        '';
        nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [ pkgs.makeWrapper ];
     });

      # https://github.com/NixOS/nixpkgs/issues/18640
      tla-plus = callPackage pkgs/tla-plus { inherit pkgs; };
      dummy-wget = callPackage pkgs/dummy-wget { inherit pkgs; };
      polyml-5-4 = callPackage pkgs/polyml-5-4 {};
      isabelle2011-1 = callPackage pkgs/isabelle2011-1 {
          inherit (pkgs) stdenv fetchurl nettools perl;
          inherit (pkgs.emacs25Packages) proofgeneral;
          polyml = polyml-5-4;
      };
      skypeforlinux = unstable.skypeforlinux;
      mmark = callPackage ./mmark {  };
      xml2rfc = callPackage ./xml2rfc { };
      sikulix = callPackage ./sikulix.nix { };
      elixir = unstable.elixir;
  };
}

