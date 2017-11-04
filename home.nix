{ pkgs, ... }:

with import <nixpkgs> {};
with builtins;
with lib;
with import home-manager/modules/lib/dag.nix { inherit lib; };

let
sanitiseName = stringAsChars (c: if elem c (lowerChars ++ upperChars)
                                    then c else "");
fetchGitHashless = args: stdenv.lib.overrideDerivation
  # Use a dummy hash, to appease fetchgit's assertions
    (fetchgit (args // { sha256 = hashString "sha256" args.url; }))

      # Remove the hash-checking
        (old: {
         outputHash     = null;
         outputHashAlgo = null;
         outputHashMode = null;
         sha256         = null;
         });
latestGitCommit = { url, ref ? "HEAD" }:
     runCommand "repo-${sanitiseName ref}-${sanitiseName url}"
     {
        # Avoids caching. This is a cheap operation and needs to be up-to-date
        version = toString currentTime;
         # Required for SSL
         GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";

          buildInputs = [ git gnused ];
     }
     ''
     REV=$(git ls-remote "${url}" "${ref}") || exit 1

     printf '"%s"' $(echo "$REV"        |
         head -n1           |
         sed -e 's/\s.*//g' ) > "$out"
     '';
fetchLatestGit = { url, ref ? "HEAD" }@args:
    with { rev = import (latestGitCommit { inherit url ref; }); };
    fetchGitHashless (removeAttrs (args // { inherit rev; }) [ "ref" ]);
sourceDirectory = path: mapAttrs
  (name: value: 
    { source = path + "/${name}"; })
  (readDir path);
in         
{
  home.packages = [
    pkgs.unzip
    pkgs.wget
    pkgs.gnupg
    pkgs.wpa_supplicant_gui
    pkgs.blackbox pkgs.keybase
    pkgs.udisks
    pkgs.mc
    pkgs.nix-repl
    pkgs.rlwrap
    pkgs.xorg.xdpyinfo # awesome/foggy seems to want it
    pkgs.vlc
    pkgs.shutter # Screenshots
    pkgs.zathura # document viewer
    pkgs.htop
    pkgs.bc
    pkgs.ncdu # Disk space usage analyzer
    pkgs.ripgrep # rg, fast grepper
    pkgs.rtv # Reddit
    pkgs.dropbox
    pkgs.zeal
    pkgs.atom
    pkgs.vscode
    pkgs.idea.idea-ultimate pkgs.jdk
    pkgs.gradle
    pkgs.tdesktop # Telegram 
    pkgs.skype
    pkgs.chromium pkgs.firefox
    pkgs.alacritty pkgs.termite pkgs.tmux
    pkgs.translate-shell
    pkgs.xss-lock
    pkgs.ansifilter # used to strip ANSI out in awesome extensions 
    pkgs.zim # desktop wiki
    pkgs.whois
    pkgs.youtube-dl
    pkgs.gimp
    pkgs.gcc
    pkgs.rustChannels.stable.rust 
    pkgs.tla-plus.full
    pkgs.ghc pkgs.cabal-install pkgs.stack
    pkgs.haskellPackages.idris
    pkgs.tetex
    pkgs.funnelweb
    pkgs.plantuml
    pkgs.vagrant
  ];


  programs.home-manager.enable = true;

  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "Yurii Rashkovskii";
    userEmail = "yrashk@gmail.com";
  };

  programs.command-not-found.enable = true;

  programs.vim = {
    enable = true;
    extraConfig = builtins.readFile vim/vimrc;
    settings = {
       number = true;
    };
    plugins = [
      "idris-vim"
      "sensible"
      "vim-airline"
      "The_NERD_tree" # file system explorer
      "fugitive" "vim-gitgutter" # git 
    ];
  };

  services.udiskie = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 1800;
  };

  systemd.user.services.dropbox = {
    Unit = {
      Description = "Dropbox";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Restart = "on-failure";
      RestartSec = 1;
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      Environment = "QT_PLUGIN_PATH=/run/current-system/sw/${pkgs.qt5.qtbase.qtPluginPrefix}";
     };

    Install = {
        WantedBy = [ "graphical-session.target" ];
    };

  };

  home.file = { 
  
  ".config/alacritty/alacritty.yml".source = ./alacritty.yml;

  ".config/termite/config".source = ./termite.config;


  ".tmux.conf" = {
   text = ''
   set-option -g default-shell /run/current-system/sw/bin/fish
   set-window-option -g mode-keys vi
   '';
  };

  ".config/fish/config.fish" = {
    text = ''  
    set -x GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye > /dev/null
    set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh
    set -x EDITOR vim
    if status --is-interactive
       set -g fish_user_abbreviations
       abbr h 'home-manager switch'
       abbr r 'sudo nixos-rebuild switch'
       abbr gvim vim -g
    end
    function __fish_command_not_found_handler --on-event fish_command_not_found
       command-not-found $argv[1]
    end
    '';
  };


  ".config/fish/functions/nixsh.fish".source = fish/nixsh.fish;

  ".config/fish/functions/fish_prompt.fish".source = fish/fish_prompt.fish;

  ".config/zim/preferences.conf".source = zim/preferences.conf;

  ".config/zim/style.conf".source = zim/style.conf;

  ".local/share/applications/defaults.list" = {
     text = ''
     [Default Applications]
     application/pdf=zathura.desktop
     '';
  };

  ".config/awesome/rc.lua".source = awesome/rc.lua; 

  ".config/awesome/theme.lua".source = awesome/theme.lua; 

  ".config/awesome/backgrounds".source = fetchLatestGit {
     url = "https://github.com/yrashk/backgrounds";
  };

  ".config/awesome/foggy".source = fetchFromGitHub {
     owner = "k3rni";
     repo = "foggy";
     rev = "fd76b28";
     sha256 = "0lfm7kczgdlzfcc14qj8539y679lf5qcydz0xv72szn7h9wzaaiz";
  };

  ".config/awesome/battery-widget".source = fetchFromGitHub {
     owner = "deficient";
     repo = "battery-widget";
     rev = "4152487";
     sha256 = "14p4c37m6s88d2dkgkv1b7xk2paj06cfdadphmhx2m2gr7c9c01f";
  };

  ".config/awesome/volume-control".source = fetchFromGitHub {
     owner = "deficient";
     repo = "volume-control";
     rev = "137b19e";
     sha256 = "1xsxcmsivnlmqckcaz9n5gc4lgxpjm410cfp65s0s4yr5x2y0qhs";
  };

  ".config/awesome/calendar".source = fetchFromGitHub {
     owner = "yrashk";
     repo = "calendar";
     rev = "1ed19a3";
     sha256 = "1xfax18y4ddafzmwqp8qfs6k34nh163bwjxb7llvls5hxr79vr9s";
  };

  ".config/awesome/net_widgets".source = fetchFromGitHub {
     owner = "pltanton";
     repo = "net_widgets";
     rev = "82d1ecd";
     sha256 = "13c9kcc8fj4qjsbx14mfdhav5ymqxdjbng6lpnc5ycgfpyap2xqf";
  };

  } //
  # IntelliJ IDEA
  (mapAttrs' (name: value: nameValuePair (".IntelliJIdea2017.2/config/" + name) value)
   (sourceDirectory ./idea-config)); 

  home.activation.copyIdeaKey = dagEntryAfter ["writeBoundary"] ''
      install -D -m600 ${./private/idea.key} $HOME/.IntelliJIdea2017.2/config/idea.key
  '';

}
