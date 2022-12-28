{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-riscv64-qemu.nix"
  ];

  sdImage.imageBaseName = "MangoPi";
  system.stateVersion = lib.trivial.version;

  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce [ ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBlAx5Hi5TsLsy5e+4OdBmM4oHtdUnqX5gtNbfc60rq ners <ners@gmx.ch>"
  ];
}
