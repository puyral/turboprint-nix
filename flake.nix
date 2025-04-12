{
  description = "Turboprint";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        replace_vars = { };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./fmt.nix;
        pkgs = nixpkgs.legacyPackages.${system};
        turboprintPkgs = pkgs.callPackages ./turboprint.nix { };
        module = pkgs.callPackage ./module.nix turboprintPkgs;

      in
      {
        formatter = treefmtEval.config.build.wrapper;
        packages = rec {
          turboprint = turboprintPkgs.withEnv;
          tprintdaemon = turboprintPkgs.daemon;

          default = turboprint;
        };
        nixosModules = module;
      }
    );
}
