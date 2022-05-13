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

  networking.hostName = "adrien"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  nixpkgs.config.allowUnfree = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_FR.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # To use Flatpak you must enable XDG Desktop Portals with xdg.portal.enable.
  xdg.portal.enable = true;
  services.flatpak.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  # todo Enable i3 Desktop Environment too
  services.xserver = {

    desktopManager = {
      gnome.enable = true;
    };
   
    #windowManager.i3 = {
    #  enable = true;
    #  extraPackages = with pkgs; [
    #    dmenu #application launcher most people use
    #    i3status # gives you the default i3 status bar
    #    i3lock #default i3 screen locker
    #    i3blocks #if you are planning on using i3blocks over i3status
    # ];
    #};
  };
  # todo make xmonad work => services.xserver.windowManager.xmonad.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # uncomment to get docker
  # virtualisation.docker.enable = true;
  users.users.adrien = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # wget
    firefox
    rustup
    cmake
    # (vscode-with-extensions.override {
    #   vscodeExtensions = with pkgs.vscode-extensions; [
    #     github.github-vscode-theme
    #     github.vscode-pull-request-github
    #     matklad.rust-analyzer
    #     ms-vsliveshare.vsliveshare
    #     eamodio.gitlens
    #     yzhang.markdown-all-in-one
    #     jnoortheen.nix-ide
    #     ms-vscode.cpptools
    #   ];
    # })
    pkg-config
    openssl
    bintools-unwrapped
    discord
    git
    powertop acpi
    direnv nix-direnv
    gnupg1 # in user you may want to `add default-cache-ttl 3600` in ~/.gnupg/gpg-agent.conf
    pinentry # Don't forget to add the line bellow
    pinentry-curses
    protobuf # Needed by tokio-console-subscriber

    nodejs
    yarn

    gnumake
    gcc
  ];

  # I prefer to try to load the packages
  programs.neovim = {
    enable = true;
    configure = {

      plug.plugins = with pkgs.vimPlugins; [
        # trying to make that working
        #{
        #  rtp = nvim-base16;
        #  config = ''
        #    packadd! nvim-base16.lua
        #    vim.cmd('colorscheme base16-gruvbox-dark-soft')
        #  '';
        #}
        vim-nix
        # fzf-lsp-nvim
        nerdtree
        vim-monokai
        # and what about that ? rust-vim
        vim-markdown
      ];

      customRC = ''
        syntax on
        colorscheme monokai
        set number
        set relativenumber

        highlight ExtraWhitespace ctermbg=red guibg=red
        autocmd BufWritePre * %s/\s\+$//e
      '';
    };
    viAlias = true;
    # configure.customRC = builtins.readFile /home/adrien/.config/nvim/init.vim;
  };

  environment = {
    sessionVariables = rec {
      RUST_BACKTRACE = "1";
      PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
    };
    pathsToLink = [
      "/share/nix-direnv"
    ];
  };

  # To use correctly gpg, in the user you should have:
  # $ cat ~/.gnupg/gpg-agent.conf
  # pinentry-program /run/current-system/sw/bin/pinentry
 
  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryFlavor = "curses";
    enableSSHSupport = true;
  };

  # nix options for derivations to persist garbage collection
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  # if you also want support for flakes (this makes nix-direnv use the
  # unstable version of nix):
  nixpkgs.overlays = [
    (self: super: { nix-direnv = super.nix-direnv.override { enableFlakes = true; }; } )
  ];

  documentation.dev.enable = true;
  environment.extraOutputsToInstall = [ "info" "man" "devman" ];

  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    promptInit = ''
      source ${pkgs.grml-zsh-config}/etc/zsh/zshrc
    '';
  };


  # Auto upgrade the system =-)
  system.autoUpgrade.enable = true;

  # Do the garbage collection & optimisation weekly.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ ];

  networking.nameservers = [
    "2a07:a8c0::85:4ac4"
    "2a07:a8c1::85:4ac4"
    "45.90.28.69"
    "45.90.30.69"
  ]; # NextDNS

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Power management
  powerManagement.enable = true;
  services.upower.enable = true;
  services.thermald.enable = true;
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
