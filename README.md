$ git submodule init
$ git submodule update
$ ln -s `pwd` ~/.config/nixpkgs
$ nix-env -f '<nixpkgs>' -iA home-manager
