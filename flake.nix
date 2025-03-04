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
    typst-packages = {
      flake = false;
      url = "github:typst/packages";
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
            typstPackagesSrc: typstProjectSrc:
            pkgs.stdenvNoCC.mkDerivation {
              __structuredAttrs = true;
              strictDeps = true;
              preferLocalBuild = true;
              allowSubstitutes = false;

              name = "typst-packages-cache";
              src = null;

              inherit typstPackagesSrc;
              inherit typstProjectSrc;
              inherit cacheDirPrefix;

              nativeBuildInputs = [ pkgs.ripgrep ];

              buildCommandPath = ./build-typst-packages-cache.bash;

              postInstall = ''
                if [[ -f "$outputPackagesDir/nulite/0.1.0/lib.typ" ]]; then
                  nixLog "patching nulite 0.1.0"
                  # Remove the symlink
                  rm "$outputPackagesDir/nulite/0.1.0"
                  # Copy the file
                  cp -r "$inputPackagesDir/nulite/0.1.0" "$outputPackagesDir/nulite/0.1.0"
                  # Patch the file
                  substituteInPlace "$outputPackagesDir/nulite/0.1.0/lib.typ" \
                    --replace-fail \
                      '#let ctx-name = "@preview/vegalite"' \
                      '#let ctx-name = "@preview/nulite"'
                fi
              '';
            };

          typstPackagesCache = buildTypstPackagesCache inputs.typst-packages "${./imports.typ}";

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

            fontPaths = [
              # Add paths to fonts here
              "${pkgs.nacelle}/share/fonts/opentype"
            ];

            virtualPaths = [
              # Add paths that must be locally accessible to typst here
              # {
              #   dest = "icons";
              #   src = "${inputs.font-awesome}/svgs/regular";
              # }
            ];
          };

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
        in
        {
          checks = {
            inherit build-drv build-script watch-script;
          };

          packages = {
            default = build-drv;
            inherit typstPackagesCache;
            typstPackagesSrc = inputs.typst-packages.outPath;
          };

          apps = {
            default = config.apps.watch;
            build.program = build-script;
            watch.program = watch-script;
          };

          devShells.default = typixLib.devShell {
            inherit (commonArgs) fontPaths virtualPaths;
            packages = attrValues config.treefmt.build.programs ++ [
              # WARNING: Don't run `typst-build` directly, instead use `nix run .#build`
              # See https://github.com/loqusion/typix/issues/2
              # build-script
              watch-script
              # More packages can be added here, like typstfmt
              # pkgs.typstfmt
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
              # JSON, Markdown, YAML
              prettier = {
                enable = true;
                includes = [
                  "*.json"
                  "*.md"
                  "*.yaml"
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
