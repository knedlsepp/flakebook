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
    defaultLocale = "en_US.UTF-8";
  };

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
    ]))

    # CLI stuff
    wget
    myVim
    gitFull
    fzf
    htop
    duc
    lsof
    file
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
  programs.command-not-found.enable = true;
  programs.bash = {
    enableCompletion = true;
    shellAliases = {
      l = "ls -rltah";
    };
    loginShellInit = ''
      if command -v fzf-share >/dev/null; then
        source "$(fzf-share)/key-bindings.bash"
      fi
    '';
  };

  environment.variables = {
    EDITOR = "vi";
  };
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.enableAllFirmware = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us,de";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.middleEmulation = false;
  services.xserver.libinput.clickMethod = "clickfinger";

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;
  users.users.sepp = {
    isNormalUser = true;
    uid = 1000;
    initialPassword = "sepp";
    extraGroups = [ "wheel" "networkmanager" ];
  };
  users.users.lena = {
    isNormalUser = true;
    uid = 1001;
    initialPassword = "lena";
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}

