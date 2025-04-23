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
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Flake magic & nix settings
  # ─────────────────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  services.flatpak.enable = true;

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "-d";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Bootloader & Kernel Setup
  # ─────────────────────────────────────────────────────────────────────────
  boot = {
    kernelPackages = pkgs.linuxPackages_cachyos;
    kernelParams = [ "quiet" "splash" "systemd.show_status=false" "boot.shell_on_fail" "udev.log_priority=3" "rd.systemd.show_status=auto" "nvidia_drm.modeset=1" ];
    initrd.kernelModules = [
    "nvidia"
    "nvidia_drm"
];

    #initrd.systemd.enable = true;
    consoleLogLevel = 3;
    initrd.verbose = false;
    plymouth = {
      enable = true;
      theme = "lone";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "lone" ];
        })
      ];
    };

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5; #Keep the 5 last Generations
      efi.canTouchEfiVariables = true;

    };
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ⛷️ CPU & GPU Support
  # ─────────────────────────────────────────────────────────────────────────
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.cpu.amd.updateMicrocode = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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
    scx.scheduler = "scx_flash"; # default is "scx_rustland"
    printing.enable = false;
    blueman.enable = false;

    pipewire = {
      enable = true;
      wireplumber.enable = true;
      # Disable suspend of Toslink output to prevent audio popping.
      wireplumber.extraConfig."99-disable-suspend" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          {
            "node.name" = "alsa_output.usb-Burr-Brown_from_TI_USB_Audio_CODEC-00.analog-stereo-output";
          }
        ];
        actions = {
          update-props = {
            "session.suspend-timeout-seconds" = 0;
          };
        };
      }
    ];
  };
      pulse.enable = true;
      };

  };

  systemd.user.services."app-org.kde.kalendarac@autostart".enable = false;

  security.rtkit.enable = true;

  # ─────────────────────────────────────────────────────────────────────────
  # 🧊 User Setup: isolde
  # ─────────────────────────────────────────────────────────────────────────
  users.users.isolde = {
    isNormalUser = true;
    description = "isolde";
    extraGroups = [ "networkmanager" "wheel" "audio" "gamemode"];
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
          #pkgs.libxcrypt-legacy
          #pkgs.python312
          #pkgs.python312Packages.torch
          #pkgs.cudaPackages.cudnn
          #pkgs.cudaPackages.cudatoolkit
          #pkgs.libGL
          #pkgs.python312Packages.torchvision
        ];
      };
    };

    hyprland.enable = true;
    firefox.enable = true;
    partition-manager.enable = true;
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
    KWIN_TRIPLE_BUFFER = "1";
    KWIN_COMPOSE = "O2";
    BALOO_DISABLE = "1";
    QT_QUICK_BACKEND = "opengl";
    KWIN_BACKEND = "vulkan";
    KWIN_LOW_LATENCY = "1";
    #NIXOS_OZONE_WL = "1";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 📦 System Packages
  # ─────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
   #kdePackages.plasma-workspace
    #kdePackages.kde-gtk-config
    #kdePackages.kwin
    #kdePackages.systemsettings
    #kdePackages.filelight
    git
    zip
    rar
    unzip
    toybox
    vesktop
    kitty
    gearlever
    easyeffects
    fragments
    fastfetch
    appimage-run
    p3x-onenote

    #Coding Stuff
    cudaPackages.cudnn
    cudaPackages.cudatoolkit
    python313Packages.torchvision
    python313
    vscode-fhs
    unityhub
    dotnetCorePackages.dotnet_9.sdk


    #gaming stuff
    winetricks
    ryujinx
    virt-manager
    libGL
    pciutils
    bottles
    lutris
    protontricks
    wineWowPackages.staging
    calibre
    plymouth
    inputs.Neve.packages.${pkgs.system}.default
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
    discover
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
