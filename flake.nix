{
  description = "A Typst project";

  inputs = {
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    git-hooks-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/git-hooks.nix";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nulite = {
      url = "github:ConnorBaker/typst-vegalite/feat/update";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks-nix.follows = "git-hooks-nix";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];
      perSystem =
        {
          config,
          lib,
          pkgs,
          system,
          ...
        }:
        let
          inherit (lib.attrsets) attrValues;
          inherit (lib.fileset) toSource unions;

          typixLib = inputs.typix.lib.${system};

          buildTypstPackagesCache =
            {
              # A list of directories each containing directories of the form `<namespace>/<package>/<version>`
              packagesSources,
              # The Typst project to build
              projectSource,
            }:
            # Produces an output containing containing directories of the form `<namespace>/<package>/<version>`.
            # As such, the outPath can be provided to TYPST_PACKAGE_CACHE_PATH and TYPST_PACKAGE_PATH.
            pkgs.stdenvNoCC.mkDerivation {
              __structuredAttrs = true;
              strictDeps = true;
              preferLocalBuild = true;
              allowSubstitutes = false;

              name = "typst-packages-cache";
              src = null;

              inherit packagesSources;
              inherit projectSource;

              nativeBuildInputs = [ pkgs.ripgrep ];

              buildCommandPath = ./build-typst-packages-cache.bash;
            };

          typstPackagesCache =
            let
              preview = pkgs.fetchFromGitHub {
                owner = "typst";
                repo = "packages";
                rev = "d4ac49c134db967fb251d6dccd8fcce472da1cb3";
                hash = "sha256-xVj8uVLCb5wy76MVTcQKb+A129sBYu4KqgjYV/E2mJE=";
              };
            in
            buildTypstPackagesCache {
              packagesSources = [
                "${preview}/packages"
                "${pkgs.nulite-typst}/share/typst/packages"
              ];
              projectSource = ./.;
            };

          commonArgs = {
            typstSource = "main.typ";
            fontPaths = [ "${pkgs.nacelle}/share/fonts/opentype" ];
            virtualPaths = [ ];
            env = {
              TYPST_PACKAGE_CACHE_PATH = typstPackagesCache.outPath;
              TYPST_PACKAGE_PATH = typstPackagesCache.outPath;
            };
            src = toSource {
              root = ./.;
              fileset = unions [
                ./aggregated.json
                ./imports.typ
                ./main.typ
                ./vega-lite-specs
              ];
            };
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.nulite.overlays.default ];
          };

          packages = {
            default = config.packages.build-drv;

            # Compile a Typst project, *without* copying the result
            # to the current directory
            build-drv = typixLib.buildTypstProject commonArgs;

            # Compile a Typst project, and then copy the result
            # to the current directory
            build-script = typixLib.buildTypstProjectLocal commonArgs;

            # Watch a project and recompile on changes
            watch-script = typixLib.watchTypstProject (
              builtins.removeAttrs commonArgs [
                "env"
                "src"
              ]
            );
          };

          apps = {
            default = config.apps.watch;
            build.program = config.packages.build-script;
            watch.program = config.packages.watch-script;
          };

          devShells.default = typixLib.devShell {
            inherit (commonArgs) fontPaths virtualPaths;
            packages = attrValues config.treefmt.build.programs ++ [
              # WARNING: Don't run `typst-build` directly, instead use `nix run .#build`
              # See https://github.com/loqusion/typix/issues/2
              # build-script
              config.packages.watch-script
            ];
          };

          pre-commit.settings.hooks = {
            # Formatter checks
            treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };

            # Nix checks
            deadnix.enable = true;
            nil.enable = true;
            statix.enable = true;
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              # JSON, Markdown
              prettier = {
                enable = true;
                includes = [
                  "*.json"
                  "*.md"
                ];
                settings = {
                  embeddedLanguageFormatting = "auto";
                  printWidth = 120;
                  tabWidth = 2;
                };
              };

              # Nix
              nixfmt.enable = true;

              # Shell
              shellcheck.enable = true;
              shfmt.enable = true;

              # Typst
              typstyle.enable = true;
            };
          };
        };
    };
}
