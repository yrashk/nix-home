{ pkgs, ... }:

with import <nixpkgs> {};

{
  home.packages = [
    pkgs.unzip
    pkgs.wget
    pkgs.gnupg
    pkgs.blackbox pkgs.keybase
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
    pkgs.idea.idea-ultimate pkgs.jdk
    pkgs.gradle
    pkgs.tdesktop # Telegram 
    pkgs.skype
    pkgs.chromium
    pkgs.alacritty pkgs.termite pkgs.tmux
    pkgs.translate-shell
    pkgs.xss-lock
    pkgs.ansifilter # used to strip ANSI out in awesome extensions 
    pkgs.zim # desktop wiki
    pkgs.whois
    pkgs.youtube-dl
    pkgs.gimp
    pkgs.tla-plus.full
  ];


  programs.git = {
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
      "sensible"
      "vim-airline"
      "The_NERD_tree" # file system explorer
      "fugitive" "vim-gitgutter" # git 
    ];
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
      ExecStart = "${pkgs.unstable.dropbox}/bin/dropbox";
      Environment = "QT_PLUGIN_PATH=/run/current-system/sw/${pkgs.qt5.qtbase.qtPluginPrefix}";
     };

    Install = {
        WantedBy = [ "graphical-session.target" ];
    };

  };

  home.file.".config/alacritty/alacritty.yml" = {
    text = builtins.readFile ./alacritty.yml;
  };

  home.file.".config/termite/config" = {
    text = builtins.readFile ./termite.config;
  };


  home.file.".tmux.conf" = {
   text = ''
   set-option -g default-shell /run/current-system/sw/bin/fish
   set-window-option -g mode-keys vi
   '';
  };

  home.file.".config/fish/config.fish" = {
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


  home.file.".config/fish/functions/nixsh.fish" = {
     text = builtins.readFile fish/nixsh.fish;
  };

  home.file.".config/fish/functions/fish_prompt.fish" = {
     text = builtins.readFile fish/fish_prompt.fish;
  };

  home.file.".config/zim/preferences.conf" = {
     text = builtins.readFile zim/preferences.conf;
  };

  home.file.".config/zim/style.conf" = {
     text = builtins.readFile zim/style.conf;
  };

  home.file.".config/awesome/rc.lua" = {
     text = builtins.readFile awesome/rc.lua; 
  };

  home.file.".config/awesome/theme.lua" = {
     text = builtins.readFile awesome/theme.lua; 
  };

  home.file.".config/awesome/backgrounds".source = fetchFromGitHub {
     owner = "yrashk";
     repo = "backgrounds";
     rev = "78969fe";
     sha256 = "1n3yphisyj031rr4y2r12d2iv2v4cb8dk8krkbi0b4p2l6jp4zk7";
  };

  home.file.".config/awesome/foggy".source = fetchFromGitHub {
     owner = "k3rni";
     repo = "foggy";
     rev = "fd76b28";
     sha256 = "0lfm7kczgdlzfcc14qj8539y679lf5qcydz0xv72szn7h9wzaaiz";
  };

  home.file.".config/awesome/battery-widget".source = fetchFromGitHub {
     owner = "deficient";
     repo = "battery-widget";
     rev = "4152487";
     sha256 = "14p4c37m6s88d2dkgkv1b7xk2paj06cfdadphmhx2m2gr7c9c01f";
  };

  home.file.".config/awesome/volume-control".source = fetchFromGitHub {
     owner = "deficient";
     repo = "volume-control";
     rev = "137b19e";
     sha256 = "1xsxcmsivnlmqckcaz9n5gc4lgxpjm410cfp65s0s4yr5x2y0qhs";
  };

  home.file.".config/awesome/calendar".source = fetchFromGitHub {
     owner = "yrashk";
     repo = "calendar";
     rev = "1ed19a3";
     sha256 = "1xfax18y4ddafzmwqp8qfs6k34nh163bwjxb7llvls5hxr79vr9s";
  };


}
