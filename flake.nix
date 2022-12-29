{
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
  inputs.nixpkgs-musl.url = github:ners/nixpkgs/riscv-musl;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (buildPlatform:
    let
      pkgsFor = nixpkgs: system: import nixpkgs { inherit system; };
      buildPkgs = pkgsFor inputs.nixpkgs buildPlatform;
      hostPlatform = "riscv64-linux";
    in
    {
      nixosConfigurations = {
        MangoPi =
          let nixpkgs = inputs.nixpkgs; in
          nixpkgs.lib.nixosSystem {
            modules = [
              {
                nixpkgs = { inherit buildPlatform hostPlatform; };
              }
              ./mangoPi.nix
            ];
          };
        MangoPiMusl =
          let nixpkgs = inputs.nixpkgs-musl; in
          nixpkgs.lib.nixosSystem {
            modules = [
              {
                nixpkgs = {
                  inherit buildPlatform hostPlatform;
                  pkgs = (pkgsFor nixpkgs hostPlatform).pkgsMusl;
                };
              }
              ./mangoPi.nix
            ];
          };
      };

      devShells.default = buildPkgs.mkShell { };

      packages =
        let
          nixpkgs = inputs.nixpkgs;
          pkgs = pkgsFor nixpkgs buildPlatform;
        in
        rec {
          inherit (inputs.self.nixosConfigurations.${buildPlatform}.MangoPi.config.system.build) sdImage toplevel;
          default = sdImage;
          sdImageMusl = inputs.self.nixosConfigurations.${buildPlatform}.MangoPiMusl.config.system.build.sdImage;
        };
    }
  );
}
