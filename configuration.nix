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
    ibm-plex
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts
    dina-font
    proggyfonts
  ];

  # Set your time zone.
  time.timeZone = "Europe/Vienna";

  nixpkgs.config.allowUnfree = true;
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
            set cindent

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
  environment.systemPackages = with pkgs; [

    aspellDicts.de
    aspellDicts.en

    tor
    spotify
    vlc
    signal-desktop
    mattermost-desktop
    chromium

    jetbrains.pycharm-community
    sublime3
    netbeans
    android-studio
    adb-sync
    adbfs-rootless

    (python3.withPackages(ps: with ps; [
      ipython
      numpy
      toolz
      jupyter
      pygame
      yapf
      pandas
      redis
    ]))

    # CLI stuff
    wget
    myVim
    gitFull
    fzf
    bat
    htop
    duc
    lsof
    file
    paprefs # pulseaudio preferences (for enabling airplay)
    gnome3.dconf # Needed to run pulseaudio preferences
    libinput-gestures
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
    ];
  };
  programs.dconf.enable = true; # without this paprefs could not enable airplay: https://github.com/NixOS/nixpkgs/issues/47938
  programs.command-not-found.enable = true;
  programs.bash = {
    enableCompletion = true;
    shellAliases = {
      l = "ls -rltah";
    };
    interactiveShellInit = ''
      if command -v fzf-share >/dev/null; then
        source "$(fzf-share)/key-bindings.bash"
        source "$(fzf-share)/completion.bash"
      fi
    '';
  };
  programs.adb.enable = true;

  environment.variables = {
    EDITOR = "vi";
  };
  # List services that you want to enable:

  services.redis.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    forwardX11 = true;
  };

  services.journald.extraConfig = ''
    SystemMaxUse=300M
  '';

  services.avahi.enable = true; # For discovering of (e.g.) airtunes speakers
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull; # Airtunes support
  hardware.enableAllFirmware = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us,de";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.middleEmulation = false;
  services.xserver.libinput.clickMethod = "clickfinger";

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;
  users.users.sepp = {
    isNormalUser = true;
    uid = 1000;
    initialPassword = "sepp";
    extraGroups = [ "wheel" "networkmanager" "adbusers" "input" ];
  };
  users.users.lena = {
    isNormalUser = true;
    uid = 1001;
    initialPassword = "lena";
    extraGroups = [ "wheel" "networkmanager" "adbusers" "input" ];
  };
  security.sudo.wheelNeedsPassword = false;
  nix = {
    autoOptimiseStore = true;
    buildCores = 3;
    daemonIONiceLevel = 2;
    daemonNiceLevel = 2;
    buildMachines = [
      { hostName = "knedlsepp.at";
        sshUser = "sepp";
        sshKey = "/root/.ssh/id_rsa";
        system = "x86_64-linux";
        maxJobs = 2;
        supportedFeatures = [ "kvm" ];
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

