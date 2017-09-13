{
  allowUnfree = true;
  packageOverrides = pkgs: rec {
      unstable = import <nixos-unstable> {
          config = {
              allowUnfree = true;
          };
      };
      home-manager = import ./home-manager { inherit pkgs; };
  };
}
