{
  allowUnfree = true;
  packageOverrides = pkgs: rec {
      unstable = import (fetchTarball https://nixos.org/channels/nixos-unstable/nixexprs.tar.xz) {
          config = {
              allowUnfree = true;
          };
      };
      nixpkgs = import (fetchTarball https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz) {
          config = {
              allowUnfree = true;
          };
      };
      home-manager = import ./home-manager { inherit pkgs; };
  };
}
