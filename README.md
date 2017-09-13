# Instllation

```shell
$ git submodule init
$ git submodule update
$ ln -s `pwd` ~/.config/nixpkgs
$ nix-env -f '<nixpkgs>' -iA home-manager
```

# Using Rust

```shell
# A channel can be "nightly", "beta", "stable", "\d{1}.\d{1}.\d{1}", or "\d{1}.\d{2\d{1}".
$ nix-shell --command fish -p rustChannels.stable.rust
```
