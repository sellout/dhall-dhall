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
          (inputs.project-manager.schemas)
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

      devShells.default =
        inputs.flaky.lib.devShells.default
        pkgs
        inputs.self
        [
          pkgs.dhall
          pkgs.dhall-docs
          pkgs.dhall-lsp-server
        ]
        "";

      projectConfigurations = inputs.flaky.lib.projectConfigurations.default {
        inherit pkgs;
        inherit (inputs) self;
      };

      checks = inputs.self.projectConfigurations.${system}.checks;

      formatter = inputs.self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs = {
        project-manager.follows = "project-manager";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    caterwaul = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/caterwaul";
    };

    dada = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        dhall-bhat.follows = "dhall-bhat";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/dada";
    };

    dhall-bhat = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/dhall-bhat";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        project-manager.follows = "project-manager";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";

    project-manager = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/project-manager";
    };
  };
}
