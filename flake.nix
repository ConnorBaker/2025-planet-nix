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
          inherit (lib.strings) optionalString;
          inherit (pkgs.stdenv.hostPlatform) isDarwin;

          typixLib = inputs.typix.lib.${system};

          # Yay for differences in how macOS and Linux handle cache directories :l
          cacheDirPrefix = optionalString isDarwin "Library/Caches/";
          cacheDirEnvName = optionalString (!isDarwin) "XDG_CACHE_" + "HOME";

          buildTypstPackagesCache =
            {
              # A list of directories each containing directories of the form `<namespace>/<package>/<version>`
              packageSources,
              # The Typst project to build
              projectSource,
            }:
            pkgs.stdenvNoCC.mkDerivation {
              __structuredAttrs = true;
              strictDeps = true;
              preferLocalBuild = true;
              allowSubstitutes = false;

              name = "typst-packages-cache";
              src = null;

              inherit packageSources;
              inherit projectSource;
              inherit cacheDirPrefix;

              nativeBuildInputs = [ pkgs.ripgrep ];

              buildCommandPath = ./build-typst-packages-cache.bash;
            };

          typstPackagesCache =
            let
              preview = pkgs.fetchFromGitHub {
                owner = "typst";
                repo = "packages";
                rev = "d4ac49c134db967fb251d6dccd8fcce472da1cb3";
                hash = "";
              };
            in
            buildTypstPackagesCache {
              packageSources = [
                "${preview}/packages"
                "${pkgs.nulite-typst}/share/typst/packages"
              ];
              projectSource = ./.;
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

          commonArgs = {
            typstSource = "main.typ";
            fontPaths = [ "${pkgs.nacelle}/share/fonts/opentype" ];
            virtualPaths = [ ];
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
            build-drv = typixLib.buildTypstProject (
              commonArgs
              // {
                inherit src;
                ${cacheDirEnvName} = typstPackagesCache;
              }
            );

            # Compile a Typst project, and then copy the result
            # to the current directory
            build-script = typixLib.buildTypstProjectLocal (
              commonArgs
              // {
                inherit src;
                ${cacheDirEnvName} = typstPackagesCache;
              }
            );

            # Watch a project and recompile on changes
            watch-script = typixLib.watchTypstProject commonArgs;
          };

          # apps = {
          #   default = config.apps.watch;
          #   build.program = build-script;
          #   watch.program = watch-script;
          # };

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
