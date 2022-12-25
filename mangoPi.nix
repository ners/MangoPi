{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  system.stateVersion = lib.trivial.version;

  boot = {
    # Disable Grub, we're using uboot
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;

    #initrd.availableKernelModules = lib.mkForce [ ];

    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    #extraModulePackages = [ ];

    # Exclude zfs
    supportedFilesystems = lib.mkForce [ ];
  };
}
