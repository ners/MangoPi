{
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
  inputs.nixpkgs-musl.url = github:ners/nixpkgs/riscv-musl;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = inputs: inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "riscv64-linux" ] (buildPlatform:
    let
      overlays = [
      ];
      pkgsFor = nixpkgs: system: import nixpkgs { inherit system overlays; };
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
                nixpkgs = {
                  inherit buildPlatform hostPlatform overlays;
                };
              }
              ./MangoPi
            ];
          };
        MangoPiMusl =
          let nixpkgs = inputs.nixpkgs-musl; in
          #let nixpkgs = inputs.nixpkgs; in
          nixpkgs.lib.nixosSystem {
            modules = [
              {
                nixpkgs = {
                  inherit buildPlatform hostPlatform overlays;
                  pkgs = (pkgsFor nixpkgs hostPlatform).pkgsMusl;
                };
              }
              ./MangoPi
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
          inherit (pkgs) pkgsCross;
          inherit (inputs.self.nixosConfigurations.${buildPlatform}.MangoPi.config.system.build) sdImage toplevel;
          default = sdImage;
          sdImageMusl = inputs.self.nixosConfigurations.${buildPlatform}.MangoPiMusl.config.system.build.sdImage;
        };
    }
  );
}
