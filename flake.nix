{
  inputs.nixpkgs.url = github:nixos/nixpkgs/nixos-22.11;
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (hostSystem:
    let
      pkgsFor = sys: inputs.nixpkgs.legacyPackages.${sys};
      hostPkgs = pkgsFor hostSystem;
      targetSystem = "riscv64-linux";
      targetPkgs = pkgsFor targetSystem;
      inherit (inputs.nixpkgs) lib;
    in
    {
      nixosConfigurations.MangoPi = lib.nixosSystem {
        system = targetSystem;
        modules = [
          ./mangoPi.nix
        ];
      };

      devShells.default = hostPkgs.mkShell { };

      packages = rec {
        inherit (inputs.self.nixosConfigurations.${hostSystem}.MangoPi.config.system.build) sdImage toplevel;
        default = sdImage;
      };
    }
  );
}
