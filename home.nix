{ pkgs, ... }:

with import <nixpkgs> {};
with builtins;
with lib;
with import <home-manager/modules/lib/dag.nix> { inherit lib; };

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
notmuch-apply = stdenv.mkDerivation {
  name = "notmuch-apply";
  phases = [ "installPhase" ];
  buildInputs = [ notmuch python36Packages.afew bash makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    install -m777 ${./mail/notmuch} $out/notmuch-apply
    sed -i s/notmuch/"${escape ["/"] (toString notmuch)}\/bin\/notmuch"/g $out/notmuch-apply
    sed -i s/afew/"${escape ["/"] (toString python36Packages.afew)}\/bin\/afew"/g $out/notmuch-apply
    makeWrapper $out/notmuch-apply $out/bin/notmuch-apply
  '';
};
msmtp-enqueue = stdenv.mkDerivation {
   name = "msmtp-enqueue";
   phases = [ "installPhase" ];
   buildInputs = [ msmtp makeWrapper ];
   installPhase = ''
     mkdir -p $out/bin
     makeWrapper ${msmtp}/bin/msmtpq $out/bin/msmtp-enqueue --set EMAIL_QUEUE_QUIET t
   '';
};
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
    pkgs.unstable.dropbox
    pkgs.zeal
    pkgs.atom
    pkgs.vscode
    pkgs.unstable.idea.idea-ultimate pkgs.jdk
    pkgs.gradle
    pkgs.tdesktop # Telegram 
    pkgs.unstable.slack
    pkgs.skypeforlinux
    pkgs.chromium pkgs.firefox
    pkgs.alacritty pkgs.termite pkgs.tmux
    pkgs.translate-shell
    pkgs.xss-lock
    pkgs.ansifilter # used to strip ANSI out in awesome extensions 
    pkgs.zim # desktop wiki
    pkgs.whois
    pkgs.youtube-dl
    pkgs.gimp pkgs.imagemagick
    pkgs.gcc
    (pkgs.rustChannels.stable.rust.override { extensions = ["rust-src"]; })
    pkgs.tla-plus.full
    pkgs.ghc pkgs.cabal-install pkgs.stack
    pkgs.haskellPackages.idris
    pkgs.tetex
    pkgs.funnelweb
    pkgs.plantuml
    pkgs.vagrant
    pkgs.gdb
    pkgs.gnumake
    pkgs.gpxsee
    pkgs.clips
    pkgs.mosh
    pkgs.emacs
    pkgs.nix-prefetch-git
    isync notmuch notmuch-apply msmtp msmtp-enqueue python36Packages.afew
    pkgs.jq
  ];


  programs.home-manager.enable = true;

  programs.git = {
    package = pkgs.gitAndTools.gitFull;
    enable = true;
    userName = "Yurii Rashkovskii";
    userEmail = "yrashk@gmail.com";
    signing = {
      key = "me@yrashk.com";
      signByDefault = true;
    };
  };

  programs.command-not-found.enable = true;

  programs.vim = {
    enable = true;
    extraConfig = builtins.readFile vim/vimrc;
    settings = {
       relativenumber = true;
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

  systemd.user.services.syndaemon = {
    Unit = {
      Description = "syndaemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.xorg.xf86inputsynaptics}/bin/syndaemon -K -i 0.5";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.fetchmail = {
    Unit = {
      Description = "fetch mail";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.isync}/bin/mbsync -a";
      ExecStartPost = "${notmuch-apply}/bin/notmuch-apply";
      # we want notmuch applied even if there was a problem
      SuccessExitStatus = "0 1";
    };
  };

  systemd.user.timers.fetchmail = {
    Unit = {
      Description = "regular fetch mail";
    };
    Timer = {
      Unit = "fetchmail.service";
      AccuracySec = "10s";
      OnCalendar = "*:0/15";
    };
    Install = {
      WantedBy = [ "timers.target" ];
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
       abbr mc 'env TERM=linux mc'
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

  ".config/awesome/rc.lua".source = substituteAll ((import ./awesome/substitutions.nix { inherit lib; })
                                                   // { src = awesome/rc.lua; });

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

  # spacemacs
  ".emacs.d" = {
     source = fetchFromGitHub {
       owner = "syl20bnr";
       repo = "spacemacs";
       rev = "5ec172d7bdbb71d84d0189a9751665f3cb9977af";
       sha256 = "0zy0n0sc691q7gbvf1fs6wg3p53gza1nq1awmja30mj86mpkdnjz";
     };
     recursive = true;
  }; 
  ".spacemacs".source = substituteAll ( (import ./spacemacs-substitutions.nix { inherit lib; }) 
                                        // { src =./spacemacs; });
  
  ".mbsyncrc".source = mail/mbsyncrc;
  ".notmuch-config".source = mail/notmuch-config;
  ".config/afew/config".source = mail/afew-config;
  ".mailrc".text = ''
  set sendmail="${msmtp}/bin/msmtp";
  '';
  ".msmtprc".text = ''
  defaults
  port 587
  tls on
  tls_trust_file ${cacert}/etc/ssl/certs/ca-bundle.crt
  account default
  host mail.etceteralabs.com
  from me@yrashk.com
  auth on
  user me@yrashk.com
  passwordeval ${gnupg}/bin/gpg2  --no-tty -q -d ${mail/pass-yrashk.gpg}
  account gmail
  host smtp.gmail.com
  from yrashk@gmail.com
  auth on
  user yrashk@gmail.com
  passwordeval ${gnupg}/bin/gpg2  --no-tty -q -d ${mail/pass-gmail.gpg}
  '';


  ".IntelliJIdea2017.3/config" = {
     source = ./idea-config;
     recursive = true;
  };

  ".ssh/id_rsa.pub".source = ./id_rsa.pub;

  };

  home.activation.copyIdeaKey = dagEntryAfter ["writeBoundary"] ''
      install -D -m600 ${./private/idea.key} $HOME/.IntelliJIdea2017.3/config/idea.key
  '';

  home.activation.copySSHKey = dagEntryAfter ["writeBoundary"] ''
      install -D -m600 ${./private/id_rsa} $HOME/.ssh/id_rsa
  '';

  home.activation.authorizedKeys = dagEntryAfter ["writeBoundary"] ''
      install -D -m600 ${./id_rsa.pub} $HOME/.ssh/authorized_keys
  '';

  home.activation.mailPasswords = dagEntryAfter ["writeBoundary"] ''
     mkdir -p $HOME/.mail/gmail
     install -m600 ${./mail/pass-yrashk} $HOME/.mail/pass-yrashk
     install -m600 ${./mail/pass-gmail} $HOME/.mail/pass-gmail
  '';

  

}
