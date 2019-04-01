# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;
  boot.plymouth.enable = true; # Not great, see: https://github.com/NixOS/nixpkgs/issues/32556
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.blacklistedKernelModules = [ "snd-hda-intel" ];

  networking.hostName = "flakebook"; # Define your hostname.
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_GB.UTF-8";
  };

  fonts.fonts = with pkgs; [
    dina-font
    fira-code
    fira-code-symbols
    ibm-plex
    inconsolata
    liberation_ttf
    meslo-lg
    mplus-outline-fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    proggyfonts
    twemoji-color-font
  ];

  # Set your time zone.
  time.timeZone = "Europe/Vienna";

  nixpkgs.config = {
    allowUnfree = true;
    android_sdk.accept_license = true;
    gnome3 = {
      gnome-keyring.enable = true;
      at-spi2-core.enable = true;
      #gnome-user-share.enable = true;
      gvfs.enable = true;
    };
  };
  nixpkgs.overlays = [
    (self: super: {
      myVim = super.vim_configurable.customize {
        name = "vi"; # The name is used as a binary!
        vimrcConfig = {
          customRC = ''
            set encoding=utf-8
            au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown
            au BufNewFile,BufRead,BufReadPost *.f90 set syntax=fortran
            au VimEnter * if &diff | execute 'windo set wrap' | endif

            filetype plugin indent on

            set backspace=2 " make backspace work like most other program
            set bg=dark
            set tabstop=4
            set shiftwidth=4
            set expandtab
            set wildmenu

            set autoindent
            set smartindent

            let g:ycm_python_binary_path = 'python'
            let g:ycm_autoclose_preview_window_after_insertion = 1

            let g:ycm_key_list_select_completion = ['<TAB>']
            let g:ycm_key_list_previous_completion = ['<S-TAB>']
            let g:ycm_key_list_stop_completion = ['<C-y>', '<UP>', '<DOWN>']

            let g:ycm_semantic_triggers = {
            \   'python': [ 're!\w{2}' ]
            \ }

            let g:gitgutter_enabled = 1

            colorscheme gruvbox
            " Show whitespace
            highlight ExtraWhitespace ctermbg=red guibg=red
            match ExtraWhitespace /\s\+$/
            autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
            autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
            autocmd InsertLeave * match ExtraWhitespace /\s\+$/
            autocmd BufWinLeave * call clearmatches()

            " Keep visual mode active
            vnoremap < <gv
            vnoremap > >gv

            " Remember last position
            if has("autocmd")
              au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
            endif

            " sync default register to clipboard
            if has('unnamedplus')
              set clipboard=unnamedplus
            else
              set clipboard=unnamed
            endif
          '';
          packages.myVimPackage = with super.vimPlugins; {
            start = [
              youcompleteme
              ctrlp
              vim-airline
              vim-airline-themes
              fugitive
              nerdtree
              gitgutter
              molokai
              vim-colorstepper # Use F6/F7 to select your favorite colorscheme
              awesome-vim-colorschemes
              vim-yapf
            ];
            opt = [  ];
          };
        };
      };
    }
  )];
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.etc = {
    #TODO: This needs a systemd daemon and should become a NixOS module
    "libinput-gestures.conf".text = ''
      # KDE: Present Windows (current desktop)
      gesture swipe up xdotool key ctrl+F9

      # KDE: Present Windows (Window class)
      gesture swipe down xdotool key ctrl+F8

      gesture swipe left xdotool key alt+Left
      gesture swipe right xdotool key alt+Right
    '';
    };
  environment.gnome3.excludePackages = with pkgs.gnome3; [
    epiphany
    gnome-music
    gnome-photos
    totem
    accerciser
  ];
  environment.systemPackages = with pkgs; [

    aspellDicts.de
    aspellDicts.en

    spotify
    vlc
    signal-desktop
    chromium
    firefox

    jetbrains.pycharm-community
    sublime3
    #netbeans
    #android-studio
    #adb-sync
    #adbfs-rootless

    (python3.withPackages(ps: with ps; [
      ipython
      numpy
      toolz
      jupyter
      pygame
      yapf
      pandas
    ]))

    kdeApplications.gwenview
    adobeReader
    diffoscope
    mattermost-desktop
    keepassx-community
    kgraphviewer
    gimp

    libreoffice
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.Nix
        ms-vscode.cpptools
        ms-python.python
      ] ++ vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "cmake-format";
          publisher = "cheshirekow";
          version = "0.4.2";
          sha256 = "03q7ky0rb7af9ysjcvfgr5hhipaxdzkkz0ha6pjg39p30nir9qkm";
        }
        {
          name = "cmake";
          publisher = "twxs";
          version = "0.0.17";
          sha256 = "11hzjd0gxkq37689rrr2aszxng5l9fwpgs9nnglq3zhfa1msyn08";
        }
        {
          name = "cmake-tools";
          publisher = "vector-of-bool";
          version = "1.1.3";
          sha256 = "1x9ph4r742dxj0hv6269ngm7w4h0n558cvxcz9n3cg79wpd7j5i5";
        }
        {
          name = "gitlens";
          publisher = "eamodio";
          version = "9.3.0";
          sha256 = "05zwviyr1ja525ifn2a704ykl4pvqjvpppmalwy4z77bn21j2ag7";
        }
        {
          name = "vscode-icons";
          publisher = "robertohuertasm";
          version = "8.0.0";
          sha256 = "0kccniigfy3pr5mjsfp6hyfblg41imhbiws4509li31di2s2ja2d";
        }
        {
          name = "vim";
          publisher = "vscodevim";
          version = "0.17.3";
          sha256 = "0lak19bc1gwymwz0ja6dksr9ckiaikzwa78520s4fksm5ngxr678";
        }
        {
          name = "vscode-docker";
          publisher = "peterjausovec";
          version = "0.4.0";
          sha256 = "1inlks69hbln221d1g06bxl1r9f13pknw9394wyg6ffhl6fs86ri";
        }
        {
          name = "githistory";
          publisher = "donjayamanne";
          version = "0.4.4";
          sha256 = "18cha01n29dgysch2diyszjwpf9fpvpzpihikm1kps953d8blvnd";
        }
        {
          name = "bracket-pair-colorizer";
          publisher = "coenraads";
          version = "1.0.61";
          sha256 = "0r3bfp8kvhf9zpbiil7acx7zain26grk133f0r0syxqgml12i652";
        }
        {
          name = "gitblame";
          publisher = "waderyan";
          version = "2.6.3";
          sha256 = "08rlmb5ic22hglh6fmi2pl2p1yphjk5vpbi2hs12pxqjc57cqww9";
        }
        {
          name = "clang-format";
          publisher = "xaver";
          version = "1.8.0";
          sha256 = "1xncj80x82a2b34ql33rc26x8sb0vchssfa9jd7wa95jg3ivb27v";
        }
        {
          name = "vscode-lldb";
          publisher = "vadimcn";
          version = "1.2.0";
          sha256 = "016ragmcpa02jnxrf715xwvs1hwq559br71vfkhd9q3bbl49703b";
        }
        {
          name = "debug";
          publisher = "webfreak";
          version = "0.22.0";
          sha256 = "1frikakfcslwn177zdwzcc2qzvhvr7fw3whqls4hykhm577g093f";
        }
        {
          name = "vscode-cudacpp";
          publisher = "kriegalex";
          version = "0.1.1";
          sha256 = "00qkx97sk2savwpi0szc5hyjr3pwp1b809pcklynrcqnp5rj2zn1";
        }
        {
          name = "code-runner";
          publisher = "formulahendry";
          version = "0.6.33";
          sha256 = "166ia73vrcl5c9hm4q1a73qdn56m0jc7flfsk5p5q41na9f10lb0";
        }
      ];
    })

    # CLI stuff
    bat
    bear
    binutils-unwrapped
    python3Packages.black
    bvi
    byobu
    cgdb gdb
    clang-tools
    direnv
    duc
    elfutils
    fd
    file
    fzf
    git-review
    gitFull
    gitAndTools.diff-so-fancy
    gnome3.dconf # Needed to run pulseaudio preferences
    graphviz
    gitAndTools.hub
    iotop
    htop
    indent
    jq
    libinput-gestures
    lldb
    lsof
    mc
    myVim
    nixos-unstable.any-nix-shell # TODO: Switch to stable with 19.03
    nix-index
    nix-prefetch-scripts
    paprefs # pulseaudio preferences (for enabling airplay)
    patchelf
    procps-ng # watch
    rpm
    sshfs-fuse
    strace
    tldr
    tmux
    tree
    valgrind
    wget

    # Some command-line music
    pavucontrol # For fixing bluetooth issues
    python36Packages.mps-youtube mpv
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.chromium = {
    enable = true;
    homepageLocation = "https://google.at";
    extensions = [
      "chlffgpmiacpedhhbkiomidkjlcfhogd" # pushbullet
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      "cfhdojbkjhnklbpkdaibdccddilifddb" # adblock plus
      "jgfnehdmbbmcahojnebecpiljbkeaele" # ORF-TVthek - Downloader
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "ookepigabmicjpgfnmncjiplegcacdbm" # Material Simple Dark Grey
      "gkojfkhlekighikafcpjkiklfbnlmeio" # Hola VPN Proxy Unblocker
    ];
  };
  programs.dconf.enable = true; # without this paprefs could not enable airplay: https://github.com/NixOS/nixpkgs/issues/47938
  programs.command-not-found.enable = true;
  programs.bash = {
    enableCompletion = true;
    interactiveShellInit = ''
      source "$(fzf-share)/key-bindings.bash"
      source "$(fzf-share)/completion.bash"
      eval "$(direnv hook bash)"
    '';
    };
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    ohMyZsh = {
      enable = true;
      customPkgs = [];
      theme = "fishy";
      plugins = [ "git" "powerline" "tmux" "z" "docker" "colored-man-pages" ];
    };
    interactiveShellInit = ''
      source "$(fzf-share)/key-bindings.zsh"
      source "$(fzf-share)/completion.zsh"
      eval "$(direnv hook zsh)"
      export DIRENV_LOG_FORMAT= # Silence direnv
    '';
    promptInit = ''
      any-nix-shell zsh --info-right | source /dev/stdin
    '';
    syntaxHighlighting.enable = true;
  };
  environment.enableDebugInfo = true;
  environment.interactiveShellInit = ''
    function mount_server(){
      mkdir -p ~/mnt/$1
      sshfs -o reconnect,transform_symlinks $(whoami)@$1:/ ~/mnt/$1
    }
    function unmount_server(){
      fusermount -u ~/mnt/$1
    }
    function treeless(){
      tree -C ''${@} | less -f -r
    }
  '';

  environment.shellAliases = {
    l = "ls -rltah";
    search = "grep -nrw . -e \${@}";
    cat = "bat";
    open = "xdg-open";
    stream = "mpsyt /$1";
    vpn-start = "sudo systemctl start openvpn-IMS";
    vpn-stop = "sudo systemctl stop openvpn-IMS";
  };

  environment.variables = {
    EDITOR = "vi";
    LESS = "FrX";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = false;
    forwardX11 = true;
  };
  services.openvpn.servers = {
    IMS = {
      config = ''
        dev tun
        persist-tun
        persist-key
        cipher AES-128-CBC
        auth SHA256
        tls-client
        client
        reneg-sec 14400
        resolv-retry infinite
        remote limes.ims.co.at 1194 udp
        lport 0
        auth-user-pass
        pkcs12 /root/ims/cert.p12
        tls-auth /root/ims/server.key 1
        remote-cert-tls server
        auth-nocache
        script-security 2
      '';
      updateResolvConf = true;
      autoStart = false; # Requires `sudo systemctl start openvpn-IMS` to start vpn manually
      };
  };

  security.pki.certificates = [
    ''
      confluence.rnd.ims.co.at
      -----BEGIN CERTIFICATE-----
      MIIE6zCCA9OgAwIBAgIBKzANBgkqhkiG9w0BAQsFADCBijELMAkGA1UEBhMCQVQx
      DzANBgNVBAgTBlZpZW5uYTELMAkGA1UEBxMCSFExHDAaBgNVBAoTE0lNUyBOYW5v
      ZmFicmljYXRpb24xCzAJBgNVBAsTAklUMREwDwYDVQQDEwhpbXNzcnZjYTEfMB0G
      CSqGSIb3DQEJARYQZ3JwLml0QGltcy5jby5hdDAeFw0xODA1MDcwMDAwMDBaFw0y
      MDA1MDYyMzU5NTlaMIGaMQswCQYDVQQGEwJBVDEPMA0GA1UECBMGVmllbm5hMQsw
      CQYDVQQHEwJIUTEcMBoGA1UEChMTSU1TIE5hbm9mYWJyaWNhdGlvbjELMAkGA1UE
      CxMCSVQxITAfBgNVBAMTGGNvbmZsdWVuY2Uucm5kLmltcy5jby5hdDEfMB0GCSqG
      SIb3DQEJARYQZ3JwLml0QGltcy5jby5hdDCCASIwDQYJKoZIhvcNAQEBBQADggEP
      ADCCAQoCggEBALrEwWbyu4hajHCt8Gl+v5XV399tyEaC+N4/qSvmirklHZOXYa9s
      pAuvFJBzT8UWL3oxX8tJ3oOw5eFv/mTwk6bh4chLIV0EZjqmB8PWm9sJ3wD4ia/h
      uF/TN/4MGXsRvTGxwu5jkqthgUdXUB1FgZDZcoaDzYR46j+xAI4O8ajFOuB2QPOF
      2bT5WQ6w4ASkkgwMmXGOGnAzoGQWrDMhrrltJZWIjH0/bEzriHopbvKdX8igczAf
      MPyCi8f/DSe3aM0EsVphLzOVXNjYtUgQmkZ/G0J7+STiy6w6znQibWexO5gnNUP+
      xBMpXFPQ8eMENxJaBXcGXQI5T1KcEiQVSScCAwEAAaOCAUgwggFEMAwGA1UdEwEB
      /wQCMAAwHQYDVR0OBBYEFEHjCO/fA07GcCJ2Nnkd/toXKp5jMAsGA1UdDwQEAwIE
      8DBRBgNVHRIESjBIhhRodHRwOi8vd3d3Lmltcy5jby5hdIEPc3J2Y2FAaW1zLmNv
      LmF0iAgrBgEEAYKRPYIPc3J2Y2EuaW1zLmNvLmF0hwQKeBQqMF0GA1UdHwRWMFQw
      JqAkoCKGIGh0dHA6Ly93d3cuaW1zLmNvLmF0L2NybC9jcmwucGVtMCqgKKAmhiRo
      dHRwOi8vc3J2Y2EuaW1zLmNvLmF0L2NybC9zcnZjYS5jcmwwEQYJYIZIAYb4QgEB
      BAQDAgbAMB4GCWCGSAGG+EIBDQQRFg94Y2EgY2VydGlmaWNhdGUwIwYDVR0RBBww
      GoIYY29uZmx1ZW5jZS5ybmQuaW1zLmNvLmF0MA0GCSqGSIb3DQEBCwUAA4IBAQCP
      0LyjeMJquhz47HD07MWT6+mDqcRbWGmEj2iDbbRPcoyiaMR3V57hJRsx+Wh3yNCn
      Gd7bcDo8N6mCo/mNakVH53HyH3JruYP4hRJJMfo7ICImtAz374fy7pxxx+pfaa7e
      ZV8xHNMHR4oBAlsUPin3vGz5ShqY1oWFvJPtKcLSUOlhmJZk/BP4+V//g/pT9Kz7
      4+GBgp1cakhmKpoKZly/fM3FEYGvt0HcVvgB2sEYokIg6BTn9e6jIVLGpa9+lAvw
      J0em1ftqIIbJ7kAS5QfVmL/7hJ3IYBqlh1rbCzMTDYpLoqODV8h49twbd5D2bsGR
      rcnSyeoSVR7h0kPHfhcv
      -----END CERTIFICATE-----
    ''

    ''
      jira.rnd.ims.co.at
      -----BEGIN CERTIFICATE-----
      MIIE3zCCA8egAwIBAgIBKjANBgkqhkiG9w0BAQsFADCBijELMAkGA1UEBhMCQVQx
      DzANBgNVBAgTBlZpZW5uYTELMAkGA1UEBxMCSFExHDAaBgNVBAoTE0lNUyBOYW5v
      ZmFicmljYXRpb24xCzAJBgNVBAsTAklUMREwDwYDVQQDEwhpbXNzcnZjYTEfMB0G
      CSqGSIb3DQEJARYQZ3JwLml0QGltcy5jby5hdDAeFw0xODA1MDcwMDAwMDBaFw0y
      MDA1MDYyMzU5NTlaMIGUMQswCQYDVQQGEwJBVDEPMA0GA1UECBMGVmllbm5hMQsw
      CQYDVQQHEwJIUTEcMBoGA1UEChMTSU1TIE5hbm9mYWJyaWNhdGlvbjELMAkGA1UE
      CxMCSVQxGzAZBgNVBAMTEmppcmEucm5kLmltcy5jby5hdDEfMB0GCSqGSIb3DQEJ
      ARYQZ3JwLml0QGltcy5jby5hdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
      ggEBAMbu1WNIH87n2KYGhr299EBAFX7WITtDp0rMi3UVtaUkyEizFYzVBXxVXyBJ
      E5SeJwGnXzjSr04T5gel/saw2S19QPH0VcYkvk4trxY7eVblnN3VdCKoBp7brcra
      EOXjHYcIX8Zh/16IaV/O9Xvn8mo4E/66y0hkvCHmjRlzLXDgsQo4qX4s+aBv30xq
      6n5tYznI4dKSfVYpN4ZmkFzIryGCwWZatveMJsFg3CG6xfzl+kkm2idnxjsynduW
      i4CErKsENZIM4altmLoQA3qb+4URN+tsjvqavN6Z69vKQVhWtP5Rzk9XfpUBb3oW
      MlqFMLEWQIdFQGOW1EHuLRqbj7MCAwEAAaOCAUIwggE+MAwGA1UdEwEB/wQCMAAw
      HQYDVR0OBBYEFFf81/hzc8c8Oz2WyrvRCvvgvbOgMAsGA1UdDwQEAwIE8DBRBgNV
      HRIESjBIhhRodHRwOi8vd3d3Lmltcy5jby5hdIEPc3J2Y2FAaW1zLmNvLmF0iAgr
      BgEEAYKRPYIPc3J2Y2EuaW1zLmNvLmF0hwQKeBQqMF0GA1UdHwRWMFQwJqAkoCKG
      IGh0dHA6Ly93d3cuaW1zLmNvLmF0L2NybC9jcmwucGVtMCqgKKAmhiRodHRwOi8v
      c3J2Y2EuaW1zLmNvLmF0L2NybC9zcnZjYS5jcmwwEQYJYIZIAYb4QgEBBAQDAgbA
      MB4GCWCGSAGG+EIBDQQRFg94Y2EgY2VydGlmaWNhdGUwHQYDVR0RBBYwFIISamly
      YS5ybmQuaW1zLmNvLmF0MA0GCSqGSIb3DQEBCwUAA4IBAQBCf4dWFiXaT86nfiAj
      gtSD9FK88cCrCXdojAQrsjaQm5Ft/c21cstP0VIebx3pQR5SOy+JEG+0kpcqd5T+
      FJwM3Hf5Hf0xz4nk3wHrHjIBtqU1lNrDcVZ0uttvmfbHpfDdA1WHXluv+UDHTQXp
      cJNVHryR0xtHIvy8Whl5mgh1xul2MzrL92Bi0h788d26c6o0KcL1vbnvq9sXK+v5
      3ou/3sryb5QbBdxpjWKPcomxevhgBKUTULNYfdrM3qpkM8xG+WZC5yqZ1uH4WpuQ
      AAbl2zoLJ9O40eLpnf3eqUuoujGKvgwkivQQvwz3Xkhoh+bpsPVcQqmtmcd7P4GY
      es9c
      -----END CERTIFICATE-----
    ''

    ''
      gerrit.ims.co.at
      -----BEGIN CERTIFICATE-----
      MIIEpzCCA4+gAwIBAgIBLjANBgkqhkiG9w0BAQsFADCBijELMAkGA1UEBhMCQVQx
      DzANBgNVBAgTBlZpZW5uYTELMAkGA1UEBxMCSFExHDAaBgNVBAoTE0lNUyBOYW5v
      ZmFicmljYXRpb24xCzAJBgNVBAsTAklUMREwDwYDVQQDEwhpbXNzcnZjYTEfMB0G
      CSqGSIb3DQEJARYQZ3JwLml0QGltcy5jby5hdDAeFw0xODA2MjAwMDAwMDBaFw0y
      MDA2MTkyMzU5NTlaMIGSMQswCQYDVQQGEwJBVDEPMA0GA1UECBMGVmllbm5hMQsw
      CQYDVQQHEwJIUTEcMBoGA1UEChMTSU1TIE5hbm9mYWJyaWNhdGlvbjELMAkGA1UE
      CxMCSVQxGTAXBgNVBAMTEGdlcnJpdC5pbXMuY28uYXQxHzAdBgkqhkiG9w0BCQEW
      EGdycC5pdEBpbXMuY28uYXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
      AQCuiGLXERbxzCsU8MzrJlPaGqn+E9C8ai1LE+/pOQnZ59SupzoYrLRKp+GuTapZ
      sxLfHsuiGrUPI+89zjv5GNXebla5YnrlELyS/LdFAMe2XFylYluWdUj1Mzl955Mc
      cMByuygtUwd9rEB35VIjSIzWc9H/xcZhEyLE6EQ0X9KThZevSjzu7pHUzKSlmrAp
      VLAF44z+eChMCK2zKyzm6EGOwMezcpgy6+IXdC0qwu3mgi/aEh9/6sIf5Oq1Y86x
      1axLnVwdv3W5p3Bhxz2QLAiym+R0YWc0KiqixsM+ZX0l25+vKoiGQJdmmNZH3pQZ
      W2KRyzz3BzHr6nOyPED5/UCLAgMBAAGjggEMMIIBCDAMBgNVHRMBAf8EAjAAMB0G
      A1UdDgQWBBR/l2em397Uvv0xRRCnfPQz8IgO2DALBgNVHQ8EBAMCBPAwHQYDVR0l
      BBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMF0GA1UdHwRWMFQwJqAkoCKGIGh0dHA6
      Ly93d3cuaW1zLmNvLmF0L2NybC9jcmwucGVtMCqgKKAmhiRodHRwOi8vc3J2Y2Eu
      aW1zLmNvLmF0L2NybC9zcnZjYS5jcmwwEQYJYIZIAYb4QgEBBAQDAgbAMB4GCWCG
      SAGG+EIBDQQRFg94Y2EgY2VydGlmaWNhdGUwGwYDVR0RBBQwEoIQZ2Vycml0Lmlt
      cy5jby5hdDANBgkqhkiG9w0BAQsFAAOCAQEAnTMGsOrnPi2XI11/+c70fzNfLHFm
      ykBOeaojRAHddB+doxGcSCqSlQjTSURL/TN7HgHSLdtPOCHWEqBNjFSLQOqg5voN
      OUMST0RTEvj7m5IrVx6cbr5lHN1UgU65xYPAhSECwVVP6fV409D5qoulolFqmlU7
      Pp6MqjseaVF3izZamj1paKvKPqUQqw2m9q6la3PQC6Mp/ylKBNCV1SaKTsygVRU3
      e7UpRTwdVnQOZUeWA0aD5kSw97bIZ57ona/gbKgTKYhSENKyIttDoerxaA2tvOJo
      LRyuLzQsO0EsS7Su7O9/mnH0OTRZ6hEa6Kk3efHdy48dChrCL0gU64v2Vw==
      -----END CERTIFICATE-----
    ''

    ''
      gitlab.rnd.ims.co.at
      -----BEGIN CERTIFICATE-----
      MIIFKzCCAxOgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBtDELMAkGA1UEBhMCQVQx
      DzANBgNVBAgMBlZpZW5uYTEPMA0GA1UEBwwGVmllbm5hMSEwHwYDVQQKDBhJTVMg
      TmFub2ZhYnJpY2F0aW9uIEdtYkgxITAfBgNVBAsMGFJlc2VhcmNoIGFuZCBEZXZl
      bG9wbWVudDEWMBQGA1UEAwwNcm5kLmltcy5jby5hdDElMCMGCSqGSIb3DQEJARYW
      ZWxpYXMud2ltbWVyQGltcy5jby5hdDAeFw0xODA1MTUxNTE2NTZaFw0yMzA1MTQx
      NTE2NTZaMHExCzAJBgNVBAYTAkFUMQ8wDQYDVQQIDAZWaWVubmExDzANBgNVBAcM
      BlZpZW5uYTEhMB8GA1UECgwYSU1TIE5hbm9mYWJyaWNhdGlvbiBHbWJIMR0wGwYD
      VQQDDBRnaXRsYWIucm5kLmltcy5jby5hdDCCASIwDQYJKoZIhvcNAQEBBQADggEP
      ADCCAQoCggEBAPJt38Z8n9QzGqtaQnh6UNRR7jmKrd6ppNXESOf0l7DTjbepuBtM
      0FKJecT0WaHiC44iPKDBfvLIoBeOuFMoPh7oop+I/0kmCzOS2huSzkDdehsIrTOg
      RSaMBUV21CRNpRAWFXD/wse4+jzj3SP+6sU8itQS8XQpbfXsH1WWC9sRNekFOxoE
      zP9jLmpHpfYKuCEVkcTV+uXEGcfH1M3DWEHfYlxUD30K8+1YilKNUQJjWPVTohlW
      AroF1kClmZLtTNuzFjnRu0df/Pk/vIUOYCbVM+V3iSgX9ysTTl0KLyagrsxJNx8U
      H3Mycww3Ux75S3z9NbdcyotxAenSjC3uIU0CAwEAAaOBiTCBhjAdBgNVHQ4EFgQU
      Iub3AA/40I/YzvOPf7kN6jfZMCowHwYDVR0jBBgwFoAUKRAMoOHLpYRjQcUxjjt0
      k6CviHwwCQYDVR0TBAIwADALBgNVHQ8EBAMCBaAwLAYJYIZIAYb4QgENBB8WHU9w
      ZW5TU0wgR2VuZXJhdGVkIENlcnRpZmljYXRlMA0GCSqGSIb3DQEBCwUAA4ICAQA/
      N+QKtN3dVb7lmhN+BCFDy1uB/kzdGLUufRRDO4nWBRgzBjNFDv0tMiR7tq8Qxgt6
      7TTeYWG2MLgKOjLmK7H/H4/Gh7dHiC2eQNN1f2GIizEyn05ji1z6f1OEeyGOIBjR
      bfhzThZuw2M8DMLzSSGsTjjYDRmE3UZeiR6SBBBzoWEZCSPazXAPl57OT04Z/gLP
      7sSh5IAG3G7D/m7oNLtgZC7e+iuEjjj+K5lVBnVGGrD/F6oqEx+JtDSLbA7H7ATm
      ShKwXiLM8e3jKu9ZaehxjhxETOmI86yfxLHiyIznGPljT0gLgXlg+RZl0O0sc704
      QCTRE1/a0Bs/reKRdLduzUYesjMFr8bDSK4pLaGhtJG4MKCKUPWOMFtTpSjQ2hG/
      BzYK23l7ytxfdSrijvo/BtZ7sPkY3tEmET/Npg9HZerhQMrwkvZs2NqjAv3tAUqG
      3NxJUT5Aq9XtB5qXqK+zx3cyylfjShu4gpkR0P+04mkaRohs5cH0qkx6F00J1dTC
      GNZisSSSK7eBdGKqg/Wm13eYH6mmdzhuDBUxFjpf5+yBMK0yLj6lFMAmVsd9weLG
      wl+fm2VjXniwn0ivUi0rStbEq9O5pX804yK5cy4/MtfcsVR1M8zlMC8dfTXurzNO
      tbskz8Uug3b2RUuavCiQuE0eBSx8D5MrxZRa+r3S2A==
      -----END CERTIFICATE-----
    ''
  ];
  services.emacs = {
    enable = true;
    package = let
      myEmacs = pkgs.emacs26-nox;
      emacsWithPackages = (pkgs.emacsPackagesNgGen myEmacs).emacsWithPackages;
    in
      emacsWithPackages (epkgs: (with epkgs.melpaPackages; [
        anaconda-mode
        direnv
        docker
        docker-tramp
        elpy
        flycheck
        helm
        helm-projectile
        irony
        ivy
        magit
        projectile
        realgud
        use-package
      ]) ++ (with epkgs.elpaPackages; [
        company
        org
        which-key
      ]));
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;
  services.printing.listenAddresses = [
    "localhost:631"
    "cups.ims.co.at:631"
  ];

  services.journald.extraConfig = ''
    SystemMaxUse=300M
  '';

  services.locate.enable = true;
  services.avahi.enable = true; # For discovering of (e.g.) airtunes speakers
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;


  # Enable sound.
  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull; # Airtunes support
  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.sensor.iio.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us,de";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;
    middleEmulation = false;
    naturalScrolling = true;
    horizontalScrolling = false;
    tappingDragLock = false;
    scrollMethod = "twofinger";
    clickMethod = "clickfinger";
  };

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.gnome3.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;
  users.defaultUserShell = pkgs.zsh;
  users.users.sepp = {
    isNormalUser = true;
    uid = 1000;
    initialPassword = "sepp";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "adbusers" "input" ];
  };
  users.users.lena = {
    isNormalUser = true;
    uid = 1001;
    initialPassword = "lena";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "adbusers" "input" ];
  };
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  security.sudo.wheelNeedsPassword = false;
  nix = {
    autoOptimiseStore = true;
    buildCores = 3;
    daemonIONiceLevel = 5;
    daemonNiceLevel = 5;
    buildMachines = [
      { hostName = "knedlsepp.at";
        sshUser = "sepp";
        sshKey = "/root/.ssh/id_rsa";
        system = "x86_64-linux";
        maxJobs = 2;
        supportedFeatures = [ "kvm" "cuda" ];
        # mandatoryFeatures = [ "perf" ];
      }
    ];
  };
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}

