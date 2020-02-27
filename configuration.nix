# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # For bleeding edge stuff:
  nixos-unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./cave-audio.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.timeout = 2;
  # boot.plymouth.enable = true; # Not great, see: https://github.com/NixOS/nixpkgs/issues/32556
  # boot.kernelPackages = nixos-unstable.linuxPackages_testing;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = { "vm.swappiness" = 10; };

  networking.hostName = "flakebook"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.networkmanager.insertNameservers = [ "8.8.8.8" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  console.font = "Lat2-Terminus16";
  console.keyMap = "us";
  i18n = {
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
    chromium.enableWideVine = true;
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

    vlc
    ## signal-desktop
    chromium

    jetbrains.pycharm-community
    sublime3
    #netbeans
    #android-studio
    #adb-sync
    #adbfs-rootless

    (python3.withPackages(ps: with ps; [
      ipython
      numpy
      jupyter
      yapf
      pandas
    ]))

    ## kdeApplications.gwenview
    diffoscope
    ## mattermost-desktop
    keepassx-community
    kgraphviewer
    gimp
    meld

    ## libreoffice
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.Nix
        ms-vscode.cpptools
        #ms-python.python
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
#        {
#          name = "vscode-icons";
#          publisher = "robertohuertasm";
#          version = "8.0.0";
#          sha256 = "0kccniigfy3pr5mjsfp6hyfblg41imhbiws4509li31di2s2ja2d";
#        }
        {
          name = "vim";
          publisher = "vscodevim";
          version = "0.17.3";
          sha256 = "0lak19bc1gwymwz0ja6dksr9ckiaikzwa78520s4fksm5ngxr678";
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
    acpid
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
    gnumake
    graphviz
    gitAndTools.hub
    iotop
    htop
    indent
    intel-gpu-tools
    jq
    libinput-gestures
    lldb
    lsof
    mc
    myVim
    any-nix-shell
    nix-index
    nix-prefetch-scripts
    nix-review
    paprefs # pulseaudio preferences (for enabling airplay)
    patchelf
    pciutils
    procps-ng # watch
    rpm
    shellcheck
    silver-searcher
    sshfs-fuse
    strace
    tldr
    tmux
    tree
    valgrind
    wget
    xclip

    # Some command-line music
    pavucontrol # For fixing bluetooth issues
    python3Packages.mps-youtube mpv
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.adb.enable = true;
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
      plugins = [ "git" "tmux" "z" "docker" "colored-man-pages" ];
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
      sshfs -o reconnect,transform_symlinks $1:/ ~/mnt/$1
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
    search = "ag";
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
  services.earlyoom.enable = true;
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
  hardware.sensor.iio.enable = false; # The ACCEL_MOUNT_MATRIX doesn't work yet (modalias wrong?)
  services.udev.extraHwdb = ''
    sensor:modalias:platform:cros-ec-accel:dmi:*:svnGOOGLE*
     ACCEL_MOUNT_MATRIX=-1, 0, 0; 0, -1, 0; 0, 0, -1
  '';

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us,de";
  services.xserver.xkbOptions = "eurosign:e";

  services.xserver.videoDrivers = [ "intel" "modesetting" ];
  services.xserver.deviceSection = ''
    # Remove video tearing
      Option "DRI" "3"
      Option "TearFree" "true"
  '';
  # Enable touchpad support.
  services.xserver.libinput = {
    enable = true;
    middleEmulation = false;
    naturalScrolling = false;
    horizontalScrolling = false;
    tappingDragLock = false;
    scrollMethod = "twofinger";
    clickMethod = "clickfinger";
  };

  services.xserver.useGlamor = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.gnome3.enable = true;
  programs.ssh.askPassword = pkgs.lib.mkForce "${pkgs.plasma5.ksshaskpass.out}/bin/ksshaskpass";

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
  boot.kernelModules = [ "kvm-intel" ];
  boot.supportedFilesystems = [ "ntfs" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.docker = {
    enable = false;
    autoPrune.enable = true;
  };
  security.sudo.wheelNeedsPassword = false;
  nix = {
    autoOptimiseStore = false;
    buildCores = 2;
    daemonIONiceLevel = 5;
    daemonNiceLevel = 5;
    buildMachines = [
      { hostName = "knedlsepp.at";
        sshUser = "sepp";
        sshKey = "/root/.ssh/id_rsa";
        system = "x86_64-linux";
        maxJobs = 1;
        supportedFeatures = [ "kvm" "cuda" ];
        # mandatoryFeatures = [ "perf" ];
      }
    ];
  };
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?
}

