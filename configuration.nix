# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./networking.nix
      ./desktop.nix
      <nixos-hardware/dell/precision/5530>
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # use proprietary nvidia pkgs
  # services.xserver.videoDrivers = [ "nvidia" ];
  # Optionally, you may need to select the appropriate driver version for your specific GPU.

  # donnow if I need that
  # hardware.opengl.enable = true;
  #
  # nouveau is enough for desktop
  # services.xserver.videoDrivers = ["nvidia"];
  # hardware.nvidia.powerManagement.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";
  nixpkgs.config.allowUnfree = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Configure keymap in X11
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # uncomment to get docker
  # virtualisation.docker.enable = true;
  users.users.adrien = {
    isNormalUser = true;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkManager"
      # "docker" if u want docker
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # wget
    firefox
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
    discord

    # dev tools
    git
    nodejs
    yarn
    rustup
    protobuf # Needed by tokio-console-subscriber
    cmake
    gnumake
    gcc# <--- in bintools
    bintools-unwrapped
    glibc

    # power management tools
    powertop acpi

    # nix + direnv <3
    direnv nix-direnv

    gnupg1 # in user you may want to `add default-cache-ttl 3600` in ~/.gnupg/gpg-agent.conf
    pinentry # Don't forget to add the line bellow
    pinentry-curses
  ];

  # I prefer to try to load the packages
  programs.neovim = {
    enable = true;
    configure = {

      plug.plugins = with pkgs.vimPlugins; [
        vim-nix
        # fzf-lsp-nvim
        nerdtree
        vim-monokai-pro
        nvim-treesitter
        vim-surround
        rainbow
        # and what about that ? rust-vim
        rust-vim
        rust-tools-nvim
        nvim-lspconfig
        vim-markdown
      ];

      customRC = builtins.readFile ./conf.vim;
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


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Power management
  # powerManagement.enable = true;
  # services.upower.enable = true;
  # services.thermald.enable = true;
  # services.tlp.enable = true;
  # services.tlp.settings = let
  #     cfg = config.powerManagement;
  #     maybeDefault = val: lib.mkIf (val != null) (lib.mkDefault val);
  # in {
  #     TLP_ENABLE = 1;
  #     TLP_DEFAULT_MODE = "BAT";
  #     CPU_SCALING_GOVERNOR_ON_AC = maybeDefault cfg.cpuFreqGovernor;
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #     USB_AUTOSUSPEND = 1;
  #     START_CHARGE_THRESH_BAT0 = 75;
  #     STOP_CHARGE_THRESH_BAT0 = 80;
  #     START_CHARGE_THRESH_BAT1 = 75;
  #     STOP_CHARGE_THRESH_BAT1 = 80;
  #     CPU_MIN_PERF_ON_AC = 0;
  #     CPU_MAX_PERF_ON_AC = 100;
  #     CPU_MIN_PERF_ON_BAT = 0;
  #     CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
  #     CPU_MAX_PERF_ON_BAT = 30;
  #     INTEL_GPU_MIN_FREQ_ON_AC = 350;
  #     INTEL_GPU_MIN_FREQ_ON_BAT = 350;
  #     INTEL_GPU_MAX_FREQ_ON_AC = 1450;
  #     INTEL_GPU_MAX_FREQ_ON_BAT = 700;
  #     INTEL_GPU_BOOST_FREQ_ON_AC = 1450;
  #     INTEL_GPU_BOOST_FREQ_ON_BAT = 700;
  # };
  # services.power-profiles-daemon.enable = false;



  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
