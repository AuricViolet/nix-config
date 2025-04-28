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

nix.gc = {
    automatic = true;
    dates = "daily";
    options = "-d";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Bootloader & Kernel Setup
  # ─────────────────────────────────────────────────────────────────────────
  boot = {
   kernelModules= ["nvidia" "nvidia-uvm"];
   kernelPackages = pkgs.linuxPackages_cachyos;
    kernelParams = [ "quiet" "splash" "systemd.show_status=false" "boot.shell_on_fail" "udev.log_priority=3" "rd.systemd.show_status=auto" "nvidia_drm.modeset=1" ];
    initrd.kernelModules = [
    "nvidia"
];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5; #Keep the 5 last Generations
      efi.canTouchEfiVariables = true;

    };
  };
systemd.network.wait-online.enable = false;

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
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    #nvidiaPersistenced = true;
    forceFullCompositionPipeline = true;
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
    extraGroups = [ "networkmanager" "wheel" "audio" "gamemode" "video"];
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
    virt-manager.enable = true;

    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [
          pkgs.icu
          pkgs.libxcrypt-legacy
        ];
      };
    };
    firefox.enable = true;
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
    KWIN_LOW_LATENCY = "1";
    XDG_CACHE_HOME = "/home/isolde/.cache";
    #NIXOS_OZONE_WL = "1";
  };

  # ─────────────────────────────────────────────────────────────────────────
  # 📦 System Packages
  # ─────────────────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    gparted
    git
    zip
    rar
    unzip
    toybox
    vesktop
    gearlever
    easyeffects
    fragments
    fastfetch
    appimage-run
    p3x-onenote
    moonlight-qt
    ananicy-rules-cachyos
    smartmontools

    #Coding Stuff
    obsidian
    vscode-fhs
    unityhub
    dotnetCorePackages.dotnet_9.sdk
    godot_4_3

    #gaming stuff

    ryujinx
    bottles
    lutris
    heroic
    protontricks
    wine
    calibre
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
  ];

  # ─────────────────────────────────────────────────────────────────────────
  # ❄️ Portal to other realms
  # ─────────────────────────────────────────────────────────────────────────

security.sudo = {
  enable = true;
  wheelNeedsPassword = false;
};
  # ─────────────────────────────────────────────────────────────────────────
  # Unfree packages allowed
  # ─────────────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;
}
