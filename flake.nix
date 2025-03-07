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

          typixLib = inputs.typix.lib.${system} // {
            # Yay for slimming dependencies!
            buildTypstPackagesCache = pkgs.callPackage ./buildTypstPackagesCache { };
          };

          # Contains `packages` in the outPath
          # Though this is available as a flake, Darwin can't build it because rust fails to link a prerequisite.
          nulite = pkgs.fetchzip {
            name = "nulite-0.1.1";
            url = "https://github.com/ConnorBaker/typst-vegalite/releases/download/v0.1.1/v0.1.1.tar.gz";
            hash = "sha256-x4nm4JG2LmUZQNTNLWqzwWjSnQN0zgG01R+DUewYYJU=";
            stripRoot = false; # Keeps the `packages` directory
          };

          # Contains `packages` in the outPath
          typstPackages = pkgs.fetchFromGitHub {
            name = "typst-packages-d4ac49c";
            owner = "typst";
            repo = "packages";
            rev = "d4ac49c134db967fb251d6dccd8fcce472da1cb3";
            hash = "sha256-xVj8uVLCb5wy76MVTcQKb+A129sBYu4KqgjYV/E2mJE=";
          };

          aggregated-json = pkgs.fetchurl {
            name = "aggregated-nixos-desktop-20-runs-1-job-no-boost.json";
            url = "https://github.com/ConnorBaker/benchmarking-nix-eval/releases/download/v0.0.1/aggregated-nixos-desktop-20-runs-1-job-no-boost.json";
            hash = "sha256-ZOG2vgbbSz+SlfluxXjuA8rcsf6DLGsQZ7HdJgnrhpI=";
          };

          typstPackagesCache = typixLib.buildTypstPackagesCache {
            packagesSources = [
              "${typstPackages.outPath}/packages"
              "${nulite.outPath}/packages"
            ];
            projectSource = ./imports.typ;
          };

          commonArgs = {
            typstSource = "main.typ";
            fontPaths = [ "${pkgs.nacelle}/share/fonts/opentype" ];
            virtualPaths = [ ];
            env = {
              TYPST_PACKAGE_CACHE_PATH = typstPackagesCache.outPath;
              TYPST_PACKAGE_PATH = typstPackagesCache.outPath;
            };
            # Since the outPath of aggregated-json is the JSON file itself, we need to
            # create a symlink to it so we can refer to it as `aggregated.json`.
            preBuild = ''
              nixLog "symlinking ${aggregated-json.outPath} to aggregated.json"
              ln -s "${aggregated-json.outPath}" aggregated.json
            '';
            src = toSource {
              root = ./.;
              fileset = unions [
                ./eval-charts.typ
                ./imports.typ
                ./main.typ
                ./utils.typ
              ];
            };
          };
        in
        {
          packages.default = typixLib.buildTypstProject commonArgs;

          devShells.default = typixLib.devShell {
            inherit (commonArgs) env fontPaths virtualPaths;
            packages = attrValues config.treefmt.build.programs;
            # WARNING: Don't run `typst-build` directly, instead use `nix run .#build`
            # See https://github.com/loqusion/typix/issues/2
            inputsFrom = [ (typixLib.buildTypstProjectLocal commonArgs) ];
            # If aggregated.json doesn't exist or is a symlink and doesn't refer to aggregated-json.outPath,
            # remove it so we can create a new one.
            shellHook = ''
              if [[ ! -e aggregated.json ]]; then
                echo "symlinking ${aggregated-json.outPath} to aggregated.json"
                ln -s "${aggregated-json.outPath}" aggregated.json
              elif [[ -L aggregated.json && $(readlink aggregated.json) != "${aggregated-json.outPath}" ]]; then
                echo "refreshing symlink from ${aggregated-json.outPath} to aggregated.json"
                rm aggregated.json
                ln -s "${aggregated-json.outPath}" aggregated.json
              fi
            '';
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
