{
  description = "Implementation of Dhall in Dhall";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = [
      "https://cache.dhall-lang.org"
      "https://cache.garnix.io"
      "https://dhall.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.dhall-lang.org:I9/H18WHd60olG5GsIjolp7CtepSgJmM2CsO813VTmM="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "dhall.cachix.org-1:8laGciue2JBwD49ICFtg+cIF8ddDaW7OFBjDb/dHEAo="
    ];
    ## Isolate the build.
    registries = false;
    ## FIXME: Set to `true` once we don’t need `_noChroot` in checks.
    sandbox = false;
  };

  outputs = inputs: let
    pname = "dhall-dhall";
  in
    {
      schemas = {
        inherit
          (inputs.flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      overlays = {
        default = final: prev: {
          dhallPackages = prev.dhallPackages.override (old: {
            overrides =
              final.lib.composeExtensions
              (old.overrides or (_: _: {}))
              (inputs.self.overlays.dhall final prev);
          });
        };

        dhall = final: prev: dfinal: dprev: {
          ${pname} = inputs.self.packages.${final.system}.${pname};
        };
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (inputs.flaky.lib.homeConfigurations.example
            pname
            inputs.self
            [
              ({pkgs, ...}: {
                ## TODO: Is there something more like `dhallWithPackages`?
                home.packages = [pkgs.dhallPackages.${pname}];
              })
            ])
          inputs.flake-utils.lib.defaultSystems);
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.caterwaul.overlays.default
          inputs.dada.overlays.default
          inputs.dhall-bhat.overlays.default
        ];
      };

      src = pkgs.lib.cleanSource ./.;
    in {
      packages = {
        default = inputs.self.packages.${system}.${pname};

        "${pname}" = pkgs.dhallPackages.buildDhallDirectoryPackage {
          src = "${src}/dhall";
          name = pname;
          dependencies = [
            pkgs.dhallPackages.Prelude
            pkgs.dhallPackages.caterwaul
            pkgs.dhallPackages.dada
            pkgs.dhallPackages.dhall-bhat
          ];
          document = true;
        };
      };

      projectConfigurations = inputs.flaky.lib.projectConfigurations.default {
        inherit pkgs;
        inherit (inputs) self;
      };

      devShells =
        {
          default =
            inputs.flaky.lib.devShells.default
            system
            inputs.self
            []
            "";
        }
        // inputs.self.projectConfigurations.${system}.devShells;

      checks = inputs.self.projectConfigurations.${system}.checks;

      formatter = inputs.self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    caterwaul = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/caterwaul";
    };

    dada = {
      inputs = {
        dhall-bhat.follows = "dhall-bhat";
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/dada";
    };

    dhall-bhat = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/dhall-bhat";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
  };
}
