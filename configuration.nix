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
    ./packages.nix
    ./cpugpu.nix
    ./boot.nix
    ./services.nix
    ./spicetify.nix
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
  virtualisation.podman.enable = true;
  virtualisation.libvirtd.enable = true;
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
  # ❄️ Suspend/Sleep
  # ─────────────────────────────────────────────────────────────────────────
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
systemd.user.services."app-org.kde.kalendarac@autostart".enable = false;
systemd.network.wait-online.enable = false;

  #──────────────────────────────────────────────────────────────────────────
  # 🧊 User Setup: isolde
  # ─────────────────────────────────────────────────────────────────────────
  users.users.isolde = {
    isNormalUser = true;
    description = "isolde";
    extraGroups = [ "networkmanager" "wheel" "audio" "gamemode" "video" "kvm" "libvirtd"];
    packages = with pkgs; [ kdePackages.kate ];
  };

security.sudo = {
  enable = true;
  wheelNeedsPassword = false;
};

  # ─────────────────────────────────────────────────────────────────────────
  # Unfree packages allowed
  # ─────────────────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

}
