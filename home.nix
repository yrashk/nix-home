{ pkgs, ... }:

with import <nixpkgs> {};
with builtins;
with lib;
with import <home-manager/modules/lib/dag.nix> { inherit lib; };

let
notmuch-apply = stdenv.mkDerivation {
  name = "notmuch-apply";
  phases = [ "installPhase" ];
  buildInputs = [ notmuch afew bash makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    install -m777 ${./mail/notmuch} $out/notmuch-apply
    sed -i s/notmuch/"${escape ["/"] (toString notmuch)}\/bin\/notmuch"/g $out/notmuch-apply
    sed -i s/afew/"${escape ["/"] (toString afew)}\/bin\/afew"/g $out/notmuch-apply
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
sit = stdenv.mkDerivation {
   name = "sit";
   src = ./.;
   phases = [ "installPhase" ];
   installPhase = ''
     mkdir -p $out/bin
     cp ${./sit.sh} $out/bin/sit
     cp ${./sit-web.sh} $out/bin/sit-web
   '';
};
inkscapeIsometric = stdenv.mkDerivation {
   name = "inkscape-isometric-projection";
   src = fetchFromGitHub {
      owner = "jdhoek";
      repo = "inkscape-isometric-projection";
      rev = "v1.1";
      sha256 = "1vj98bci9fsf08bmp05pxzvcm9wvlrmqvms4piz6iy09m3jpkcli";
   };
   installPhase = ''
     mkdir -p $out
     cp isometric_projection.* $out/
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
    (pkgs.unstable.zoom-us.overrideAttrs (super: {
      postInstall = ''
        ${super.postInstall}
        wrapProgram $out/bin/zoom-us --set LIBGL_ALWAYS_SOFTWARE 1
      '';
    }))
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
    pkgs.ghc pkgs.cabal-install pkgs.stack
    pkgs.haskellPackages.idris
    pkgs.pandoc pkgs.texlive.combined.scheme-tetex
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
    isync notmuch notmuch-apply msmtp msmtp-enqueue afew
    pkgs.jq
    sit
    pkgs.binutils-unwrapped
    pkgs.unstable.inkscape
    inkscapeIsometric
    pkgs.unstable.astroid
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
      "rust-vim"
    ];
  };

  services.kbfs.enable = true;

  services.syncthing.enable = true;

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

  ".config/inkscape" = {
    source = ./inkscape;
    recursive = true;
  };

  ".config/inkscape/extensions/isometric_projection.inx".source = "${inkscapeIsometric}/isometric_projection.inx";
  ".config/inkscape/extensions/isometric_projection.py".source = "${inkscapeIsometric}/isometric_projection.py";
  
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

  ".config/awesome/backgrounds".source = ./backgrounds;

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
       rev = "1f93c05";
       sha256 = "1x0s5xlwhajgnlnb9mk0mnabhvhsf97xk05x79rdcxwmf041h3fd";
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

  ".config/astroid/config" = {
    text = toJSON (import ./mail/astroid.nix {
      inherit pkgs;
    });
  };

  ".IntelliJIdea2018.1/config" = {
     source = ./idea-config;
     recursive = true;
  };

  ".atom/config.json" = {
     text = toJSON (import ./atom.nix);
  };

  ".ssh/id_rsa.pub".source = ./id_rsa.pub;

  ".stack/config.yaml".text = ''
    templates:
      params:
        author-email: me@yrashk.com
        author-name: Yurii Rashkovskii
        github-username: yrashk
  '';


  };

  home.activation.copyIdeaKey = dagEntryAfter ["writeBoundary"] ''
      install -D -m600 ${./private/idea.key} $HOME/.IntelliJIdea2018.1/config/idea.key
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
