{
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixos-22.11;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = inputs:
    let
      targetSystem = "riscv64-linux";
      pkgsFor = sys: inputs.nixpkgs.legacyPackages.${sys};
      targetPkgs = pkgsFor targetSystem;
    in
    {
      nixosConfigurations.mangoPi = inputs.nixpkgs.lib.nixosSystem {
        system = targetSystem;
        modules = [ ./mangoPi.nix ];
      };
    } // inputs.flake-utils.lib.eachDefaultSystem (hostSystem:
      let
        pkgs = pkgsFor hostSystem;
      in
      {
        devShells.default = pkgs.mkShell { };

        packages.toplevel = inputs.self.nixosConfigurations.mangoPi.config.system.build.toplevel;
        packages.sdImage = inputs.self.nixosConfigurations.mangoPi.config.system.build.sdImage;
      }
    );
}
