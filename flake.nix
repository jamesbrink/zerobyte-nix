{
  description = "Zerobyte - Self-hosted backup automation and management (Nix flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zerobyte-src = {
      url = "github:nicotsx/zerobyte";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      bun2nix,
      zerobyte-src,
      treefmt-nix,
    }:
    let
      # Systems for packages and devShells (cross-platform)
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Linux-only systems for NixOS module and VM tests
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Shared configuration
      config = {
        inherit zerobyte-src;
        patches = [ ./patches/0001-add-port-and-migrations-path-config.patch ];
        bunNix = ./bun.nix;
      };

    in
    flake-utils.lib.eachSystem allSystems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ bun2nix.overlays.default ];
        };

        # Import package definitions
        packages = import ./nix/packages {
          inherit pkgs system config;
          inherit (pkgs) lib;
          bun2nixPkgs = bun2nix.packages.${system};
        };

        # Configure treefmt for nix formatting
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
        };

      in
      {
        packages = {
          inherit (packages) zerobyte shoutrrr;
          default = packages.zerobyte;
        };

        devShells.default = import ./nix/dev-shell.nix {
          inherit pkgs system;
          inherit (packages) shoutrrr;
          bun2nixPkgs = bun2nix.packages.${system};
        };

        # Nix formatter (via treefmt)
        formatter = treefmtEval.config.build.wrapper;

        # Formatting check
        checks.formatting = treefmtEval.config.build.check self;
      }
    )
    // {
      # Overlay for use in other flakes
      overlays.default = final: prev: {
        zerobyte = self.packages.${final.system}.zerobyte;
        shoutrrr = self.packages.${final.system}.shoutrrr;
      };

      # NixOS module
      nixosModules.default = import ./nix/modules/nixos.nix { inherit self; };

      # nix-darwin module (macOS)
      darwinModules.default = import ./nix/modules/darwin.nix { inherit self; };

      # NixOS integration tests (Linux only)
      checks = builtins.listToAttrs (
        map (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ bun2nix.overlays.default ];
            };
          in
          {
            name = system;
            value = {
              integration = import ./nix/tests/integration.nix {
                inherit pkgs self;
              };
            };
          }
        ) linuxSystems
      );
    };
}
