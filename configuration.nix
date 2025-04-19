# ───────────────────────────────────────────────────────────────────────────
# ❄️ Cozy NixOS: Winter Wonderland Config ❄️
# ───────────────────────────────────────────────────────────────────────────

{ config, pkgs, inputs, spicetify-nix, lib, chaotic, nix-gaming, neve, ... }:

{
  # ─────────────────────────────────────────────────────────────────────────
  # 🧊 Glacier Imports
  # ─────────────────────────────────────────────────────────────────────────
  imports = [
    ./hardware-configuration.nix
    inputs.spicetify-nix.nixosModules.default
  ];

  # ─────────────────────────────────────────────────────────────────────────
  # 🧤 Swapfile Setup (16GB)
  # ─────────────────────────────────────────────────────────────────────────
  swapDevices = [{
    device = "/swapfile";
    size = 16 * 1024;
  }];

  # ─────────────────────────────────────────────────────────────────────────
  # 🐧 Core System Settings
  # ─────────────────────────────────────────────────────────────────────────
  system.stateVersion = "24.11";
  time.timeZone = "America/Halifax";
  i18n.defaultLocale = "en_CA.UTF-8";
  networking.hostName = "boreas";
  networking.networkmanager.enable = true;

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Flake magic & nix settings
  # ─────────────────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "-d --delete-older-than +5";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Bootloader & Kernel Setup
  # ─────────────────────────────────────────────────────────────────────────
  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos;
    kernelParams = [ "quiet" "splash" "systemd.show_status=false" ];
    initrd.kernelModules = [ "nvidia" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    plymouth = {
      enable = true;
      theme = "spinfinity";
    };
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ⛷️ CPU & GPU Support
  # ─────────────────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;
  hardware.cpu.amd.updateMicrocode = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaPersistenced = true;
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Suspend/Sleep
  # ─────────────────────────────────────────────────────────────────────────
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 🧣 KDE + Plasma Desktop
  # ─────────────────────────────────────────────────────────────────────────
  services = {
    displayManager = {
      sddm.enable = true;
      sddm.theme = "catppuccin-mocha";
      sddm.wayland.enable = true;
      defaultSession = "plasma";
    };

    desktopManager.plasma6.enable = true;

    # Disable KDE background services on boot
    scx.enable = true;
    printing.enable = false;
    blueman.enable = false;

    pipewire = {
      enable = true;
      wireplumber.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
  };

  systemd.user.services."app-org.kde.kalendarac@autostart".enable = false;
  systemd.user.services."app-org.kde.kunifiedpush\x2ddistributor@autostart".enable = false;

  security.rtkit.enable = true;

  # ─────────────────────────────────────────────────────────────────────────
  # 🧊 User Setup: isolde
  # ─────────────────────────────────────────────────────────────────────────
  users.users.isolde = {
    isNormalUser = true;
    description = "isolde";
    extraGroups = [ "networkmanager" "wheel" "audio" ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 🎮 Gaming Igloo
  # ─────────────────────────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession.enable = true;
  };

  programs = {
    gamemode.enable = true;
    dconf.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [
          pkgs.icu
          pkgs.libxcrypt-legacy
          pkgs.python312
          pkgs.python312Packages.torch
          pkgs.cudaPackages.cudnn
          pkgs.cudaPackages.cudatoolkit
          pkgs.libGL
          pkgs.python312Packages.torchvision
        ];
      };
    };

    hyprland.enable = true;
    hyprlock.enable = true;
    partition-manager.enable = true;

    # Optional: disable firefox in favor of librewolf
    firefox.enable = false;
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 🧁 Spicetify
  # ─────────────────────────────────────────────────────────────────────────
  programs.spicetify = let
    spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
  in {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
    enabledCustomApps = with spicePkgs.apps; [
      newReleases
      ncsVisualizer
      marketplace
    ];
    enabledSnippets = with spicePkgs.snippets; [ pointer ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 🌬️ Environment Variables
  # ─────────────────────────────────────────────────────────────────────────
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    KWIN_TRIPLE_BUFFER = "1";
    KWIN_COMPOSE = "O2";
    KDE_NO_PRELOADING = "0";
    BALOO_DISABLE = "1";
    QT_QUICK_BACKEND = "opengl";
    KWIN_BACKEND = "vulkan";
    KWIN_LOW_LATENCY = "1";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 📦 System Packages
  # ─────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    lutris
    bottles
    kdePackages.plasma-workspace
    kdePackages.kde-gtk-config
    kdePackages.kwin
    kdePackages.systemsettings
    ryujinx
    torzu
    git
    zip
    rar
    firefox-wayland
    cool-retro-term
    unzip
    toybox
    librewolf
    cudaPackages.cudnn
    cudaPackages.cudatoolkit
    python313Packages.torchvision
    libGL
    vesktop
    gearlever
    easyeffects
    fragments
    fastfetch
    appimage-run
    winetricks
    wineWowPackages.waylandFull
    protontricks
    kdePackages.filelight
    calibre
    plymouth
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      font = "Noto Sans";
      fontSize = "9";
      background = "${./wallpaper.png}";
      loginBackground = true;
    })
  ];

  # ─────────────────────────────────────────────────────────────────────────
  # 🧊 Fonts & UI Polish
  # ─────────────────────────────────────────────────────────────────────────
  fonts = {
    fontconfig.cache32Bit = true;
    packages = with pkgs; [ font-awesome ];
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    xwaylandvideobridge
    korganizer
    khelpcenter
    akonadi
  ];

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Portal to other realms
  # ─────────────────────────────────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ─────────────────────────────────────────────────────────────────────────
  # Unfree packages allowed
  # ─────────────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
}
