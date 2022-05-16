{ pkgs, ... }:
{

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;


  # Enable/Disable the X11 windowing system.
  services.xserver.enable = true;

  # Is flatpak useless if I use nix?
  # To use Flatpak you must enable XDG Desktop Portals with xdg.portal.enable.
  # xdg.portal.enable = true;
  # services.flatpak.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver = {
    displayManager.gdm.enable = true;
    displayManager.defaultSession = "sway";
    #displayManager.sddm.enable = true;
    desktopManager = {
      #disable gnome for the moment
      gnome.enable = true;
    };
  };

  # init sway
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # so that gtk works properly
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      mako # notification daemon
      alacritty # Alacritty is the default terminal in the config
      dmenu # Dmenu is the default in the config but i recommend wofi since its wayland native
    ];
    # sway doesn't support proprietary nvidia driver so I can just do that:
    # launch with --unsupported-gpu
    extraOptions = [
      "--unsupported-gpu"
      # "--i-sware-my-next-gpu-wont-deffinitivelly-be-nvidia"
    ];
  };


  # Brightness with saw
  programs.light.enable = true;
  environment.systemPackages = with pkgs; [
    # brightness utility
    # pactl todo activate that?

    # theming
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    lxappearance
  ];

  # Configure keymap in X11
  services.xserver.layout = "fr";
  services.xserver.xkbOptions = "eurosign:e";

  environment.etc = {
    "sway/config".source = ./sway/config;
    "gitconfig".source = ./gitconfig;
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  hardware.bluetooth.enable = true;

}
