{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    #nixpkgs-musl.url = github:ners/nixpkgs/riscv-musl;
  };

  outputs = inputs:
    let
      inherit (inputs.nixpkgs) lib;
      foreach = xs: f: with lib; foldr recursiveUpdate { } (
        if isList xs then map f xs
        else if isAttrs xs then mapAttrsToList f xs
        else throw "foreach: expected list or attrset but got ${typeOf xs}"
      );
      pkgsFor = system: import inputs.nixpkgs { inherit system; overlays = []; };
      mkMangoPi = { buildPlatform, hostPlatform }:
          lib.nixosSystem {
            modules = [
              {
                nixpkgs = {
                  inherit buildPlatform hostPlatform;
                };
              }
              ./MangoPi
            ];
          };
      mkMangoPiMusl = { buildPlatform, hostPlatform }:
          lib.nixosSystem {
            modules = [
              {
                nixpkgs = {
                  inherit buildPlatform hostPlatform;
                  pkgs = (pkgsFor hostPlatform).pkgsMusl;
                };
              }
              ./MangoPi
            ];
          };
    in
    foreach inputs.nixpkgs.legacyPackages (buildPlatform: pkgs:
    let
      hostPlatform = "riscv64-linux";
      mangoPi = mkMangoPi { inherit buildPlatform hostPlatform; };
      mangoPiMusl = mkMangoPi { inherit buildPlatform hostPlatform; };
    in
    {
      formatters.${buildPlatform}.default = pkgs.nixpkgs-fmt;

      devShells.${buildPlatform}.default = pkgs.mkShell { };

      packages.${buildPlatform} = rec {
          inherit (pkgs) pkgsCross;
          inherit (mangoPi.config.system.build) sdImage toplevel;

          default = sdImage;

          sdImageMusl = mangoPiMusl.config.system.build.sdImage;

          flash = pkgs.writeShellApplication {
            name = "flash";
            runtimeInputs = with pkgs; [ zstd.bin coreutils pv ];
            text = ''
              IMAGE_FILE=''${IMAGE_FILE:-"$(nix build --no-link --print-out-paths .#sdImage 2>/dev/null | xargs -I{} find {}/sd-image/ -name '*.zst')"}

              IMAGE_SIZE="$(zstd -lv "$IMAGE_FILE" |& grep Decompressed | grep -o -e '\([0-9]\+\) B' | awk '{ print $1 }')"

              echo "Found image $IMAGE_FILE with size $IMAGE_SIZE"

              if [[ ''${DEVICE-x} == x ]]; then
                echo 'Please specify DEVICE!' >&2
                exit 1
              fi

              zstdcat -q "$IMAGE_FILE" | pv -s "$IMAGE_SIZE" | sudo dd bs=1M iflag=fullblock oflag=direct of="$DEVICE"
            '';
          };
        };
    });
}
