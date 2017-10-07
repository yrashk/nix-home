{
  allowUnfree = true;
  chromium = {
     enablePepperFlash = true;
  };
  packageOverrides = pkgs: rec {
      unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {
          config = {
              allowUnfree = true;
          };
      };
      home-manager = import ./home-manager { inherit pkgs; };
  };
}
